import json
import os
from collections import Counter
import random
from rectpack import newPacker, PackingMode, PackingBin
from rectpack.guillotine import GuillotineBssfSlas
from rectpack.packer import SORT_AREA, SORT_PERI, SORT_DIFF, SORT_SSIDE, SORT_LSIDE, SORT_RATIO, SORT_NONE
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
    bins_used = []
    # Se recorre la lista de rects para obtener los ids de las planchas usadas
    for r in rects:
        b_idx = r[0]
        # bid lo definimos como string al crear los bins
        try:
            bid = str(packer[b_idx].bid)
        except Exception:
            # Fallback: si la API difiere, intentar extraer de r
            bid = str(r[0])
        if bid not in bins_used:
            bins_used.append(bid)

    # bin_area_used: suma de área de las planchas usadas según bins_map (si no está, lo ignoramos)
    bin_area_used = 0
    for b in bins_used:
        binfo = bins_map.get(b)
        if binfo:
            bin_area_used += binfo['width'] * binfo['height']

    return placed_count, placed_area, bin_area_used, bins_used

def get_free_rects_from_packer(packer):
    free_rects = []
    unused_rects = []

    # recorremos las planchas usadas para obtener los sobrantes
    for b_idx, b in enumerate(packer):
        # guardamos las dimensiones de la plancha y su id
        bin_w, bin_h = b.width, b.height
        bid = b.bid

        # obtenemos las piezas colocadas en esta plancha
        placed = [r for r in packer.rect_list() if r[0] == b_idx]
        if not placed:
            # si ningun rect fue colocado, toda la plancha es sobrante
            free_rects.append((bid, 0, 0, bin_w, bin_h))
            continue

        # en spaces vamos a guardar los espacios libres que van quedando, incialmente es toda la plancha
        spaces = [(0, 0, bin_w, bin_h)]

        # recorremos las piezas colocadas para ir cortando los espacios
        for _, x, y, w, h, _ in placed:
            new_spaces = []
            # recorremos los espacios actuales
            for sx, sy, sw, sh in spaces:
                # Si no hay intersección → conservar, es decir que 
                if x >= sx + sw or x + w <= sx or y >= sy + sh or y + h <= sy:
                    new_spaces.append((sx, sy, sw, sh))
                    continue

                # --- Corte exacto por geometría rectangular ---
                ix0 = max(sx, x)
                iy0 = max(sy, y)
                ix1 = min(sx + sw, x + w)
                iy1 = min(sy + sh, y + h)

                # Arriba
                if iy0 > sy:
                    new_spaces.append((sx, sy, sw, iy0 - sy))
                # Abajo
                if iy1 < sy + sh:
                    new_spaces.append((sx, iy1, sw, (sy + sh) - iy1))
                # Izquierda
                if ix0 > sx:
                    new_spaces.append((sx, iy0, ix0 - sx, iy1 - iy0))
                # Derecha
                if ix1 < sx + sw:
                    new_spaces.append((ix1, iy0, (sx + sw) - ix1, iy1 - iy0))

            spaces = new_spaces

        # Limpiar espacios inválidos
        spaces = [(sx, sy, sw, sh) for (sx, sy, sw, sh) in spaces if sw > 1 and sh > 1]
        spaces = merge_adjacent_rects(spaces)

        # Clasificar según tamaño mínimo
        for sx, sy, sw, sh in spaces:
            if sw < 200 or sh < 200:
                unused_rects.append((bid, sx, sy, sw, sh))
            else:
                free_rects.append((bid, sx, sy, sw, sh))

    return free_rects, unused_rects


# Este metodo recibe las piezas a cortar y el stock (sobrantes y planchas nuevas).
# bins_to_add es basicamente los sobrantes que se estan usando y en bins_map tenemos los mismos sobrantes pero sirve para calcular las metricas
def _try_guillotine_variants(rects_to_add, bins_to_add, bins_map, rotation=True):
    guillotine_algos = [GuillotineBssfSlas]
    sort_algos_builtin = [SORT_AREA, SORT_PERI, SORT_DIFF, SORT_SSIDE, SORT_LSIDE, SORT_RATIO, SORT_NONE]
    custom_sorts = ["BY_WIDTH", "BY_HEIGHT", "BY_AREA_DESC", "SHUFFLE"]
    bin_algos = [PackingBin.BFF, PackingBin.BBF]

    best_score = None
    best_data = None

    # lista para guardar los rectángulos sobrantes de cada intento
    all_free_rects = []
    all_unused_rects = []

    # Función para evaluar una heurística y guardar sus free_rects
    def evaluate_variant(packer, algo, sort_used, bin_algo):

        nonlocal best_score, best_data, all_free_rects, all_unused_rects
        placed_count, placed_area, bin_area_used, bins_used = _evaluate_packer(packer, bins_map)
        waste = (bin_area_used - placed_area) if bin_area_used > 0 else float('inf')
        # Obtenemos los sobrantes de este intento
        free_rects, unused_rects = get_free_rects_from_packer(packer)
        all_unused_rects = unused_rects
        all_free_rects = free_rects

        # IMPORTANTE DEFINIR BUENAS METRICAS, PARA ELEGIR LA MEJOR HEURISTICA

        # Calcular métricas de calidad de sobrantes
        # Área total de sobrantes útiles (grandes, reutilizables)
        usable_waste_area = sum(fw * fh for _, _, _, fw, fh in free_rects)
        # Cantidad de sobrantes inútiles (pequeños, no reutilizables)
        unusable_count = len(unused_rects)
        # Área promedio de sobrantes útiles (preferir pocos y grandes vs muchos pequeños)
        avg_usable_size = (usable_waste_area / len(free_rects)) if free_rects else 0
        
        # Siempre elegir usar menos planchas y todas las piezas colocadas
        if waste == 0:
            score = float('inf')
        else:
            score = (
                placed_count * 100000000 +        # Prioridad 0: piezas colocadas (máxima)
                (-len(bins_used) * 10000000) +    # Prioridad 1: MENOS PLANCHAS (crítico)
                (-waste) +                         # Prioridad 2: menos desperdicio
                (avg_usable_size * 10) +          # Prioridad 3: sobrantes grandes
                (-unusable_count * 50000)         # Prioridad 4: penalizar sobrantes inútiles
            )
        
        # Mostrar métricas de cada variante prometedora
        #if placed_count > 0:
        #    print(f"  [{algo.__name__}/{sort_used}/{bin_algo}] "
        #          f"Planchas:{len(bins_used)}, Piezas:{placed_count}, Waste:{waste:.0f}, "
        #          f"AvgSobrante:{avg_usable_size:.0f}, Inútiles:{unusable_count}, "
        #          f"Score:{score:.0f}")

        if best_score is None or score > best_score:
            best_score = score
            best_data = {
                'best_packer': packer,
                'best_result': packer.rect_list(),
                'metrics': (placed_count, placed_area, bin_area_used, bins_used, waste),
                'heuristic': (algo, sort_used, bin_algo),
                'free_rects': free_rects,
                'unused_rects': unused_rects,
                'quality_metrics': {
                    'usable_waste_area': usable_waste_area,
                    'unusable_count': unusable_count,
                    'avg_usable_size': avg_usable_size,
                    'score': score
                }
            }

    # Heuristicas de la libreria
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

            # Heurísticas personalizadas
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

    # devolvemos los free_rects acumulados y los de la mejor heurística
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
            'metrics': (0, 0, 0, [], float('inf')),
            'heuristic': (None, None, None),
            'free_rects': [],
            'unused_rects': [],
            'all_free_rects': all_free_rects,
            'all_unused_rects': all_unused_rects
        }

def run_optimizer(input_data, stock_data):
    global GLOBAL_CUTS_ACCUMULATOR
    
    # Guardamos los cortes, los glassplates (planchas) y los scraps (sobrantes)
    pieces_to_cut = input_data['pieces_to_cut']
    scraps = stock_data['scraps']
    glassplates = stock_data['glassplates']

    id_stock_used = {"deleted_stock": [], "deleted_scrap": []}
    scraps_to_create = {}

    # Para cada una de las piezas guardamos sus dimensiones originales
    original_piece_dimensions = {p['id']: (p['width'], p['height'], p['typology'], p['class_cut'], p['cardinal'], p['innertube'], p['work'], p['id_work']) for p in pieces_to_cut}
    print(original_piece_dimensions)
    # Esto se usa para calcular metricas
    total_piece_area = sum(p['width'] * p['height'] * p['quantity'] for p in pieces_to_cut)

    rects_all = [] # Lista de todas las piezas a cortar
    # Por cada pieza, agregamos a rects_all sus dimensiones (ancho, alto) y su id
    for piece in pieces_to_cut:
        rects_all.append((piece['width'], piece['height'], piece['id']))

    print("ETAPA 1: Intentando empaquetar en placas sobrantes...")

    # Convertir scraps al formato esperado por pack_plates
    scraps_as_plates_base = []
    for scrap in scraps:
        scraps_as_plates_base.append({
            'id': str(scrap['id']),
            'width': scrap['width'],
            'height': scrap['height'],
            'quantity': 1,
            'color': scrap.get('color'),
            'glass_type': scrap.get('glass_type'),
            'thickness': scrap.get('thickness'),
            'ref_number': scrap.get('ref_number')
        })

    # Definir las formas de ordenamiento
    orderings = [
        ('area_asc', lambda x: x['width'] * x['height']),
        ('area_desc', lambda x: -(x['width'] * x['height'])),
        ('width_asc', lambda x: x['width']),
        ('width_desc', lambda x: -x['width']),
        ('height_asc', lambda x: x['height']),
        ('height_desc', lambda x: -x['height']),
    ]

    best_score = None
    best_result = None

    for order_name, key_func in orderings:
        scraps_as_plates = sorted(scraps_as_plates_base, key=key_func)
        bin_details_map = {}
        final_cutting_plan = []
        added_counts = Counter([r[2] for r in rects_all])
        unfitted_counts = added_counts.copy()
        bins_used = []
        unpacked_final_list, bins_used = pack_plates(
            scraps_as_plates, bin_details_map, rects_all, final_cutting_plan,
            original_piece_dimensions, unfitted_counts, 'Leftover', f'ETAPA1_{order_name}', pieces_to_cut=pieces_to_cut
        )
        # Calcular métricas para elegir el mejor resultado
        placed_count = sum(1 for item in final_cutting_plan if not item.get('Is_Waste', False))
        bins_count = len(bins_used)
        
        # Calcular área total utilizada de los sobrantes
        total_bin_area = sum(
            bin_details_map.get(bid, {}).get('width', 0) * bin_details_map.get(bid, {}).get('height', 0)
            for bid in bins_used
        )
        
        # Score: priorizar más piezas colocadas, luego menos sobrantes, luego menos área
        score = (
            placed_count * 1000000 -     # Prioridad 1: más piezas colocadas
            bins_count * 10000 -          # Prioridad 2: menos sobrantes usados
            total_bin_area                # Prioridad 3: menor área total usada
        )
        
        if best_score is None or score > best_score:
            best_score = score
            best_result = (unpacked_final_list, bins_used, bin_details_map, final_cutting_plan)

    # Usar el mejor resultado encontrado
    unpacked_final_list, bins_used, bin_details_map, final_cutting_plan = best_result
    
    id_stock_used = get_plate_and_scrap_ids_from_bin_details(bins_used)

    # ETAPA 2: Empaquetar piezas restantes en placas nuevas
    if unpacked_final_list:
        total_unfitted = sum(item['quantity_unpacked'] for item in unpacked_final_list)
        print(f"\n✨ {total_unfitted} piezas no cupieron en sobrantes. Pasando a ETAPA 2 (planchas del stock)...")

        # Preparar rects para los no empacados
        rects_unfitted = []
        for item in unpacked_final_list:
            # Por cada pieza no empacada se queda con el id, luego busca ese id en original_piece_dimensions para obtener sus dimensiones
            rid = item['id']
            quantity = item['quantity_unpacked']
            original_w, original_h, typology, class_cut, cardinal, innertube, work, id_work = original_piece_dimensions[rid]
            # Si tenemos 10 piezas V5 va a agregar las 10
            for _ in range(quantity):
                rects_unfitted.append((original_w, original_h, rid))
        
        # Calcular unfitted_counts para ETAPA 2
        unfitted_counts = Counter([r[2] for r in rects_unfitted])
        unpacked_final_list, bins_used = pack_plates(
            glassplates, bin_details_map, rects_unfitted, final_cutting_plan, 
            original_piece_dimensions, unfitted_counts, 'New', 'ETAPA2', pieces_to_cut=pieces_to_cut
        )

        id_stock_used_aux = get_plate_and_scrap_ids_from_bin_details(bins_used)
        id_stock_used["deleted_stock"] += id_stock_used_aux.get("deleted_stock", [])
        id_stock_used["deleted_scrap"] += id_stock_used_aux.get("deleted_scrap", [])

        # ETAPA 3: Planchas de proveedor 3600x2500
        count = 0        
        while unpacked_final_list:
            print(f"\nQuedaron {len(unpacked_final_list)} piezas sin colocar. Intentando en plancha nueva 3600x2500...")

            # Preparar rects para los no empacados
            rects_unfitted_final = []
            for item in unpacked_final_list:
                rid = item['id']
                quantity = item['quantity_unpacked']
                original_w, original_h, typology, class_cut, cardinal, innertube, work, id_work = original_piece_dimensions[rid]
                for _ in range(quantity):
                    rects_unfitted_final.append((original_w, original_h, rid))

            # Como se llama al optimizador por cada grupo de cortes, todos los cortes de pieces_to_cut van a tener
            # el mismo color, glass_type y thickness, por lo que podemos tomar el primero
            # Luego creamos la plancha 3600x2500 con esos atributos
            first_piece = pieces_to_cut[0]
            if first_piece.get('glass_type') == 'COL':
                plate = {
                    'id': f"3210x2400_{count}",
                    'width': 2400,
                    'height': 3210,
                    'color': first_piece.get('color'),
                    'glass_type': first_piece.get('glass_type'),
                    'thickness': first_piece.get('thickness'),
                    'quantity': 1
                }
            else:
                plate = {
                    'id': f"3600x2500_{count}",
                    'width': 2500,
                    'height': 3600,
                    'color': first_piece.get('color'),
                    'glass_type': first_piece.get('glass_type'),
                    'thickness': first_piece.get('thickness'),
                    'quantity': 1
                }
            count += 1

            # Calcular unfitted_counts para ETAPA 3
            unfitted_counts = Counter([r[2] for r in rects_unfitted_final])
            unpacked_final_list, bins_used = pack_plates(
                [plate], bin_details_map, rects_unfitted_final, final_cutting_plan, 
                original_piece_dimensions, unfitted_counts, 'New', f'ETAPA3_{count}', pieces_to_cut=pieces_to_cut
            )
    else:
        print("\n✅ ¡Todas las piezas cupieron en las placas de sobrante!")

    scraps_to_create = build_new_scraps_dict(final_cutting_plan)
    
    # Preparar cortes para retornar (para acumulación externa)
    cuts_for_summary = []
    for item in final_cutting_plan:
        if not item.get('Is_Waste', False):  # Solo piezas reales (no sobrantes)
            bin_info = bin_details_map.get(item['Source_Plate_ID'], {})
            cuts_for_summary.append({
                'tipologia': item.get('Typology', '-'),
                'id_pieza': item.get('Piece_ID', '-'),
                'clase': item.get('Class_Cut', 'Simple'),
                'cardinal': item.get('Cardinal', '1/1'),
                'innertube' : item.get('Innertube', '-'),
                'tipo': str(bin_info.get('glass_type', '-')).strip(),
                'grosor': str(bin_info.get('thickness', '-')).strip(),
                'color': str(bin_info.get('color', '-')).strip(),
                'ancho': item.get('Packed_Width', 0),
                'alto': item.get('Packed_Height', 0),
                'plancha': item.get('Source_Plate_ID', '-'),
                'is_rotated': item.get('Is_Rotated', False),
                'work': item.get('Work', '-'),
                'id_work': item.get('Id_Work', '-'),
            })
    
    return final_cutting_plan, unpacked_final_list, bin_details_map, total_piece_area, id_stock_used, scraps_to_create, cuts_for_summary

# method to get used plate and scrap ids from bin_details_map
def get_plate_and_scrap_ids_from_bin_details(bins_used):
    plate_ids = []
    scrap_ids = []
    for plate_id in bins_used:
        if plate_id.startswith("Plancha_"):
            # Extraer el número entre "Plancha_" y el siguiente "_"
            parts = plate_id.split("_")
            if len(parts) >= 3:
                plate_ids.append(parts[1])
        elif plate_id.startswith("Sobrante_"):
            # Extraer el id del sobrante
            parts = plate_id.split("_")
            if len(parts) >= 2:
                scrap_ids.append(parts[1])
    return {"deleted_stock": plate_ids, "deleted_scrap": scrap_ids}

# method to get usable waste pieces
def get_usable_waste_pieces(final_cutting_plan):
    return [item for item in final_cutting_plan if item.get('Is_Waste', False) and not item.get('Is_Unused', False)]

def build_new_scraps_dict(final_cutting_plan):
    scraps = get_usable_waste_pieces(final_cutting_plan)
    new_scraps = {}
    for idx, scrap in enumerate(scraps, 1):
        scrap_key = f"scrap_{idx}_{scrap.get("glass_type")}"
        new_scraps[scrap_key] = {
            "width": scrap.get("Packed_Width"),
            "height": scrap.get("Packed_Height"),
            "color": scrap.get("color"),
            "thickness": scrap.get("thickness"),
            "glass_type": scrap.get("glass_type")
        }
    return {"new_scraps": new_scraps}

def pack_plates(plates, bin_details_map, rects_unfitted, final_cutting_plan, original_piece_dimensions, unfitted_counts, plate_type='New', etapa_name='ETAPA', pieces_to_cut=None):

    bins_to_add = []
    bins_used = []
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
                'ref_number': plate.get('ref_number')
            }
    
    # Probamos heurísticas
    res = _try_guillotine_variants(rects_unfitted, bins_to_add, bins_map, rotation=True)
    
    # Si res es None, inicializamos con valores por defecto, en res vamos a guardar la mejor heurística
    if res is None:
        res = {
            'best_result': None,
            'best_packer': None,
            'metrics': (0, 0, 0, [], float('inf')),
            'heuristic': (None, None, None),
            'free_rects': [],
            'unused_rects': []
        }
    
    # Se obtienen los sobrantes (reutlizable e inutiles) de la mejor heurística
    best_free_rects = res.get('free_rects', [])
    best_unused_rects = res.get('unused_rects', [])

    if res and res['best_result']:
        algo, sort, bin_algo = res['heuristic']
        placed_count, placed_area, bin_area_used, bins_used, waste = res['metrics']
        #print(f"[{etapa_name}] Mejor heurística: Algoritmo - {algo.__name__}, Ordenamiento - {sort}, BinAlgo: {bin_algo}.")
        #print(f"[{etapa_name}] Colocadas: {placed_count}, Área colocada: {placed_area}, Área bins usados: {bin_area_used}, Desperdicio: {waste}")
        
        # Mostrar métricas de calidad
        if 'quality_metrics' in res:
            qm = res['quality_metrics']
            #print(f"[{etapa_name}] 📊 Calidad: Sobrantes útiles área={qm['usable_waste_area']:.0f}, "
            #      f"Avg={qm['avg_usable_size']:.0f}, Inútiles={qm['unusable_count']}, Score={qm['score']:.0f}")

        best_packer = res['best_packer']
        for rect in res['best_result']:
            b_idx, x, y, w, h, rid = rect
            bid = str(best_packer[b_idx].bid)
            original_w, original_h, typology, class_cut, cardinal, innertube, work, id_work = original_piece_dimensions[rid]
            is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h)
            
            is_transformed = False
            if plate['glass_type'] == 'LAM' and plate['thickness'] == '3+3' and plate['color'] == 'INC':
                pieza = next(
                    (p for p in pieces_to_cut
                    if p['id'] == rid and p['type_opening'] == 'Aluminio' and (p['width'] == original_w and p['height'] == original_h or p['width'] == original_h and p['height'] == original_w)
                    ),
                    None
                )                
                if pieza and pieza.get('is_transformed'):
                    is_transformed = True

            final_cutting_plan.append({
                'Piece_ID': rid, 'Source_Plate_ID': bid, 'Source_Plate_Type': plate_type,
                'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated, 'Is_Waste': False,
                'Is_Unused': False, 'Is_Transformed': is_transformed, 'Typology': typology, 'Class_Cut': class_cut, 'Cardinal': cardinal, 'Innertube': innertube, 'Work': work,
                'Id_Work': id_work
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
                'color': bin_details_map[bid].get('color'),
                'thickness': bin_details_map[bid].get('thickness'),
                'glass_type': bin_details_map[bid].get('glass_type'),
                'Is_Rotated': False,
                'Is_Waste': True,
                'Is_Unused': False, # Es un sobrante utilizable
                'Is_Transformed': False
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
                'Is_Unused': True, # Es un sobrante inutilizable
                'Is_Transformed': False
            })
        
        print(f"[{etapa_name}] Sobrantes agregados al plan: {len(best_free_rects)}")

        # Calcular restantes no empacados
        placed_rids = [piece[5] for piece in res['best_result']]
        placed_counts = Counter(placed_rids)
        # Obtenemos la cantidad de piezas que deberian haberse empaquetado en esta etapa
        added_counts = Counter([r[2] for r in rects_unfitted])
        # Hacemos la diferencia para ver si quedaron piezas sin empacar
        remaining_unfitted = added_counts - placed_counts
        # Si queda alguna pieza sin empacar, la guardamos en unpacked_final_list, donde vamos a guardar 
        # el id (tipologia) de la pieza y la cantidad que no se pudo empacar
        unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in remaining_unfitted.items()]
    else:
        # Entra por aca si ninguna heurística pudo colocar piezas, pero no deberia pasar nunca
        print(f"[{etapa_name}] Ninguna heurística pudo colocar piezas en las placas.")
        # Si no se pudo colocar nada, marcar todo como sin empacar
        unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in unfitted_counts.items()]
    
    return unpacked_final_list, bins_used

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
    final_plan, unpacked_items, bin_details, piece_area, id_stock_used, scraps_to_create, cuts_for_summary = run_optimizer(input_data, stock_data)

    filtered_pieces = [p for p in final_plan if str(p.get('Piece_ID', '')).startswith('V')]

    result = {
        "new_scraps": scraps_to_create["new_scraps"],
        "deleted_stock": id_stock_used["deleted_stock"],
        "deleted_scrap": id_stock_used["deleted_scrap"],
        "final_pieces": filtered_pieces,
        "cuts_for_summary": cuts_for_summary
    }

    print(json.dumps(result))
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

        # Limpiar PDFs viejos si ya no hay imágenes PNG en output_visuals
        try:
            output_folder = 'output_visuals'
            if os.path.exists(output_folder):
                png_files = [f for f in os.listdir(output_folder) if f.endswith('.png')]
                if not png_files:
                    pdf_files = [f for f in os.listdir(output_folder) if f.endswith('.pdf')]
                    for pdf in pdf_files:
                        pdf_path = os.path.join(output_folder, pdf)
                        try:
                            os.remove(pdf_path)
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