"""
Casos de test predefinidos para validar el optimizador.
Cada caso tiene datos de entrada y criterios de éxito esperados.
"""

# Caso 1: Optimización simple - una pieza en un sobrante
CASE_SIMPLE_SCRAP = {
    "name": "Simple: 1 pieza pequeña en sobrante grande",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 200, "height": 200, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 1000, "height": 1000,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF001"}
        ],
        "glassplates": []
    },
    "expected": {
        "pieces_placed": 1,
        "plates_used": 1,
        "should_use_scrap": True,
        "max_waste_percent": 90  # Máximo 90% de desperdicio aceptable
    }
}

# Caso 2: Múltiples piezas en una plancha
CASE_MULTIPLE_PIECES = {
    "name": "Múltiples piezas en una plancha",
    "input": {
        "pieces_to_cut": [
            *[
                {"id": "v1", "width": 150, "height": 139, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
                for _ in range(9)
            ],
            {"id": "v2", "width": 400, "height": 400, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 1000, "height": 1000,
             "glass_type": "LAM", "thickness": "3+3", "color": "INC", "ref_number": "REF002"}
        ],
        "glassplates": []
    },
    "expected": {
        "pieces_placed": 10,
        "plates_used": 1,
        "should_use_scrap": True,
        "min_usable_waste_area": 200000  # Debe generar al menos un sobrante útil grande
    }
}

# Caso 3: Etapa 2 - usar planchas nuevas
CASE_NEW_PLATE = {
    "name": "Etapa 2: Pieza grande necesita plancha nueva",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 600, "height": 600, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 500, "height": 500,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 1,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 1,
        "plates_used": 1,
        "should_use_scrap": False,
        "plate_type": "New"
    }
}

# Caso 4: Rotación óptima
CASE_ROTATION = {
    "name": "Rotación: Aprovechar mejor el espacio",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 300, "height": 1500, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"},
            {"id": "v2", "width": 300, "height": 1500, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 1,
             "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 2,
        "plates_used": 1,  # Deben caber ambas en una plancha (posiblemente rotadas)
        "allow_rotation": True
    }
}

# Caso 5: Optimización de sobrantes
CASE_WASTE_QUALITY = {
    "name": "Calidad de sobrantes: Preferir pocos sobrantes grandes",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 400, "height": 400, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 1000, "height": 1000,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF003"}
        ],
        "glassplates": []
    },
    "expected": {
        "pieces_placed": 1,
        "plates_used": 1,
        "max_unusable_waste_count": 3,  # Máximo 3 sobrantes inútiles
        "min_avg_usable_size": 200000   # Sobrantes útiles deben ser grandes
    }
}

# Caso 6: Plancha de emergencia
CASE_EMERGENCY_PLATE = {
    "name": "Plancha de emergencia: Pieza muy grande",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 3000, "height": 2000, "quantity": 1, "glass_type": "FLO", "thickness": "8mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 1,
             "glass_type": "FLO", "thickness": "8mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 1,
        "plates_used": 1,
        "should_use_emergency": True  # Debe usar plancha 3600x2500
    }
}

# Caso 7: Prioridad de menos planchas
CASE_FEWER_PLATES_PRIORITY = {
    "name": "Prioridad: Usar menos planchas",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 200, "height": 200, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"},
            {"id": "v2", "width": 200, "height": 200, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 1000, "height": 1000,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"},
            {"id": "scrap2", "width": 500, "height": 500,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ],
        "glassplates": []
    },
    "expected": {
        "pieces_placed": 2,
        "plates_used": 1,  # Ambas piezas deben ir en scrap1 (más grande)
        "should_use_scrap": True
    }
}

# Caso 8: Stress test - muchas piezas pequeñas
CASE_MANY_SMALL_PIECES = {
    "name": "Stress test: 50 piezas pequeñas",
    "input": {
        "pieces_to_cut": [
            {"id": f"v{i}", "width": 100, "height": 100, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
            for i in range(1, 51)
        ]
    },
    "stock": {
        "scraps": [],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 5,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 50,
        "max_plates_used": 3,  # No debería usar más de 3 planchas
        "min_efficiency": 70  # Al menos 70% de eficiencia
    }
}

# Caso 9: No hay superposición de sobrantes
CASE_NO_OVERLAP = {
    "name": "Validación: Sin superposición de sobrantes",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 150, "height": 139, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"},
            {"id": "v2", "width": 400, "height": 400, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"},
            *[
                {"id": "v3", "width": 99, "height": 99, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
                for _ in range(9)
            ]
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 1000, "height": 1000,
             "glass_type": "LAM", "thickness": "3+3", "color": "INC", "ref_number": "Bachigay1090"}
        ],
        "glassplates": []
    },
    "expected": {
        "pieces_placed": 11,
        "no_overlaps": True,  # Ningún sobrante debe superponerse con piezas
        "all_within_bounds": True  # Todo debe estar dentro de los límites de la plancha
    }
}

# Caso 10: Preservación de ref_number
CASE_REF_NUMBER_PRESERVATION = {
    "name": "Trazabilidad: Preservar ref_number",
    "input": {
        "pieces_to_cut": [
            {"id": "v1", "width": 200, "height": 200, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "stock": {
        "scraps": [
            {"id": "scrap1", "width": 1000, "height": 1000,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC", 
             "ref_number": "SCRAP-2024-001"}
        ],
        "glassplates": []
    },
    "expected": {
        "pieces_placed": 1,
        "should_preserve_ref_number": "SCRAP-2024-001"
    }
}

# ==================== CASOS GRANDES Y COMPLEJOS ====================

# Caso 11: Producción Alta - 100 piezas variadas con mucho stock
CASE_HIGH_PRODUCTION = {
    "name": "Producción Alta: 100 piezas variadas con 20 sobrantes",
    "input": {
        "pieces_to_cut": [
            # Piezas grandes
            *[
                {"id": "v1", "width": 800, "height": 1200, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(5)
            ],
            *[
                {"id": "v2", "width": 1000, "height": 1000, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(3)
            ],
            *[
                {"id": "v3", "width": 900, "height": 1500, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(4)
            ],
            # Piezas medianas
            *[
                {"id": "v4", "width": 500, "height": 600, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(15)
            ],
            *[
                {"id": "v5", "width": 400, "height": 700, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(12)
            ],
            *[
                {"id": "v6", "width": 600, "height": 500, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(10)
            ],
            # Piezas pequeñas
            *[
                {"id": "v7", "width": 250, "height": 300, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(20)
            ],
            *[
                {"id": "v8", "width": 200, "height": 400, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(18)
            ],
            *[
                {"id": "v9", "width": 300, "height": 350, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(13)
            ]
        ]
    },
    "stock": {
        "scraps": [
            # Sobrantes grandes (ideales para piezas grandes)
            {"id": "scrap1", "width": 1800, "height": 1800, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-L001"},
            {"id": "scrap2", "width": 1600, "height": 1900, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-L002"},
            {"id": "scrap3", "width": 1700, "height": 1700, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-L003"},
            {"id": "scrap4", "width": 1500, "height": 2000, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-L004"},
            # Sobrantes medianos
            {"id": "scrap5", "width": 1200, "height": 1400, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-M001"},
            {"id": "scrap6", "width": 1300, "height": 1300, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-M002"},
            {"id": "scrap7", "width": 1100, "height": 1500, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-M003"},
            {"id": "scrap8", "width": 1400, "height": 1200, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-M004"},
            {"id": "scrap9", "width": 1000, "height": 1600, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-M005"},
            {"id": "scrap10", "width": 1250, "height": 1350, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-M006"},
            # Sobrantes pequeños/medianos (para piezas pequeñas)
            {"id": "scrap11", "width": 800, "height": 1000, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S001"},
            {"id": "scrap12", "width": 900, "height": 900, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S002"},
            {"id": "scrap13", "width": 750, "height": 1100, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S003"},
            {"id": "scrap14", "width": 850, "height": 850, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S004"},
            {"id": "scrap15", "width": 700, "height": 1200, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S005"},
            {"id": "scrap16", "width": 950, "height": 800, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S006"},
            {"id": "scrap17", "width": 600, "height": 1000, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S007"},
            {"id": "scrap18", "width": 800, "height": 700, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S008"},
            {"id": "scrap19", "width": 650, "height": 950, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S009"},
            {"id": "scrap20", "width": 900, "height": 650, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "REF-S010"}
        ],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 10,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 100,
        "max_plates_used": 15,  # Con buenos sobrantes, no debería necesitar muchas planchas nuevas
        "min_efficiency": 65,
        "should_use_scrap": True
    }
}

# Caso 12: Multi-tipo - Diferentes tipos de vidrio
CASE_MULTI_GLASS_TYPES = {
    "name": "Multi-tipo: 80 piezas con 4 tipos de vidrio y 15 sobrantes",
    "input": {
        "pieces_to_cut": [
            # FLO 4mm
            *[
                {"id": "f1", "width": 700, "height": 900, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(8)
            ],
            *[
                {"id": "f2", "width": 500, "height": 600, "quantity": 1, "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(12)
            ],
            # LAM 3+3
            *[
                {"id": "l1", "width": 800, "height": 1000, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
                for _ in range(6)
            ],
            *[
                {"id": "l2", "width": 400, "height": 500, "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
                for _ in range(15)
            ],
            # FLO 6mm
            *[
                {"id": "f6_1", "width": 900, "height": 1200, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(5)
            ],
            *[
                {"id": "f6_2", "width": 600, "height": 800, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(10)
            ],
            # LAM 4+4
            *[
                {"id": "l4_1", "width": 1000, "height": 1000, "quantity": 1, "glass_type": "LAM", "thickness": "4+4", "color": "INC"}
                for _ in range(4)
            ],
            *[
                {"id": "l4_2", "width": 300, "height": 400, "quantity": 1, "glass_type": "LAM", "thickness": "4+4", "color": "INC"}
                for _ in range(20)
            ]
        ]
    },
    "stock": {
        "scraps": [
            # Sobrantes FLO 4mm
            {"id": "s_f4_1", "width": 1600, "height": 1800, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "F4-001"},
            {"id": "s_f4_2", "width": 1400, "height": 1500, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "F4-002"},
            {"id": "s_f4_3", "width": 1200, "height": 1700, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "F4-003"},
            {"id": "s_f4_4", "width": 1000, "height": 1200, "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": "F4-004"},
            # Sobrantes LAM 3+3
            {"id": "s_l33_1", "width": 1700, "height": 1600, "glass_type": "LAM", "thickness": "3+3", "color": "INC", "ref_number": "L33-001"},
            {"id": "s_l33_2", "width": 1300, "height": 1400, "glass_type": "LAM", "thickness": "3+3", "color": "INC", "ref_number": "L33-002"},
            {"id": "s_l33_3", "width": 1100, "height": 1300, "glass_type": "LAM", "thickness": "3+3", "color": "INC", "ref_number": "L33-003"},
            # Sobrantes FLO 6mm
            {"id": "s_f6_1", "width": 1800, "height": 1900, "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": "F6-001"},
            {"id": "s_f6_2", "width": 1500, "height": 1600, "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": "F6-002"},
            {"id": "s_f6_3", "width": 1200, "height": 1500, "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": "F6-003"},
            {"id": "s_f6_4", "width": 900, "height": 1400, "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": "F6-004"},
            # Sobrantes LAM 4+4
            {"id": "s_l44_1", "width": 1600, "height": 1700, "glass_type": "LAM", "thickness": "4+4", "color": "INC", "ref_number": "L44-001"},
            {"id": "s_l44_2", "width": 1400, "height": 1300, "glass_type": "LAM", "thickness": "4+4", "color": "INC", "ref_number": "L44-002"},
            {"id": "s_l44_3", "width": 1200, "height": 1200, "glass_type": "LAM", "thickness": "4+4", "color": "INC", "ref_number": "L44-003"},
            {"id": "s_l44_4", "width": 800, "height": 1000, "glass_type": "LAM", "thickness": "4+4", "color": "INC", "ref_number": "L44-004"}
        ],
        "glassplates": [
            {"id": "plate_f4", "width": 2000, "height": 2000, "quantity": 5, "glass_type": "FLO", "thickness": "4mm", "color": "INC"},
            {"id": "plate_l33", "width": 2000, "height": 2000, "quantity": 5, "glass_type": "LAM", "thickness": "3+3", "color": "INC"},
            {"id": "plate_f6", "width": 2000, "height": 2000, "quantity": 5, "glass_type": "FLO", "thickness": "6mm", "color": "INC"},
            {"id": "plate_l44", "width": 2000, "height": 2000, "quantity": 5, "glass_type": "LAM", "thickness": "4+4", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 80,
        "max_plates_used": 12,
        "min_efficiency": 60,
        "should_use_scrap": True
    }
}

# Caso 13: Ventanas Estándar - Pedido real de obra
CASE_STANDARD_WINDOWS = {
    "name": "Pedido Real: 120 piezas de ventanas estándar con 25 sobrantes",
    "input": {
        "pieces_to_cut": [
            *[
                {"id": "vent_120x150", "width": 1200, "height": 1500, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(30)
            ],
            *[
                {"id": "vent_100x120", "width": 1000, "height": 1200, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(25)
            ],
            *[
                {"id": "vent_80x100", "width": 800, "height": 1000, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(20)
            ],
            *[
                {"id": "puerta_1", "width": 900, "height": 2000, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(8)
            ],
            *[
                {"id": "puerta_2", "width": 800, "height": 2100, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(7)
            ],
            *[
                {"id": "vent_60x80", "width": 600, "height": 800, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(15)
            ],
            *[
                {"id": "vent_50x60", "width": 500, "height": 600, "quantity": 1,
                 "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
                for _ in range(15)
            ]
        ]
    },
    "stock": {
        "scraps": [
            # Mix de sobrantes grandes y medianos
            {"id": f"scrap_obra_{i}", "width": 1800 - (i * 50), "height": 1900 - (i * 40),
             "glass_type": "FLO", "thickness": "4mm", "color": "INC", "ref_number": f"OBRA-{i:03d}"}
            for i in range(1, 26)  # 25 sobrantes de diferentes tamaños
        ],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 20,
             "glass_type": "FLO", "thickness": "4mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 120,
        "max_plates_used": 30,
        "min_efficiency": 65,
        "should_use_scrap": True
    }
}

# Caso 14: Stock Masivo - Muchos sobrantes disponibles
CASE_MASSIVE_STOCK = {
    "name": "Stock Masivo: 60 piezas con 40 sobrantes disponibles",
    "input": {
        "pieces_to_cut": [
            {"id": f"pieza_{i}", "width": 300 + (i * 20), "height": 400 + (i * 15), "quantity": 1, "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
            for i in range(1, 61)  # 60 piezas de tamaños progresivos
        ]
    },
    "stock": {
        "scraps": [
            # 40 sobrantes de diferentes tamaños
            {"id": f"stock_{i}", 
             "width": 800 + (i * 30), 
             "height": 900 + (i * 25),
             "glass_type": "LAM", "thickness": "3+3", "color": "INC", 
             "ref_number": f"STOCK-{i:03d}"}
            for i in range(1, 41)
        ],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 15,
             "glass_type": "LAM", "thickness": "3+3", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 60,
        "max_plates_used": 20,
        "min_efficiency": 55,
        "should_use_scrap": True
    }
}

# Caso 15: Optimización Extrema - 150 piezas mixtas
CASE_EXTREME_OPTIMIZATION = {
    "name": "Optimización Extrema: 150 piezas variadas con 30 sobrantes",
    "input": {
        "pieces_to_cut": [
            # Piezas muy grandes
            *[
                {"id": "xl1", "width": 1500, "height": 1800, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(3)
            ],
            *[
                {"id": "xl2", "width": 1400, "height": 1700, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(3)
            ],
            # Piezas grandes
            *[
                {"id": "l1", "width": 1000, "height": 1200, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(10)
            ],
            *[
                {"id": "l2", "width": 900, "height": 1100, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(12)
            ],
            *[
                {"id": "l3", "width": 800, "height": 1000, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(15)
            ],
            # Piezas medianas
            *[
                {"id": "m1", "width": 600, "height": 800, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(20)
            ],
            *[
                {"id": "m2", "width": 500, "height": 700, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(22)
            ],
            *[
                {"id": "m3", "width": 550, "height": 650, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(18)
            ],
            # Piezas pequeñas
            *[
                {"id": "s1", "width": 300, "height": 400, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(25)
            ],
            *[
                {"id": "s2", "width": 250, "height": 350, "quantity": 1, "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
                for _ in range(22)
            ]
        ]
    },
    "stock": {
        "scraps": [
            # Sobrantes diversos
            *[{"id": f"big_scrap_{i}", "width": 1700 - (i * 50), "height": 1800 - (i * 40),
               "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": f"BIG-{i:03d}"}
              for i in range(1, 11)],  # 10 grandes
            *[{"id": f"med_scrap_{i}", "width": 1200 - (i * 30), "height": 1300 - (i * 25),
               "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": f"MED-{i:03d}"}
              for i in range(1, 11)],  # 10 medianos
            *[{"id": f"small_scrap_{i}", "width": 800 - (i * 20), "height": 900 - (i * 15),
               "glass_type": "FLO", "thickness": "6mm", "color": "INC", "ref_number": f"SML-{i:03d}"}
              for i in range(1, 11)]  # 10 pequeños
        ],
        "glassplates": [
            {"id": "plate1", "width": 2000, "height": 2000, "quantity": 25,
             "glass_type": "FLO", "thickness": "6mm", "color": "INC"}
        ]
    },
    "expected": {
        "pieces_placed": 150,
        "max_plates_used": 40,
        "min_efficiency": 60,
        "should_use_scrap": True
    }
}

# Lista de todos los casos para iteración fácil
ALL_TEST_CASES = [
    CASE_SIMPLE_SCRAP,
    CASE_MULTIPLE_PIECES,
    CASE_NEW_PLATE,
    CASE_ROTATION,
    CASE_WASTE_QUALITY,
    CASE_EMERGENCY_PLATE,
    CASE_FEWER_PLATES_PRIORITY,
    CASE_MANY_SMALL_PIECES,
    CASE_NO_OVERLAP,
    CASE_REF_NUMBER_PRESERVATION,
    # Casos grandes y complejos
    CASE_HIGH_PRODUCTION,
    CASE_MULTI_GLASS_TYPES,
    CASE_STANDARD_WINDOWS,
    CASE_MASSIVE_STOCK,
    CASE_EXTREME_OPTIMIZATION
]
