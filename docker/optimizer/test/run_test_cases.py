#!/usr/bin/env python3
"""
Runner para ejecutar los casos de test predefinidos del optimizador.
Ejecutar con: python run_test_cases.py
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from cut_optimizer import run_optimizer
from test_cases import ALL_TEST_CASES
from test_utils import save_test_with_artifacts, cleanup_old_test_outputs
import json


def check_no_overlaps(plan):
    """Verifica que ninguna pieza se superponga con otra"""
    pieces = [p for p in plan if not p.get('Is_Waste', False)]
    waste_pieces = [p for p in plan if p.get('Is_Waste', False)]
    
    # Verificar que sobrantes no se superpongan con piezas
    for waste in waste_pieces:
        wx1, wy1 = waste['X_Coordinate'], waste['Y_Coordinate']
        wx2, wy2 = wx1 + waste['Packed_Width'], wy1 + waste['Packed_Height']
        
        for piece in pieces:
            if waste['Source_Plate_ID'] != piece['Source_Plate_ID']:
                continue
                
            px1, py1 = piece['X_Coordinate'], piece['Y_Coordinate']
            px2, py2 = px1 + piece['Packed_Width'], py1 + piece['Packed_Height']
            
            overlaps = not (wx2 <= px1 or wx1 >= px2 or wy2 <= py1 or wy1 >= py2)
            if overlaps:
                return False, f"Sobrante {waste['Piece_ID']} superpuesto con {piece['Piece_ID']}"
    
    return True, "OK"


def check_within_bounds(plan, bin_details):
    """Verifica que todas las piezas estén dentro de los límites de su plancha"""
    for piece in plan:
        plate_id = piece['Source_Plate_ID']
        if plate_id not in bin_details:
            return False, f"Plancha {plate_id} no encontrada en bin_details"
        
        plate = bin_details[plate_id]
        px = piece['X_Coordinate']
        py = piece['Y_Coordinate']
        pw = piece['Packed_Width']
        ph = piece['Packed_Height']
        
        if px < 0 or py < 0:
            return False, f"{piece['Piece_ID']} tiene coordenadas negativas"
        
        if px + pw > plate['width'] or py + ph > plate['height']:
            return False, f"{piece['Piece_ID']} excede límites de {plate_id}"
    
    return True, "OK"


def validate_case(case, save_artifacts=True):
    """Ejecuta un caso de test y valida los resultados"""
    print(f"\n{'='*70}")
    print(f"🧪 Test: {case['name']}")
    print(f"{'='*70}")
    
    # Ejecutar optimizador
    try:
        plan, unpacked, bin_details, total_area = run_optimizer(
            case['input'], 
            case['stock']
        )
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False
    
    # Guardar artifacts (PDFs + resumen + ZIP)
    if save_artifacts and plan:
        try:
            zip_file = save_test_with_artifacts(
                case['name'].replace(' ', '_').replace(':', ''),
                plan, 
                unpacked, 
                bin_details, 
                case.get('expected')
            )
        except Exception as e:
            print(f"⚠️  No se pudieron guardar artifacts: {e}")
    
    expected = case['expected']
    results = []
    
    # Validar piezas colocadas
    pieces_placed = len([p for p in plan if not p.get('Is_Waste', False)])
    if 'pieces_placed' in expected:
        passed = pieces_placed == expected['pieces_placed']
        results.append(('Piezas colocadas', pieces_placed, expected['pieces_placed'], passed))
    
    # Validar planchas usadas
    plates_used = len(set(p['Source_Plate_ID'] for p in plan if not p.get('Is_Waste', False)))
    if 'plates_used' in expected:
        passed = plates_used == expected['plates_used']
        results.append(('Planchas usadas', plates_used, expected['plates_used'], passed))
    
    if 'max_plates_used' in expected:
        passed = plates_used <= expected['max_plates_used']
        results.append(('Max planchas', plates_used, f"<= {expected['max_plates_used']}", passed))
    
    # Validar uso de sobrantes
    if 'should_use_scrap' in expected:
        used_scrap = any('Sobrante' in p['Source_Plate_ID'] 
                        for p in plan if not p.get('Is_Waste', False))
        passed = used_scrap == expected['should_use_scrap']
        results.append(('Usa sobrante', used_scrap, expected['should_use_scrap'], passed))
    
    # Validar tipo de plancha
    if 'plate_type' in expected:
        plate_types = set(p['Source_Plate_Type'] 
                         for p in plan if not p.get('Is_Waste', False))
        passed = expected['plate_type'] in plate_types
        results.append(('Tipo plancha', list(plate_types), expected['plate_type'], passed))
    
    # Validar plancha de emergencia
    if 'should_use_emergency' in expected:
        used_emergency = any('3600x2500' in p['Source_Plate_ID'] 
                            for p in plan if not p.get('Is_Waste', False))
        passed = used_emergency == expected['should_use_emergency']
        results.append(('Plancha emergencia', used_emergency, expected['should_use_emergency'], passed))
    
    # Validar calidad de sobrantes
    if 'max_unusable_waste_count' in expected:
        unusable = len([p for p in plan if p.get('Is_Unused', False)])
        passed = unusable <= expected['max_unusable_waste_count']
        results.append(('Sobrantes inútiles', unusable, f"<= {expected['max_unusable_waste_count']}", passed))
    
    if 'min_usable_waste_area' in expected:
        usable_waste = [p for p in plan 
                       if p.get('Is_Waste', False) and not p.get('Is_Unused', False)]
        total_usable_area = sum(w['Packed_Width'] * w['Packed_Height'] for w in usable_waste)
        passed = total_usable_area >= expected['min_usable_waste_area']
        results.append(('Área sobrantes útiles', total_usable_area, 
                       f">= {expected['min_usable_waste_area']}", passed))
    
    if 'min_avg_usable_size' in expected:
        usable_waste = [p for p in plan 
                       if p.get('Is_Waste', False) and not p.get('Is_Unused', False)]
        if usable_waste:
            avg_size = sum(w['Packed_Width'] * w['Packed_Height'] for w in usable_waste) / len(usable_waste)
            passed = avg_size >= expected['min_avg_usable_size']
            results.append(('Tamaño promedio sobrantes', f"{avg_size:.0f}", 
                           f">= {expected['min_avg_usable_size']}", passed))
    
    # Validar sin superposiciones
    if 'no_overlaps' in expected and expected['no_overlaps']:
        passed, msg = check_no_overlaps(plan)
        results.append(('Sin superposiciones', msg, 'OK', passed))
    
    # Validar dentro de límites
    if 'all_within_bounds' in expected and expected['all_within_bounds']:
        passed, msg = check_within_bounds(plan, bin_details)
        results.append(('Dentro de límites', msg, 'OK', passed))
    
    # Validar preservación de ref_number
    if 'should_preserve_ref_number' in expected:
        ref_found = any(
            bin_details.get(p['Source_Plate_ID'], {}).get('ref_number') == expected['should_preserve_ref_number']
            for p in plan if not p.get('Is_Waste', False)
        )
        passed = ref_found
        results.append(('Preserva ref_number', ref_found, True, passed))
    
    # Validar eficiencia
    if 'min_efficiency' in expected:
        pieces = [p for p in plan if not p.get('Is_Waste', False)]
        total_piece_area = sum(p['Packed_Width'] * p['Packed_Height'] for p in pieces)
        total_plate_area = sum(
            bin_details[plate_id]['width'] * bin_details[plate_id]['height']
            for plate_id in set(p['Source_Plate_ID'] for p in pieces)
        )
        efficiency = (total_piece_area / total_plate_area * 100) if total_plate_area > 0 else 0
        passed = efficiency >= expected['min_efficiency']
        results.append(('Eficiencia %', f"{efficiency:.1f}%", f">= {expected['min_efficiency']}%", passed))
    
    # Mostrar resultados
    print(f"\n📊 Resultados:")
    all_passed = True
    for criterion, actual, expected_val, passed in results:
        status = "✅" if passed else "❌"
        print(f"  {status} {criterion}: {actual} (esperado: {expected_val})")
        if not passed:
            all_passed = False
    
    # Resumen de desperdicio
    waste_pieces = [p for p in plan if p.get('Is_Waste', False)]
    usable_waste = [p for p in waste_pieces if not p.get('Is_Unused', False)]
    unusable_waste = [p for p in waste_pieces if p.get('Is_Unused', False)]
    
    print(f"\n📦 Resumen del plan:")
    print(f"  • Piezas cortadas: {pieces_placed}")
    print(f"  • Planchas usadas: {plates_used}")
    print(f"  • Sobrantes útiles: {len(usable_waste)}")
    print(f"  • Sobrantes inútiles: {len(unusable_waste)}")
    
    return all_passed


def main():
    """Ejecuta todos los casos de test"""
    print("🚀 EJECUTANDO CASOS DE TEST DEL OPTIMIZADOR")
    print("=" * 70)
    print("📦 Los resultados se guardarán en archivos ZIP individuales")
    print("=" * 70)
    
    # Limpiar outputs antiguos (mantener solo los últimos 10)
    cleanup_old_test_outputs(keep_last_n=10)
    
    passed = 0
    failed = 0
    zip_files = []
    
    for i, case in enumerate(ALL_TEST_CASES, 1):
        print(f"\n[{i}/{len(ALL_TEST_CASES)}]")
        if validate_case(case, save_artifacts=True):
            passed += 1
        else:
            failed += 1
    
    # Resumen final
    print(f"\n\n{'='*70}")
    print("📈 RESUMEN FINAL")
    print(f"{'='*70}")
    print(f"✅ Tests exitosos: {passed}/{len(ALL_TEST_CASES)}")
    print(f"❌ Tests fallidos: {failed}/{len(ALL_TEST_CASES)}")
    print(f"\n📁 Archivos guardados en: test_outputs/")
    print(f"   Cada test tiene su propio ZIP con PDFs y resumen")
    print(f"{'='*70}\n")
    
    return failed == 0


if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)
