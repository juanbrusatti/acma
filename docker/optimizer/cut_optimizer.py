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

    # Definimos los algoritmos y variantes a probar
    guillotine_algos = [GuillotineBssfSlas] # Un solo algortimo Guillotina
    sort_algos_builtin = [SORT_AREA, SORT_PERI, SORT_DIFF, SORT_SSIDE, SORT_LSIDE, SORT_RATIO, SORT_NONE] # Diferentes formas de ordenar las piezas antes de colocarlas
    custom_sorts = ["BY_WIDTH", "BY_HEIGHT", "BY_AREA_DESC", "SHUFFLE"] # Sorts personalizados que no estan en la libreria
    bin_algos = [PackingBin.BFF, PackingBin.BBF] # Diferentes formas de elegir las planchas, Best Fit o Best Better Fit

    # Variables usadas para guardar la mejor heurística y sus resultados
    best_score = None
    best_data = None

    # Probar todas las combinaciones de algoritmos y variantes
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
                # Le decimos al packer las piezas y planchas a usar
                for (w, h, rid) in rects_to_add:
                    packer.add_rect(width=w, height=h, rid=rid)
                for (bw, bh, bid) in bins_to_add:
                    packer.add_bin(width=bw, height=bh, bid=bid)
                try:
                    packer.pack()
                except Exception:
                    continue
                # Guardamos las siguientes metricas: cantidad de piezas colocadas, area colocada, area de las planchas usadas, ids de las planchas usadas
                placed_count, placed_area, bin_area_used, bins_used = _evaluate_packer(packer, bins_map)
                # Dejamos en waste el area que quedo "desperciada" en las planchas usadas
                waste = (bin_area_used - placed_area) if bin_area_used > 0 else float('inf')
                # Dejamos como metricas la cantidad de cortes colocados, el area desperdiciada (negativa para maximizar) y la cantidad de planchas usadas (negativa para maximizar)
                metrics = (placed_count, -waste, -len(bins_used))
                # Vamos guardando la mejor heurística
                if best_score is None or metrics > best_score:
                    best_score = metrics
                    best_data = {
                        'best_packer': packer,
                        'best_result': packer.rect_list(),
                        'metrics': (placed_count, placed_area, bin_area_used, bins_used, waste),
                        'heuristic': (algo, sort, bin_algo)
                    }

            # Arriba usabamos los algoritmos que trae la libreria, ahora usamos los nuestros
            for sort_tag in custom_sorts:
                packer = newPacker(
                    mode=PackingMode.Offline,
                    rotation=rotation,
                    pack_algo=algo,
                    sort_algo=SORT_NONE,
                    bin_algo=bin_algo
                )

                # Dejamos el sort_algo en NONE y hacemos el ordenamiento nosotros
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
                except Exception:
                    continue
                placed_count, placed_area, bin_area_used, bins_used = _evaluate_packer(packer, bins_map)
                waste = (bin_area_used - placed_area) if bin_area_used > 0 else float('inf')
                metrics = (placed_count, -waste, -len(bins_used))
                if best_score is None or metrics > best_score:
                    best_score = metrics
                    best_data = {
                        'best_packer': packer,
                        'best_result': packer.rect_list(),
                        'metrics': (placed_count, placed_area, bin_area_used, bins_used, waste),
                        'heuristic': (algo, sort_tag, bin_algo)
                    }

    return best_data

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

    # bins_map para consultar áreas por bid (strings)
    scraps_map = {str(s['id']): {'width': s['width'], 'height': s['height']} for s in scraps}

    print("ETAPA 1: Intentando empaquetar en placas sobrantes...")

    # Guardamos en bins_to_add_scraps las dimensiones y ids de los sobrantes del stock
    bins_to_add_scraps = [(s['width'], s['height'], str(s['id'])) for s in scraps]

    # Guardamos en res_scraps el mejor resultado de probar todas las heurísticas con los sobrantes
    res_scraps = _try_guillotine_variants(rects_all, bins_to_add_scraps, scraps_map, rotation=True)

    packed_in_scraps = [] # Lista de piezas que se lograron empaquetar en los sobrantes
    bin_details_map = {} # Mapa de detalles de las planchas usadas (sobrantes y nuevas)
    used_rids_after_scraps = [] # Lista de ids de piezas que se lograron empaquetar en los sobrantes

    # mapeo de detalles de sobrantes en formato esperado
    for bin_info in scraps:
        bid_str = str(bin_info['id'])
        sobrante_id = f"Sobrante_{bid_str}"
        details = {**bin_info, 'id': sobrante_id, 'type': 'Leftover'}
        bin_details_map[sobrante_id] = details

    # Si se logró empaquetar algo en los sobrantes, reconstruimos el plan de corte, primero guardamos la heurística ganadora y sus métricas
    # luego 
    if res_scraps and res_scraps['best_result']:
        algo, sort, bin_algo = res_scraps['heuristic']
        placed_count, placed_area, bin_area_used, bins_used, waste = res_scraps['metrics']
        print(f"[ETAPA1] Mejor heurística: Algoritmo - {algo.__name__}, Ordenamiento - {sort}, BinAlgo: {bin_algo}.")
        print(f"[ETAPA1] Colocadas: {placed_count}, Área colocada: {placed_area}, Área bins usados: {bin_area_used}, Desperdicio: {waste}")

        # recorremos todas las piezas colocadas en los sobrantes
        best_packer = res_scraps['best_packer']
        for rect in res_scraps['best_result']:
            b_idx, x, y, w, h, rid = rect # obtenemos el id, dimensiones y posicion de cada pieza colocada
            bid = str(best_packer[b_idx].bid) # obtenemos el id del sobrante usado
            sobrante_id = f"Sobrante_{bid}"
            original_w, original_h = original_piece_dimensions[rid] # dimensiones originales de la pieza
            is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h) # si las dimensiones no coinciden, la pieza fue rotada

            # Guardamos toda la informacion de la pieza
            packed_in_scraps.append({
                'Piece_ID': rid, 'Source_Plate_ID': sobrante_id, 'Source_Plate_Type': 'Leftover',
                'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated
            })
            used_rids_after_scraps.append(rid)

            for abin in best_packer:
                bid = str(abin.bid)
                sobrante_id = f"Sobrante_{bid}"
                bin_w, bin_h = abin.width, abin.height

                # obtener todas las piezas colocadas en este bin
                pieces_in_bin = [
                    r for r in res_scraps['best_result']
                    if str(best_packer[r[0]].bid) == bid
                ]

                waste_rects = []

                # líneas de corte (simples)
                for b_idx, x, y, w, h, rid in pieces_in_bin:
                    # derecha del corte
                    if x + w < bin_w:
                        waste_rects.append((x + w, y, bin_w - (x + w), h))
                    # abajo del corte
                    if y + h < bin_h:
                        waste_rects.append((x, y + h, w, bin_h - (y + h)))
                    # esquina diagonal (opcional, completa)
                    if x + w < bin_w and y + h < bin_h:
                        waste_rects.append((x + w, y + h, bin_w - (x + w), bin_h - (y + h)))

                # evitar duplicados y filtrar rectángulos mínimos
                seen = set()
                for wx, wy, ww, wh in waste_rects:
                    key = (round(wx), round(wy), round(ww), round(wh))
                    if key not in seen and ww > 2 and wh > 2:
                        seen.add(key)
                        packed_in_scraps.append({
                            'Piece_ID': f"{sobrante_id}",
                            'Source_Plate_ID': sobrante_id,
                            'Source_Plate_Type': 'Leftover',
                            'X_Coordinate': wx,
                            'Y_Coordinate': wy,
                            'Packed_Width': ww,
                            'Packed_Height': wh,
                            'Is_Rotated': False,
                            'Is_Waste': True
                        })
                
    else:
        print("[ETAPA1] Ninguna heurística colocó piezas en los sobrantes.")

    # Calcular piezas que quedaron sin colocar, comparando las que intentamos colocar con las que se lograron colocar
    added_counts = Counter([r[2] for r in rects_all])
    placed_counts = Counter(used_rids_after_scraps)
    unfitted_counts = added_counts - placed_counts

    # Esta es la lista final de cortes que se lograron empaquetar en sobrantes
    final_cutting_plan = packed_in_scraps.copy()
    unpacked_final_list = []

    # ETAPA 2: Empaquetar piezas restantes en placas nuevas
    if unfitted_counts:
        total_unfitted = sum(unfitted_counts.values())
        print(f"\n✨ {total_unfitted} piezas no cupieron en sobrantes. Pasando a ETAPA 2 (planchas del stock)...")

        # Preparar rects para los no empacados
        rects_unfitted = []
        for rid, count in unfitted_counts.items():
            original_w, original_h = original_piece_dimensions[rid]
            for _ in range(count):
                rects_unfitted.append((original_w, original_h, rid))
        # Preparar bins y bins_map para las planchas nuevas
        bins_to_add_new = []
        bins_map_new = {}
        for plate in glassplates:
            for i in range(int(plate.get('quantity', 1))):
                new_plate_id = f"Plancha_{plate['id']}_{i+1}"
                bins_to_add_new.append((plate['width'], plate['height'], new_plate_id))
                bins_map_new[new_plate_id] = {'width': plate['width'], 'height': plate['height']}

                # guardar detalles en bin_details_map (tipo New)
                bin_details_map[new_plate_id] = {
                    'id': new_plate_id,
                    'width': plate['width'],
                    'height': plate['height'],
                    'type': 'New',
                    'color': plate.get('color'),
                    'glass_type': plate.get('glass_type'),
                    'thickness': plate.get('thickness')
                }

        # Probamos heuristicas para las planchas nuevas
        res_new = _try_guillotine_variants(rects_unfitted, bins_to_add_new, bins_map_new, rotation=True)

        if res_new and res_new['best_result']:
            algo, sort, bin_algo = res_new['heuristic']
            placed_count, placed_area, bin_area_used, bins_used, waste = res_new['metrics']
            print(f"[ETAPA2] Mejor heurística: Algoritmo - {algo.__name__}, Ordenamiento - {sort}, BinAlgo: {bin_algo}.")
            print(f"[ETAPA2] Colocadas: {placed_count}, Área colocada: {placed_area}, Área bins usados: {bin_area_used}, Desperdicio: {waste}")

            best_packer_new = res_new['best_packer']
            for rect in res_new['best_result']:
                b_idx, x, y, w, h, rid = rect
                bid = str(best_packer_new[b_idx].bid)
                original_w, original_h = original_piece_dimensions[rid]
                is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h)

                final_cutting_plan.append({
                    'Piece_ID': rid, 'Source_Plate_ID': bid, 'Source_Plate_Type': 'New',
                    'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated
                })

            # calcular restantes no empacados
            placed_rids_new = [r[5] for r in res_new['best_result']]
            added_counts_glassplates = Counter([r[2] for r in rects_unfitted])
            placed_counts_new = Counter(placed_rids_new)
            remaining_unfitted = added_counts_glassplates - placed_counts_new
            unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in remaining_unfitted.items()]

        else:
            print("[ETAPA2] Ninguna heurística pudo colocar piezas en las planchas del stock.")
            # Si no se pudo colocar nada, marcar todo como sin empacar
            unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in unfitted_counts.items()]

        count = 0        
        while len(unpacked_final_list) > 0:

            print(f"\nQuedaron {len(unpacked_final_list)} piezas sin colocar. Intentando en plancha nueva 3600x2500...")

            # Preparar rects para los no empacados
            rects_unfitted_final = []
            for item in unpacked_final_list:
                rid = item['id']
                original_w, original_h = original_piece_dimensions[rid]
                rects_unfitted_final.append((original_w, original_h, rid))

            # Crear una sola plancha nueva de 3600x2500
            emergency_plate_id =  f"Plancha_3600x2500_{count}"
            count = count + 1
            bins_to_add_emergency = [(3600, 2500, emergency_plate_id)]
            bins_map_emergency = {emergency_plate_id: {'width': 3600, 'height': 2500}}

            # Obtengo los detalles de la plancha de emergencia por medio del primer corte de la lista
            piece = pieces_to_cut[0]
            bin_details_map[emergency_plate_id] = {
                'id': emergency_plate_id,
                'width': 3600,
                'height': 2500,
                'type': 'New',
                'color': piece.get('color'),
                'glass_type': piece.get('glass_type'),
                'thickness': piece.get('thickness')
            }

            # Intentar ubicar las piezas restantes en la plancha nueva
            res_emergency = _try_guillotine_variants(rects_unfitted_final, bins_to_add_emergency, bins_map_emergency, rotation=True)

            if res_emergency and res_emergency['best_result']:
                algo, sort, bin_algo = res_emergency['heuristic']
                placed_count, placed_area, bin_area_used, bins_used, waste = res_emergency['metrics']
                print(f"[ETAPA3] Mejor heurística: Algoritmo - {algo.__name__}, Ordenamiento - {sort}, BinAlgo: {bin_algo}.")
                print(f"[ETAPA3] Colocadas: {placed_count}, Área colocada: {placed_area}, Área bins usados: {bin_area_used}, Desperdicio: {waste}")

                best_packer_emergency = res_emergency['best_packer']
                placed_rids_emergency = []
                for rect in res_emergency['best_result']:
                    b_idx, x, y, w, h, rid = rect
                    bid = str(best_packer_emergency[b_idx].bid)
                    original_w, original_h = original_piece_dimensions[rid]
                    is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h)

                    final_cutting_plan.append({
                        'Piece_ID': rid, 'Source_Plate_ID': bid, 'Source_Plate_Type': 'Emergency',
                        'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated
                    })
                    placed_rids_emergency.append(rid)

                # Actualizar la lista de piezas no empacadas
                added_counts_emergency = Counter([r[2] for r in rects_unfitted_final])
                placed_counts_emergency = Counter(placed_rids_emergency)
                remaining_unfitted_emergency = added_counts_emergency - placed_counts_emergency
                unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in remaining_unfitted_emergency.items()]

    else:
        print("\n✅ ¡Todas las piezas cupieron en las placas de sobrante!")

    return final_cutting_plan, unpacked_final_list, bin_details_map, total_piece_area

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