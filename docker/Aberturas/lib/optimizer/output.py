import os
import csv

def save_cutting_plan_to_csv(cutting_plan, output_dir='output_plan'):
    """
    Guarda el plan de corte detallado en un archivo CSV.
    """
    if not cutting_plan:
        return

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    filepath = os.path.join(output_dir, 'cutting_plan.csv')
    with open(filepath, 'w', newline='') as csvfile:
        fieldnames = cutting_plan[0].keys()
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(cutting_plan)
    print(f"✅ Plan de corte detallado guardado en: '{filepath}'")


def print_summary(plan, unpacked, bin_map, total_piece_area):
    print("\n" + "="*40)
    print("📊 RESUMEN DE LA OPTIMIZACIÓN")
    print("="*40)

    if not plan:
        print("❌ No se pudo empaquetar ninguna pieza.")
        return

    used_bins = sorted(list(set(p['Source_Plate_ID'] for p in plan)))
    used_leftovers = [b for b in used_bins if bin_map[b]['type'] == 'Leftover']
    used_new_plates = [b for b in used_bins if bin_map[b]['type'] == 'New']

    print(f"Placas de Sobrante Utilizadas ({len(used_leftovers)}): {', '.join(used_leftovers) if used_leftovers else 'Ninguna'}")
    print(f"Placas Nuevas Utilizadas ({len(used_new_plates)}): {len(used_new_plates)}")

    total_used_area = 0
    for bin_id in used_bins:
        bin_info = bin_map[bin_id]
        # Asegurarse que width y height son números
        width = bin_info['width']
        height = bin_info['height']
        total_used_area += width * height

    if total_used_area > 0:
        utilization = (total_piece_area / total_used_area) * 100
        print(f"Área Total de Piezas a Cortar: {total_piece_area:.2f} unidades²")
        print(f"Área Total de Placas Utilizadas: {total_used_area:.2f} unidades²")
        print(f"Eficiencia/Utilización del Material: {utilization:.2f}%")

    if unpacked:
        print("\n--- ⚠️ Piezas No Empaquetadas ---")
        for item in unpacked:
            print(f"  - ID: {item['id']}, Cantidad Faltante: {item['quantity_unpacked']}")
    else:
        print("\n--- ✅ Todas las piezas fueron empaquetadas exitosamente ---")
    print("="*40)
