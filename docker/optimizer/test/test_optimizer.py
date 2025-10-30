#!/usr/bin/env python3
"""
Suite de tests para el optimizador de corte de vidrio.
Ejecutar con: python test_optimizer.py
"""

import sys
import os
import json
import unittest
from io import StringIO

# Agregar el directorio padre al path para importar los módulos
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from cut_optimizer import run_optimizer, merge_adjacent_rects, _try_guillotine_variants
from test_utils import save_test_with_artifacts

# Variable global para controlar si se guardan artifacts
SAVE_ARTIFACTS = os.environ.get('SAVE_TEST_ARTIFACTS', 'false').lower() == 'true'


def maybe_save_artifacts(test_name, plan, unpacked, bin_details):
    """Guarda artifacts solo si SAVE_ARTIFACTS está habilitado"""
    if SAVE_ARTIFACTS and plan:
        try:
            save_test_with_artifacts(test_name, plan, unpacked, bin_details)
        except Exception as e:
            print(f"⚠️  No se pudieron guardar artifacts para {test_name}: {e}")


class TestMergeAdjacentRects(unittest.TestCase):
    """Tests para la función de fusión de rectángulos adyacentes"""
    
    def test_merge_vertical_adjacent(self):
        """Debe fusionar rectángulos verticalmente adyacentes"""
        rects = [
            (0, 0, 100, 200),    # Arriba
            (0, 200, 100, 300)   # Abajo, adyacente
        ]
        result = merge_adjacent_rects(rects)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], (0, 0, 100, 500))
    
    def test_merge_horizontal_adjacent(self):
        """Debe fusionar rectángulos horizontalmente adyacentes"""
        rects = [
            (0, 0, 200, 100),    # Izquierda
            (200, 0, 300, 100)   # Derecha, adyacente
        ]
        result = merge_adjacent_rects(rects)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], (0, 0, 500, 100))
    
    def test_no_merge_non_adjacent(self):
        """No debe fusionar rectángulos no adyacentes"""
        rects = [
            (0, 0, 100, 100),
            (200, 200, 100, 100)  # Separado
        ]
        result = merge_adjacent_rects(rects)
        self.assertEqual(len(result), 2)
    
    def test_empty_list(self):
        """Debe manejar lista vacía"""
        result = merge_adjacent_rects([])
        self.assertEqual(result, [])


class TestBasicPacking(unittest.TestCase):
    """Tests básicos de empaquetado"""
    
    def test_single_piece_fits_in_scrap(self):
        """Una pieza pequeña debe caber en un sobrante grande"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 200, 'height': 200, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 1000, 'height': 1000, 
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ],
            'glassplates': []
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Guardar artifacts si está habilitado
        maybe_save_artifacts('test_single_piece_fits_in_scrap', plan, unpacked, bin_details)
        
        # Verificar que se empaquetó correctamente
        self.assertGreater(len(plan), 0, "Debe generar un plan de corte")
        self.assertEqual(len(unpacked), 0, "No deben quedar piezas sin empaquetar")
        
        # Verificar que se usó el sobrante
        piece = [p for p in plan if p['Piece_ID'] == 'v1'][0]
        self.assertIn('Sobrante', piece['Source_Plate_ID'])
    
    def test_piece_fits_in_new_plate(self):
        """Una pieza debe caber en una plancha nueva si no hay sobrantes"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 400, 'height': 400, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [],
            'glassplates': [
                {'id': 'plate1', 'width': 1000, 'height': 1000, 'quantity': 1,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ]
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        self.assertGreater(len(plan), 0)
        self.assertEqual(len(unpacked), 0)
        
        # Verificar que se usó una plancha nueva
        piece = [p for p in plan if p['Piece_ID'] == 'v1'][0]
        self.assertIn('Plancha', piece['Source_Plate_ID'])


class TestWasteDetection(unittest.TestCase):
    """Tests para detección de sobrantes"""
    
    def test_generates_waste_rectangles(self):
        """Debe detectar sobrantes después de colocar piezas"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 400, 'height': 400, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 1000, 'height': 1000,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ],
            'glassplates': []
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Debe haber piezas marcadas como sobrantes
        waste_pieces = [p for p in plan if p.get('Is_Waste', False)]
        self.assertGreater(len(waste_pieces), 0, "Debe generar sobrantes")
        
        # Verificar que los sobrantes útiles son >= 200mm
        usable_waste = [w for w in waste_pieces 
                       if not w.get('Is_Unused', False)]
        for waste in usable_waste:
            self.assertGreaterEqual(waste['Packed_Width'], 200)
            self.assertGreaterEqual(waste['Packed_Height'], 200)
    
    def test_no_overlapping_waste(self):
        """Los sobrantes no deben superponerse con las piezas"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 150, 'height': 139, 'quantity': 1},
                {'id': 'v2', 'width': 400, 'height': 400, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 1000, 'height': 1000,
                 'glass_type': 'LAM', 'thickness': '3+3', 'color': 'INC'}
            ],
            'glassplates': []
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Obtener todas las piezas reales (no sobrantes)
        pieces = [p for p in plan if not p.get('Is_Waste', False)]
        waste_pieces = [p for p in plan if p.get('Is_Waste', False)]
        
        # Verificar que ningún sobrante se superpone con las piezas
        for waste in waste_pieces:
            wx1, wy1 = waste['X_Coordinate'], waste['Y_Coordinate']
            wx2, wy2 = wx1 + waste['Packed_Width'], wy1 + waste['Packed_Height']
            
            for piece in pieces:
                px1, py1 = piece['X_Coordinate'], piece['Y_Coordinate']
                px2, py2 = px1 + piece['Packed_Width'], py1 + piece['Packed_Height']
                
                # Verificar que NO hay superposición
                overlaps = not (wx2 <= px1 or wx1 >= px2 or wy2 <= py1 or wy1 >= py2)
                self.assertFalse(overlaps, 
                    f"Sobrante {waste['Piece_ID']} se superpone con pieza {piece['Piece_ID']}")


class TestMultiStageOptimization(unittest.TestCase):
    """Tests para la optimización multi-etapa"""
    
    def test_etapa1_uses_scraps_first(self):
        """ETAPA1 debe intentar usar sobrantes primero"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 200, 'height': 200, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 500, 'height': 500,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ],
            'glassplates': [
                {'id': 'plate1', 'width': 2000, 'height': 2000, 'quantity': 1,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ]
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Verificar que se usó el sobrante
        piece = [p for p in plan if p['Piece_ID'] == 'v1'][0]
        self.assertIn('Sobrante', piece['Source_Plate_ID'])
        self.assertEqual(piece['Source_Plate_Type'], 'Leftover')
    
    def test_etapa2_uses_new_plates(self):
        """ETAPA2 debe usar planchas nuevas si no caben en sobrantes"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 600, 'height': 600, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 500, 'height': 500,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ],
            'glassplates': [
                {'id': 'plate1', 'width': 2000, 'height': 2000, 'quantity': 1,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ]
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Verificar que se usó una plancha nueva
        piece = [p for p in plan if p['Piece_ID'] == 'v1'][0]
        self.assertIn('Plancha', piece['Source_Plate_ID'])
        self.assertEqual(piece['Source_Plate_Type'], 'New')


class TestRotationHandling(unittest.TestCase):
    """Tests para manejo de rotación"""
    
    def test_rotation_flag_correct(self):
        """El flag Is_Rotated debe ser correcto"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 300, 'height': 500, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [],
            'glassplates': [
                {'id': 'plate1', 'width': 1000, 'height': 1000, 'quantity': 1,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ]
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        piece = [p for p in plan if p['Piece_ID'] == 'v1'][0]
        
        # Verificar que si está rotada, las dimensiones están intercambiadas
        if piece['Is_Rotated']:
            self.assertEqual(piece['Packed_Width'], 500)
            self.assertEqual(piece['Packed_Height'], 300)
        else:
            self.assertEqual(piece['Packed_Width'], 300)
            self.assertEqual(piece['Packed_Height'], 500)


class TestEdgeCases(unittest.TestCase):
    """Tests para casos extremos"""
    
    def test_empty_pieces_list(self):
        """Debe manejar lista vacía de piezas"""
        input_data = {'pieces_to_cut': []}
        stock_data = {
            'scraps': [],
            'glassplates': [
                {'id': 'plate1', 'width': 1000, 'height': 1000, 'quantity': 1,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ]
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        self.assertEqual(len(plan), 0)
        self.assertEqual(len(unpacked), 0)
    
    def test_piece_larger_than_stock(self):
        """Debe usar plancha de emergencia si la pieza no cabe"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 3000, 'height': 3000, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [],
            'glassplates': [
                {'id': 'plate1', 'width': 1000, 'height': 1000, 'quantity': 1,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ]
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Debe haber usado plancha de emergencia 3600x2500
        if len(plan) > 0:
            piece = [p for p in plan if p['Piece_ID'] == 'v1'][0]
            self.assertIn('3600x2500', piece['Source_Plate_ID'])


class TestQualityMetrics(unittest.TestCase):
    """Tests para métricas de calidad de optimización"""
    
    def test_prefers_fewer_plates(self):
        """Debe preferir usar menos planchas"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 200, 'height': 200, 'quantity': 1},
                {'id': 'v2', 'width': 200, 'height': 200, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 1000, 'height': 1000,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ],
            'glassplates': []
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Verificar que ambas piezas están en la misma plancha
        piece1 = [p for p in plan if p['Piece_ID'] == 'v1'][0]
        piece2 = [p for p in plan if p['Piece_ID'] == 'v2'][0]
        self.assertEqual(piece1['Source_Plate_ID'], piece2['Source_Plate_ID'])
    
    def test_prefers_larger_waste_rectangles(self):
        """Debe preferir soluciones con sobrantes grandes sobre muchos pequeños"""
        input_data = {
            'pieces_to_cut': [
                {'id': 'v1', 'width': 400, 'height': 400, 'quantity': 1}
            ]
        }
        stock_data = {
            'scraps': [
                {'id': 'scrap1', 'width': 1000, 'height': 1000,
                 'glass_type': 'FLO', 'thickness': '4mm', 'color': 'INC'}
            ],
            'glassplates': []
        }
        
        plan, unpacked, bin_details, _ = run_optimizer(input_data, stock_data)
        
        # Obtener sobrantes útiles (no inútiles)
        usable_waste = [p for p in plan 
                       if p.get('Is_Waste', False) and not p.get('Is_Unused', False)]
        
        if len(usable_waste) > 0:
            # Calcular área promedio
            avg_area = sum(w['Packed_Width'] * w['Packed_Height'] for w in usable_waste) / len(usable_waste)
            # Los sobrantes deberían ser razonablemente grandes
            self.assertGreater(avg_area, 100000, "Sobrantes deberían ser grandes")


def run_test_suite():
    """Ejecuta toda la suite de tests con reporte detallado"""
    print("=" * 70)
    print("🧪 SUITE DE TESTS DEL OPTIMIZADOR DE CORTE")
    print("=" * 70)
    print()
    
    # Crear suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Agregar todos los tests
    suite.addTests(loader.loadTestsFromTestCase(TestMergeAdjacentRects))
    suite.addTests(loader.loadTestsFromTestCase(TestBasicPacking))
    suite.addTests(loader.loadTestsFromTestCase(TestWasteDetection))
    suite.addTests(loader.loadTestsFromTestCase(TestMultiStageOptimization))
    suite.addTests(loader.loadTestsFromTestCase(TestRotationHandling))
    suite.addTests(loader.loadTestsFromTestCase(TestEdgeCases))
    suite.addTests(loader.loadTestsFromTestCase(TestQualityMetrics))
    
    # Ejecutar con verbosity
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Resumen final
    print()
    print("=" * 70)
    print("📊 RESUMEN DE TESTS")
    print("=" * 70)
    print(f"✅ Tests exitosos: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"❌ Tests fallidos: {len(result.failures)}")
    print(f"💥 Errores: {len(result.errors)}")
    print(f"⏭️  Tests omitidos: {len(result.skipped)}")
    print("=" * 70)
    
    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_test_suite()
    sys.exit(0 if success else 1)
