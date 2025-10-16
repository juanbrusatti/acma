import json
import os
from collections import Counter
from rectpack import GuillotineBssfSas, GuillotineBafSas, GuillotineBssfSlas
from rectpack import newPacker, PackingMode, PackingBin
from rectpack import SORT_AREA, SORT_PERI, SORT_DIFF, SORT_SSIDE, SORT_LSIDE, SORT_RATIO, SORT_NONE
from visualize import visualize_packing
from output import save_cutting_plan_to_csv, print_summary
import argparse
import sys
import random
import shutil

# funcion para parsear args
def parse_args():
    """
    Parsea los argumentos pasados al script.
    Si no se proporciona un archivo JSON, se utilizará inputs.json por defecto.
    """

    parser = argparse.ArgumentParser(description='Run cut optimizer')
    parser.add_argument('--inp', type=str, default='inputs.json',
                        help='JSON string with input data or path to a JSON file. If omitted, reads inputs.json')
    parser.add_argument('--stdin', action='store_true',
                        help='Read a single JSON object from stdin with keys "pieces_to_cut" and "stock"')
    return parser.parse_args()


# --- funcion aux ---
def get_unfitted_rects(packer):
    """
    Obtiene la lista de rectángulos no empaquetados de forma compatible
    con diferentes versiones de la librería rectpack. Porque con algunas anda bien
    y con otras tira error
    """
    try:
        # Intenta usar el método más reciente
        return packer.rect_list_unfitted()
    except AttributeError:
        # Si falla, usa el método alternativo/antiguo
        try:
            return packer.rect_list_unsorted()
        except AttributeError:
            # Si ninguno funciona, retorna una lista vacía
            print("Empty list: No unfitted rectangles found.")
            return []

def merge_adjacent_rects(rects):
    """
    Fusiona rectángulos adyacentes de manera conservadora, respetando el corte guillotina.
    Solo fusiona rectángulos que comparten exactamente un borde completo.
    """
    if not rects or len(rects) <= 1:
        return rects
    
    # Ordenar por posición para procesamiento más eficiente
    rects = sorted(rects, key=lambda r: (r[0], r[1]))  # ordenar por x, luego y
    
    merged = True
    iteration = 0
    max_iterations = 10  # Evitar ciclos infinitos
    
    while merged and iteration < max_iterations:
        merged = False
        iteration += 1
        new_rects = []
        used = set()
        
        for i, (bx, by, bw, bh) in enumerate(rects):
            if i in used:
                continue
            
            merged_this = False
            
            for j, (bx2, by2, bw2, bh2) in enumerate(rects):
                if i >= j or j in used:
                    continue
                
                # FUSIÓN VERTICAL: rectángulos uno encima del otro
                # Deben tener el mismo X, mismo ancho, y ser adyacentes en Y
                if bx == bx2 and bw == bw2:
                    # Verificar que son exactamente adyacentes (sin gap ni overlap)
                    if by + bh == by2:
                        # Rect i está arriba de rect j
                        new_rects.append((bx, by, bw, bh + bh2))
                        used.update([i, j])
                        merged = merged_this = True
                        break
                    elif by2 + bh2 == by:
                        # Rect j está arriba de rect i
                        new_rects.append((bx, by2, bw, bh + bh2))
                        used.update([i, j])
                        merged = merged_this = True
                        break
                
                # FUSIÓN HORIZONTAL: rectángulos lado a lado
                # Deben tener el mismo Y, misma altura, y ser adyacentes en X
                elif by == by2 and bh == bh2:
                    # Verificar que son exactamente adyacentes (sin gap ni overlap)
                    if bx + bw == bx2:
                        # Rect i está a la izquierda de rect j
                        new_rects.append((bx, by, bw + bw2, bh))
                        used.update([i, j])
                        merged = merged_this = True
                        break
                    elif bx2 + bw2 == bx:
                        # Rect j está a la izquierda de rect i
                        new_rects.append((bx2, by, bw + bw2, bh))
                        used.update([i, j])
                        merged = merged_this = True
                        break
            
            if not merged_this:
                new_rects.append((bx, by, bw, bh))
        
        rects = new_rects
    
    return rects
        
# Es metodo que permite asignarle un valor a nuestro empaquetado o plan de corte
def _evaluate_packer(packer, bins_map):
    rects = packer.rect_list()
    placed_count = len(rects)
    placed_area = sum((r[3] * r[4]) for r in rects)  # w*h
    bins_used = set()
    # Se recorre la lista de rects para obtener los ids de las planchas usadas
    for r in rects:
        b_idx = r[0]
        # bid lo definimos como string al crear los bins
        try:
            bid = str(packer[b_idx].bid)
        except Exception:
            # Fallback: si la API difiere, intentar extraer de r
            bid = str(r[0])
        bins_used.add(bid)

    # bin_area_used: suma de área de las planchas usadas según bins_map (si no está, lo ignoramos)
    bin_area_used = 0
    for b in bins_used:
        binfo = bins_map.get(b)
        if binfo:
            bin_area_used += binfo['width'] * binfo['height']

    return placed_count, placed_area, bin_area_used, bins_used

# Este metodo recibe las piezas a cortar y el stock (sobrantes y planchas nuevas).
# bins_to_add es basicamente los sobrantes que se estan usando y en bins_map tenemos los mismos sobrantes pero sirve para calcular las metricas
def _try_guillotine_variants(rects_to_add, bins_to_add, bins_map, rotation=True):
    import random
    from rectpack import newPacker, PackingMode, PackingBin
    from rectpack.guillotine import GuillotineBssfSlas
    from rectpack.packer import SORT_AREA, SORT_PERI, SORT_DIFF, SORT_SSIDE, SORT_LSIDE, SORT_RATIO, SORT_NONE

    guillotine_algos = [GuillotineBssfSlas]
    sort_algos_builtin = [SORT_AREA, SORT_PERI, SORT_DIFF, SORT_SSIDE, SORT_LSIDE, SORT_RATIO, SORT_NONE]
    custom_sorts = ["BY_WIDTH", "BY_HEIGHT", "BY_AREA_DESC", "SHUFFLE"]
    bin_algos = [PackingBin.BFF, PackingBin.BBF]

    best_score = None
    best_data = None

    # 🔹 lista para guardar los rectángulos sobrantes de cada intento
    all_free_rects = []
    all_unused_rects = []

    def get_free_rects_from_packer(packer):
        free_rects = []
        unused_rects = []

        for b_idx, b in enumerate(packer):
            bin_w, bin_h = b.width, b.height
            bid = b.bid

            # Lista de piezas colocadas (en esta plancha)
            placed = [r for r in packer.rect_list() if r[0] == b_idx]
            if not placed:
                free_rects.append((bid, 0, 0, bin_w, bin_h))
                continue

            # Espacios libres iniciales: toda la plancha
            spaces = [(0, 0, bin_w, bin_h)]

            for _, x, y, w, h, _ in placed:
                new_spaces = []
                for sx, sy, sw, sh in spaces:
                    # Si no hay intersección, se conserva
                    if x + w <= sx or x >= sx + sw or y + h <= sy or y >= sy + sh:
                        new_spaces.append((sx, sy, sw, sh))
                        continue

                    # Corte guillotina — subdividimos el espacio
                    # Arriba del rectángulo
                    if y > sy:
                        new_spaces.append((sx, sy, sw, y - sy))
                    # Abajo del rectángulo
                    if y + h < sy + sh:
                        new_spaces.append((sx, y + h, sw, (sy + sh) - (y + h)))
                    # Izquierda del rectángulo
                    if x > sx:
                        new_spaces.append((sx, y, x - sx, h))
                    # Derecha del rectángulo
                    if x + w < sx + sw:
                        new_spaces.append((x + w, y, (sx + sw) - (x + w), h))

                spaces = new_spaces

            spaces = merge_adjacent_rects(spaces)
            # Filtrar sobrantes mínimos y guardar
            for sx, sy, sw, sh in spaces:
                if sw < 200 or sh < 200:
                    unused_rects.append((bid, sx, sy, sw, sh))
                else: 
                    free_rects.append((bid, sx, sy, sw, sh))

        return free_rects, unused_rects

    # 🔸 Función para evaluar una heurística y guardar sus free_rects
    def evaluate_variant(packer, algo, sort_used, bin_algo):
        nonlocal best_score, best_data, all_free_rects, all_unused_rects
        placed_count, placed_area, bin_area_used, bins_used = _evaluate_packer(packer, bins_map)
        waste = (bin_area_used - placed_area) if bin_area_used > 0 else float('inf')
        metrics = (placed_count, -waste, -len(bins_used))
        free_rects, unused_rects = get_free_rects_from_packer(packer)
        all_unused_rects.extend(unused_rects)
        all_free_rects.extend(free_rects)  # guardamos todos los sobrantes

        if best_score is None or metrics > best_score:
            best_score = metrics
            best_data = {
                'best_packer': packer,
                'best_result': packer.rect_list(),
                'metrics': (placed_count, placed_area, bin_area_used, bins_used, waste),
                'heuristic': (algo, sort_used, bin_algo),
                'free_rects': free_rects,  # 🔸 agregamos aquí los sobrantes de la mejor heurística
                'unused_rects': unused_rects
            }

    # ---------------------
    # Heurísticas de rectpack
    # ---------------------
    for algo in guillotine_algos:
        for bin_algo in bin_algos:
            for sort in sort_algos_builtin:
                packer = newPacker(
                    mode=PackingMode.Offline,
                    rotation=rotation,
                    pack_algo=algo,
                    sort_algo=sort,
                    bin_algo=bin_algo
                )
                for (w, h, rid) in rects_to_add:
                    packer.add_rect(width=w, height=h, rid=rid)
                for (bw, bh, bid) in bins_to_add:
                    packer.add_bin(width=bw, height=bh, bid=bid)
                try:
                    packer.pack()
                    evaluate_variant(packer, algo, sort, bin_algo)
                except Exception:
                    continue

            # ---------------------
            # Heurísticas personalizadas
            # ---------------------
            for sort_tag in custom_sorts:
                packer = newPacker(
                    mode=PackingMode.Offline,
                    rotation=rotation,
                    pack_algo=algo,
                    sort_algo=SORT_NONE,
                    bin_algo=bin_algo
                )

                if sort_tag == "BY_WIDTH":
                    rects_iter = sorted(rects_to_add, key=lambda r: r[0], reverse=True)
                elif sort_tag == "BY_HEIGHT":
                    rects_iter = sorted(rects_to_add, key=lambda r: r[1], reverse=True)
                elif sort_tag == "BY_AREA_DESC":
                    rects_iter = sorted(rects_to_add, key=lambda r: r[0]*r[1], reverse=True)
                elif sort_tag == "SHUFFLE":
                    rects_iter = list(rects_to_add)
                    random.shuffle(rects_iter)
                else:
                    rects_iter = list(rects_to_add)

                for (w, h, rid) in rects_iter:
                    packer.add_rect(width=w, height=h, rid=rid)
                for (bw, bh, bid) in bins_to_add:
                    packer.add_bin(width=bw, height=bh, bid=bid)

                try:
                    packer.pack()
                    evaluate_variant(packer, algo, sort_tag, bin_algo)
                except Exception:
                    continue

    # 🔹 devolvemos los free_rects acumulados y los de la mejor heurística
    if best_data is not None:
        best_data['all_free_rects'] = all_free_rects
        best_data['all_unused_rects'] = all_unused_rects
        #best_data['free_rects'] = get_free_rects_from_packer(best_data['best_packer'])
        return best_data
    else:
        # Si no se encontró ninguna solución, devolver estructura vacía
        return {
            'best_result': None,
            'best_packer': None,
            'metrics': (0, 0, 0, set(), float('inf')),
            'heuristic': (None, None, None),
            'free_rects': [],
            'unused_rects': [],
            'all_free_rects': all_free_rects,
            'all_unused_rects': all_unused_rects
        }

def run_optimizer(input_data, stock_data):
    
    # Guardamos los cortes, los glassplates (planchas) y los scraps (sobrantes)
    pieces_to_cut = input_data['pieces_to_cut']
    scraps = stock_data['scraps']
    glassplates = stock_data['glassplates']

    # Para cada una de las piezas guardamos sus dimensiones originales
    original_piece_dimensions = {p['id']: (p['width'], p['height']) for p in pieces_to_cut}
    total_piece_area = sum(p['width'] * p['height'] * p['quantity'] for p in pieces_to_cut)

    rects_all = [] # Lista de todas las piezas a cortar
    # Por cada pieza, agregamos a rects_all sus dimensiones (ancho, alto) y su id
    for piece in pieces_to_cut:
        rects_all.append((piece['width'], piece['height'], piece['id']))

    print("ETAPA 1: Intentando empaquetar en placas sobrantes...")

    # Convertir scraps al formato esperado por pack_plates
    scraps_as_plates = []
    for scrap in scraps:
        scraps_as_plates.append({
            'id': str(scrap['id']),
            'width': scrap['width'],
            'height': scrap['height'],
            'quantity': 1,
            'color': scrap.get('color'),
            'glass_type': scrap.get('glass_type'),
            'thickness': scrap.get('thickness'),
            'ref_number': scrap.get('ref_number')
        })

    bin_details_map = {} # Mapa de detalles de las planchas usadas
    final_cutting_plan = [] # Lista final del plan de corte
    
    # Usar pack_plates para sobrantes
    added_counts = Counter([r[2] for r in rects_all])
    unfitted_counts = added_counts.copy()  # Inicialmente todas están sin empacar
    
    unpacked_final_list = pack_plates(
        scraps_as_plates, bin_details_map, rects_all, final_cutting_plan, 
        original_piece_dimensions, unfitted_counts, 'Leftover', 'ETAPA1'
    )

    # ETAPA 2: Empaquetar piezas restantes en placas nuevas
    if unpacked_final_list:
        total_unfitted = sum(item['quantity_unpacked'] for item in unpacked_final_list)
        print(f"\n✨ {total_unfitted} piezas no cupieron en sobrantes. Pasando a ETAPA 2 (planchas del stock)...")

        # Preparar rects para los no empacados
        rects_unfitted = []
        for item in unpacked_final_list:
            rid = item['id']
            quantity = item['quantity_unpacked']
            original_w, original_h = original_piece_dimensions[rid]
            for _ in range(quantity):
                rects_unfitted.append((original_w, original_h, rid))
        
        # Calcular unfitted_counts para ETAPA 2
        unfitted_counts = Counter([r[2] for r in rects_unfitted])
        unpacked_final_list = pack_plates(glassplates, bin_details_map, rects_unfitted, final_cutting_plan, original_piece_dimensions, unfitted_counts, 'New', 'ETAPA2')

        # ETAPA 3: Planchas de emergencia 3600x2500
        count = 0        
        while unpacked_final_list:
            print(f"\nQuedaron {len(unpacked_final_list)} piezas sin colocar. Intentando en plancha nueva 3600x2500...")

            # Preparar rects para los no empacados
            rects_unfitted_final = []
            for item in unpacked_final_list:
                rid = item['id']
                quantity = item['quantity_unpacked']
                original_w, original_h = original_piece_dimensions[rid]
                for _ in range(quantity):
                    rects_unfitted_final.append((original_w, original_h, rid))

            # Crear plancha de emergencia
            first_piece = pieces_to_cut[0]
            plate = {
                'id': f"3600x2500_{count}",
                'width': 2500,
                'height': 3600,
                'color': first_piece.get('color'),
                'glass_type': first_piece.get('glass_type'),
                'thickness': first_piece.get('thickness'),
                'quantity': 1
            }

            # Calcular unfitted_counts para ETAPA 3
            unfitted_counts = Counter([r[2] for r in rects_unfitted_final])
            unpacked_final_list = pack_plates([plate], bin_details_map, rects_unfitted_final, final_cutting_plan, original_piece_dimensions, unfitted_counts, 'New', f'ETAPA3_{count}')
    else:
        print("\n✅ ¡Todas las piezas cupieron en las placas de sobrante!")

    return final_cutting_plan, unpacked_final_list, bin_details_map, total_piece_area

def pack_plates(plates, bin_details_map, rects_unfitted, final_cutting_plan, original_piece_dimensions, unfitted_counts, plate_type='New', etapa_name='ETAPA'):

    bins_to_add = []
    bins_map = {}
    
    for plate in plates:
        for i in range(int(plate.get('quantity', 1))):
            # Generar ID según el tipo
            if plate_type == 'Leftover':
                plate_id = f"Sobrante_{plate['id']}"
            else:
                plate_id = f"Plancha_{plate['id']}_{i+1}"
            
            bins_to_add.append((plate['width'], plate['height'], plate_id))
            bins_map[plate_id] = {'width': plate['width'], 'height': plate['height']}

            # Guardar detalles en bin_details_map
            bin_details_map[plate_id] = {
                'id': plate_id,
                'width': plate['width'],
                'height': plate['height'],
                'type': plate_type,
                'color': plate.get('color'),
                'glass_type': plate.get('glass_type'),
                'thickness': plate.get('thickness'),
                'ref_number': plate.get('ref_number')  # Preservar número de referencia para trazabilidad
            }
    
    # Probamos heurísticas
    res = _try_guillotine_variants(rects_unfitted, bins_to_add, bins_map, rotation=True)
    
    # Verificar que res no sea None
    if res is None:
        res = {
            'best_result': None,
            'best_packer': None,
            'metrics': (0, 0, 0, set(), float('inf')),
            'heuristic': (None, None, None),
            'free_rects': [],
            'unused_rects': []
        }
    
    best_free_rects = res.get('free_rects', [])
    best_unused_rects = res.get('unused_rects', [])

    if res and res['best_result']:
        algo, sort, bin_algo = res['heuristic']
        placed_count, placed_area, bin_area_used, bins_used, waste = res['metrics']
        print(f"[{etapa_name}] Mejor heurística: Algoritmo - {algo.__name__}, Ordenamiento - {sort}, BinAlgo: {bin_algo}.")
        print(f"[{etapa_name}] Colocadas: {placed_count}, Área colocada: {placed_area}, Área bins usados: {bin_area_used}, Desperdicio: {waste}")

        best_packer = res['best_packer']
        for rect in res['best_result']:
            b_idx, x, y, w, h, rid = rect
            bid = str(best_packer[b_idx].bid)
            original_w, original_h = original_piece_dimensions[rid]
            is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h)

            final_cutting_plan.append({
                'Piece_ID': rid, 'Source_Plate_ID': bid, 'Source_Plate_Type': plate_type,
                'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated, 'Is_Waste': False,
                'Is_Unused': False

            })

        # Agregar los free rects (sobrantes) al plan de corte
        print(f"[{etapa_name}] DEBUG: Free rects encontrados: {len(best_free_rects)}")
        for i, (bid, fx, fy, fw, fh) in enumerate(best_free_rects):
            print(f"[{etapa_name}] Sobrante {i+1}: Plancha={bid}, Pos=({fx},{fy}), Dim=({fw}x{fh})")
            final_cutting_plan.append({
                'Piece_ID': f"Sobrante_{str(bid)}_{fx}_{fy}",  # ID único para el sobrante
                'Source_Plate_ID': str(bid),
                'Source_Plate_Type': plate_type,
                'X_Coordinate': fx,
                'Y_Coordinate': fy,
                'Packed_Width': fw,
                'Packed_Height': fh,
                'Is_Rotated': False,
                'Is_Waste': True,
                'Is_Unused': False
            })
        
        for i, (bid, fx, fy, fw, fh) in enumerate(best_unused_rects):
            final_cutting_plan.append({
                'Piece_ID': f"SobranteInutil_{str(bid)}_{fx}_{fy}", 
                'Source_Plate_ID': str(bid),
                'Source_Plate_Type': plate_type,
                'X_Coordinate': fx,
                'Y_Coordinate': fy,
                'Packed_Width': fw,
                'Packed_Height': fh,
                'Is_Rotated': False,
                'Is_Waste': True,
                'Is_Unused': True
            })
        
        print(f"[{etapa_name}] Sobrantes agregados al plan: {len(best_free_rects)}")

        # Calcular restantes no empacados
        placed_rids = [r[5] for r in res['best_result']]
        added_counts = Counter([r[2] for r in rects_unfitted])
        placed_counts = Counter(placed_rids)
        remaining_unfitted = added_counts - placed_counts
        unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in remaining_unfitted.items()]
    else:
        print(f"[{etapa_name}] Ninguna heurística pudo colocar piezas en las placas.")
        # Si no se pudo colocar nada, marcar todo como sin empacar
        unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in unfitted_counts.items()]
    
    return unpacked_final_list

# Metodo que usamos para borrar la carpeta output_visuals vieja
def cleanup_previous_outputs():
    shutil.rmtree('output_visual', ignore_errors=True)
    shutil.rmtree('output_visuals', ignore_errors=True)

if __name__ == "__main__":
    args = parse_args()

    input_data = None
    stock_data = None

    if args.stdin:
        try:
            body = json.load(sys.stdin)
            if not isinstance(body, dict) or 'pieces_to_cut' not in body or 'stock' not in body:
                print("Error: stdin JSON must be an object with 'pieces_to_cut' and 'stock' keys.", file=sys.stderr)
                exit(1)
            # Guardamos del cuerpo del body los cortes a realizar y el stock
            input_data = {'pieces_to_cut': body['pieces_to_cut']}
            stock_data = body['stock']
            print("[LOG] Input and stock read from stdin")
        except Exception as e:
            print(f"Error reading JSON from stdin: {e}", file=sys.stderr)
            exit(1)
    else:
        print(f"Error: no hay args.stdin")
        exit()
        # Esto estaba antes, era teniamos los datos en archivos json
        """ if args.inp:
            # primero intentar parsear como JSON literal
            try:
                input_data = json.loads(args.inp)
            except Exception:
                # si falla, intentar tratar como path a archivo
                if os.path.exists(args.inp):
                    try:
                        with open(args.inp, 'r') as f:
                            input_data = json.load(f)
                    except Exception as e:
                        print(f"Error leyendo JSON desde '{args.inp}': {e}")
                        exit()
                else:
                    print(f"El argumento --inp no es un JSON válido ni un path existente: {args.inp}")
                    exit()
        else:
            INPUT_FILE = 'inputs.json'
            try:
                with open(INPUT_FILE, 'r') as f:
                    input_data = json.load(f)
            except FileNotFoundError:
                print(f"Error: El archivo de entrada '{INPUT_FILE}' no fue encontrado.")
                exit()
            except json.JSONDecodeError:
                print(f"Error: El archivo '{INPUT_FILE}' no es un JSON válido.")
                exit()

        STOCK_FILE = 'stock_data.json'
        try:
            with open(STOCK_FILE, 'r') as f:
                stock_data = json.load(f)
        except FileNotFoundError:
            print(f"Error: El archivo de stock '{STOCK_FILE}' no fue encontrado.")
            exit()
        except json.JSONDecodeError:
            print(f"Error: El archivo '{STOCK_FILE}' no es un JSON válido.")
            exit()
 """
    # Borramos la capreta output_visuals vieja para que no quede nada viejo
    cleanup_previous_outputs()

    # Llamamos al optimizador y guardamos los resultados: los cortes que no entraron en ningun lado, etc
    final_plan, unpacked_items, bin_details, piece_area = run_optimizer(input_data, stock_data)

    if final_plan:
        # Asegurar que existan los directorios de salida
        try:
            os.makedirs('output_plan', exist_ok=True)
            os.makedirs('output_visuals', exist_ok=True)
            print("[LOG] Directorios de salida verificados/creados: output_plan, output_visuals")
        except Exception as e:
            print(f"[ERROR] No se pudieron crear los directorios de salida: {e}")
            pass

        print_summary(final_plan, unpacked_items, bin_details, piece_area)
        # --- Filtrar campos extra antes de guardar el CSV ---
        allowed_keys = [
            'Piece_ID', 'Source_Plate_ID', 'Source_Plate_Type',
            'X_Coordinate', 'Y_Coordinate', 'Packed_Width', 'Packed_Height', 'Is_Rotated'
        ]
        final_plan_for_csv = [
            {k: v for k, v in item.items() if k in allowed_keys}
            for item in final_plan
        ]
        save_cutting_plan_to_csv(final_plan_for_csv)
        # Asegurarse de que las coordenadas que pasamos a la visualización sean ints
        for item in final_plan:
            for k in ('X_Coordinate','Y_Coordinate','Packed_Width','Packed_Height'):
                if k in item:
                    try:
                        item[k] = int(item[k])
                    except Exception:
                        pass

        # Limpiar imágenes viejas de los bins usados para evitar confusión
        try:
            output_folder = 'output_visuals'
            if os.path.exists(output_folder):
                used_bins = set(p['Source_Plate_ID'] for p in final_plan)
                for b in used_bins:
                    pth = os.path.join(output_folder, f"{b}.png")
                    if os.path.exists(pth):
                        try:
                            os.remove(pth)
                        except Exception:
                            pass
        except Exception:
            pass

        # Generar visualizaciones para cada placa por separado para asegurar
        # que se escribe un PNG por cada placa utilizada.
        used_bins = sorted(set(p['Source_Plate_ID'] for p in final_plan))
        for b in used_bins:
            pieces_for_bin = [p for p in final_plan if p['Source_Plate_ID'] == b]
            try:
                visualize_packing(pieces_for_bin, {b: bin_details[b]})
            except Exception:
                # Fallback: intentar con todo el mapa si falla por cualquier razón
                try:
                    visualize_packing(final_plan, bin_details)
                except Exception:
                    pass
    else:
        print("\n❌ No se pudo generar un plan de corte con los recursos disponibles.")