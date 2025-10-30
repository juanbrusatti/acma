#!/usr/bin/env python3
"""
Utilidades para guardar y organizar los resultados visuales de los tests.
"""

import os
import shutil
import zipfile
from datetime import datetime


def create_test_output_dir(test_name):
    """
    Crea un directorio para guardar los outputs de un test específico.
    Retorna la ruta al directorio creado.
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    base_dir = "test_outputs"
    test_dir = os.path.join(base_dir, f"{test_name}_{timestamp}")
    
    os.makedirs(test_dir, exist_ok=True)
    return test_dir


def save_test_artifacts(test_name, plan, bin_details):
    """
    Guarda los PDFs generados por un test en una carpeta específica.
    Retorna la ruta al directorio creado.
    """
    from visualize import visualize_packing
    
    # Crear directorio para este test
    test_dir = create_test_output_dir(test_name)
    output_folder = os.path.join(test_dir, "pdfs")
    os.makedirs(output_folder, exist_ok=True)
    
    # Generar visualizaciones
    used_bins = sorted(set(p['Source_Plate_ID'] for p in plan))
    for bin_id in used_bins:
        pieces_for_bin = [p for p in plan if p['Source_Plate_ID'] == bin_id]
        try:
            visualize_packing(pieces_for_bin, {bin_id: bin_details[bin_id]}, output_folder=output_folder)
        except Exception as e:
            print(f"Warning: No se pudo generar PDF para {bin_id}: {e}")
    
    return test_dir


def create_test_summary(test_dir, test_name, plan, unpacked, bin_details, expected):
    """
    Crea un archivo de resumen con información del test.
    """
    summary_file = os.path.join(test_dir, "RESUMEN.txt")
    
    with open(summary_file, 'w', encoding='utf-8') as f:
        f.write(f"{'='*70}\n")
        f.write(f"RESUMEN DEL TEST: {test_name}\n")
        f.write(f"{'='*70}\n\n")
        
        # Información básica
        pieces = [p for p in plan if not p.get('Is_Waste', False)]
        waste_pieces = [p for p in plan if p.get('Is_Waste', False)]
        usable_waste = [p for p in waste_pieces if not p.get('Is_Unused', False)]
        unusable_waste = [p for p in waste_pieces if p.get('Is_Unused', False)]
        plates_used = len(set(p['Source_Plate_ID'] for p in pieces))
        
        f.write(f"📊 ESTADÍSTICAS:\n")
        f.write(f"  • Piezas cortadas: {len(pieces)}\n")
        f.write(f"  • Piezas sin colocar: {len(unpacked)}\n")
        f.write(f"  • Planchas usadas: {plates_used}\n")
        f.write(f"  • Sobrantes útiles: {len(usable_waste)}\n")
        f.write(f"  • Sobrantes inútiles: {len(unusable_waste)}\n\n")
        
        # Detalles de planchas
        f.write(f"🔨 PLANCHAS USADAS:\n")
        for plate_id in sorted(set(p['Source_Plate_ID'] for p in pieces)):
            plate = bin_details[plate_id]
            pieces_in_plate = [p for p in pieces if p['Source_Plate_ID'] == plate_id]
            f.write(f"  • {plate_id}: {plate['width']}x{plate['height']}\n")
            f.write(f"    - Tipo: {plate.get('type', 'Unknown')}\n")
            f.write(f"    - Piezas: {len(pieces_in_plate)}\n")
            if plate.get('ref_number'):
                f.write(f"    - Ref: {plate['ref_number']}\n")
        
        f.write(f"\n")
        
        # Sobrantes útiles
        if usable_waste:
            f.write(f"♻️  SOBRANTES ÚTILES (reutilizables):\n")
            for i, waste in enumerate(usable_waste, 1):
                w = waste['Packed_Width']
                h = waste['Packed_Height']
                area = w * h
                f.write(f"  {i}. {w}x{h} mm (Área: {area:,} mm²)\n")
            f.write(f"\n")
        
        # Sobrantes inútiles
        if unusable_waste:
            f.write(f"🗑️  SOBRANTES INÚTILES (< 200mm):\n")
            for i, waste in enumerate(unusable_waste, 1):
                w = waste['Packed_Width']
                h = waste['Packed_Height']
                f.write(f"  {i}. {w}x{h} mm\n")
            f.write(f"\n")
        
        # Piezas sin colocar
        if unpacked:
            f.write(f"❌ PIEZAS SIN COLOCAR:\n")
            for item in unpacked:
                f.write(f"  • {item['id']}: {item['quantity_unpacked']} unidades\n")
            f.write(f"\n")
        
        # Criterios esperados
        if expected:
            f.write(f"✅ CRITERIOS DE VALIDACIÓN:\n")
            for key, value in expected.items():
                f.write(f"  • {key}: {value}\n")
        
        f.write(f"\n{'='*70}\n")


def create_zip_archive(test_dir, test_name):
    """
    Crea un archivo ZIP con todos los PDFs y el resumen del test.
    """
    zip_filename = f"{test_dir}.zip"
    
    with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(test_dir):
            for file in files:
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, os.path.dirname(test_dir))
                zipf.write(file_path, arcname)
    
    return zip_filename


def cleanup_old_test_outputs(keep_last_n=5):
    """
    Limpia outputs antiguos, manteniendo solo los últimos N.
    """
    base_dir = "test_outputs"
    if not os.path.exists(base_dir):
        return
    
    # Obtener todos los subdirectorios con timestamp
    test_dirs = []
    for dirname in os.listdir(base_dir):
        dir_path = os.path.join(base_dir, dirname)
        if os.path.isdir(dir_path):
            test_dirs.append((dirname, os.path.getctime(dir_path)))
    
    # Ordenar por fecha de creación (más reciente primero)
    test_dirs.sort(key=lambda x: x[1], reverse=True)
    
    # Eliminar los más antiguos
    for dirname, _ in test_dirs[keep_last_n:]:
        dir_path = os.path.join(base_dir, dirname)
        shutil.rmtree(dir_path, ignore_errors=True)
        print(f"🧹 Limpiado: {dirname}")


def save_test_with_artifacts(test_name, plan, unpacked, bin_details, expected=None):
    """
    Función todo-en-uno para guardar artifacts de un test.
    Retorna la ruta al ZIP generado.
    """
    # Guardar PDFs
    test_dir = save_test_artifacts(test_name, plan, bin_details)
    
    # Crear resumen
    create_test_summary(test_dir, test_name, plan, unpacked, bin_details, expected)
    
    # Crear ZIP
    zip_file = create_zip_archive(test_dir, test_name)
    
    print(f"📦 Artifacts guardados: {zip_file}")
    
    return zip_file
