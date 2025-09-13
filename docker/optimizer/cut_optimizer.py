import json
import os
from collections import Counter
from rectpack import newPacker, PackingMode, PackingBin, SORT_AREA, MaxRectsBssf
from visualize import visualize_packing
from output import save_cutting_plan_to_csv, print_summary
import argparse

# funcion para parsear args
def parse_args():
    """
    Parsea los argumentos pasados al script.
    Si no se proporciona un archivo JSON, se utilizará inputs.json por defecto.
    """

    parser = argparse.ArgumentParser(description='Run cut optimizer')
    parser.add_argument('--inp', type=str, default='inputs.json',
                        help='JSON string with input data or path to a JSON file. If omitted, reads inputs.json')
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

# logica ptincipal del programa
def run_optimizer(input_data):
    """
    Organizamos el proceso de optimización de corte en etapas para priorizar sobrantes sobre piezas nuevas.
    """
    pieces_to_cut = input_data['pieces_to_cut']
    leftover_plates = input_data['leftover_plates']
    new_stock_info = input_data['new_stock_info']

    # Diccionario para dimensiones originales y cálculo de áreas
    original_piece_dimensions = {p['id']: (p['width'], p['height']) for p in pieces_to_cut}
    total_piece_area = sum(p['width'] * p['height'] * p['quantity'] for p in pieces_to_cut)

    # ETAPA 1: Intentamos empaquetar primero en los sobrantes
    print("🚀 ETAPA 1: Intentando empaquetar en placas de sobrante...")
    packer_leftovers = newPacker(mode=PackingMode.Offline, rotation=True)

    # Añadimos las piezas a cortar al empaquetador
    # Guardamos una lista de las piezas que intentamos agregar para poder
    # comparar después cuántas efectivamente fueron colocadas (evitar depender
    # de APIs internas de rectpack que pueden no existir en todas las versiones).
    added_rects_leftovers = []
    for piece in pieces_to_cut:
        for _ in range(piece['quantity']):
            packer_leftovers.add_rect(width=piece['width'], height=piece['height'], rid=piece['id'])
            added_rects_leftovers.append(piece['id'])

    # Añadimos los sobrante al empaquetador
    for leftover in leftover_plates:
        packer_leftovers.add_bin(width=leftover['width'], height=leftover['height'], bid=leftover['id'])

    # Empaquetamos para los sobrantes
    packer_leftovers.pack()

    packed_in_leftovers = []
    bin_details_map = {}

    # Mapeamos los detalles de las placas sobrantes
    # y generamos el plan de corte para las piezas empaquetadas
    for bin_info in leftover_plates:
        bin_details_map[bin_info['id']] = {**bin_info, 'type': 'Leftover'}

    # Recorremos las piezas empaquetadas en los sobrantes
    for rect in packer_leftovers.rect_list():
        b_idx, x, y, w, h, rid = rect
        bid = packer_leftovers[b_idx].bid
        original_w, original_h = original_piece_dimensions[rid]
        is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h)

        packed_in_leftovers.append({
            'Piece_ID': rid, 'Source_Plate_ID': bid, 'Source_Plate_Type': 'Leftover',
            'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated
        })

    # Obtenemos las piezas que no cupieron en los sobrantes
    # En vez de usar métodos dependientes de la versión, comparamos lo que
    # agregamos con lo que fue realmente colocado.
    placed_rids_leftovers = [r[5] for r in packer_leftovers.rect_list()]
    added_counts = Counter(added_rects_leftovers)
    placed_counts = Counter(placed_rids_leftovers)
    unfitted_counts = added_counts - placed_counts

    # Si no hay piezas empaquetadas, no hay plan de corte
    final_cutting_plan = packed_in_leftovers
    unpacked_final_list = []

    # ETAPA 2: Empaquetar piezas restantes en placas nuevas ---
    if unfitted_counts:
        total_unfitted = sum(unfitted_counts.values())
        print(f"\n✨ {total_unfitted} piezas no cupieron en sobrantes. Pasando a ETAPA 2 (Placas Nuevas)...")
        packer_new = newPacker(mode=PackingMode.Offline, rotation=True)

        # Añadimos las piezas restantes al empaquetador (respetando cantidades)
        added_rects_new = []
        for rid, qty in unfitted_counts.items():
            original_w, original_h = original_piece_dimensions[rid]
            for _ in range(qty):
                packer_new.add_rect(width=original_w, height=original_h, rid=rid)
                added_rects_new.append(rid)

        # Añadimos las placas nuevas al empaquetador
        for i in range(new_stock_info['quantity']):
            new_plate_id = f"NewPlate_{i+1}"
            packer_new.add_bin(width=new_stock_info['width'], height=new_stock_info['height'], bid=new_plate_id)
            bin_details_map[new_plate_id] = {
                'id': new_plate_id, 'width': new_stock_info['width'], 'height': new_stock_info['height'], 'type': 'New'
            }

        # Empaquetamos para las piezas nuevas
        packer_new.pack()

        for rect in packer_new.rect_list():
            b_idx, x, y, w, h, rid = rect
            bid = packer_new[b_idx].bid
            original_w, original_h = original_piece_dimensions[rid]
            is_rotated = (w == original_h and h == original_w) and (w != original_w or h != original_h)

            final_cutting_plan.append({
                'Piece_ID': rid, 'Source_Plate_ID': bid, 'Source_Plate_Type': 'New',
                'X_Coordinate': x, 'Y_Coordinate': y, 'Packed_Width': w, 'Packed_Height': h, 'Is_Rotated': is_rotated
            })

        # Lista final de piezas no empaquetadas (comparando añadido vs colocado)
        placed_rids_new = [r[5] for r in packer_new.rect_list()]
        added_counts_new = Counter(added_rects_new)
        placed_counts_new = Counter(placed_rids_new)
        remaining_unfitted = added_counts_new - placed_counts_new
        unpacked_final_list = [{'id': pid, 'quantity_unpacked': count} for pid, count in remaining_unfitted.items()]

    else:
        print("\n✅ ¡Todas las piezas cupieron en las placas de sobrante!")

    return final_cutting_plan, unpacked_final_list, bin_details_map, total_piece_area

if __name__ == "__main__":
    args = parse_args()

    input_data = None
    if args.inp:
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

    # Limpiar outputs previos (cutting_plan y visualizaciones) antes de cada ejecución
    def cleanup_previous_outputs():
        try:
            # borrar CSV previo
            csv_path = os.path.join('output_plan', 'cutting_plan.csv')
            if os.path.exists(csv_path):
                try:
                    os.remove(csv_path)
                except Exception:
                    pass

            # borrar imágenes previas
            visuals_dir = 'output_visuals'
            if os.path.isdir(visuals_dir):
                for fname in os.listdir(visuals_dir):
                    fpath = os.path.join(visuals_dir, fname)
                    try:
                        if os.path.isfile(fpath):
                            os.remove(fpath)
                    except Exception:
                        pass
        except Exception:
            pass

    cleanup_previous_outputs()

    final_plan, unpacked_items, bin_details, piece_area = run_optimizer(input_data)

    if final_plan:
        print_summary(final_plan, unpacked_items, bin_details, piece_area)
        save_cutting_plan_to_csv(final_plan)
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
            import os
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