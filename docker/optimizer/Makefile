# Makefile para facilitar la ejecución de tests del optimizador

.PHONY: help test test-unit test-cases test-all test-with-pdfs clean clean-outputs

help:
	@echo "🧪 Tests del Optimizador de Corte"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Comandos disponibles:"
	@echo "  make test           - Ejecutar todos los tests (sin PDFs)"
	@echo "  make test-unit      - Solo tests unitarios (unittest)"
	@echo "  make test-cases     - Solo casos predefinidos (CON PDFs) ⭐"
	@echo "  make test-with-pdfs - Tests unitarios guardando PDFs"
	@echo "  make test-docker    - Ejecutar tests dentro de Docker"
	@echo "  make summary-big    - Ver resumen de casos grandes ⭐"
	@echo "  make clean          - Limpiar archivos temporales"
	@echo "  make clean-outputs  - Limpiar solo test_outputs/"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test: test-all

test-all:
	@echo "🚀 Ejecutando todos los tests..."
	@./test/run_all_tests.sh

test-unit:
	@echo "🧪 Ejecutando tests unitarios..."
	@python test/test_optimizer.py

test-cases:
	@echo "📋 Ejecutando casos predefinidos (generando PDFs)..."
	@python test/run_test_cases.py

test-with-pdfs:
	@echo "🧪 Ejecutando tests unitarios con PDFs..."
	@SAVE_TEST_ARTIFACTS=true python test/test_optimizer.py

test-docker:
	@echo "🐳 Ejecutando tests en Docker..."
	@cd .. && docker compose run --rm optimizer bash -c "cd /app && python test/test_optimizer.py && python test/run_test_cases.py"

clean:
	@echo "🧹 Limpiando archivos temporales..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -rf output_plan/* output_visuals/* 2>/dev/null || true
	@echo "✅ Limpieza completada"

clean-outputs:
	@echo "🧹 Limpiando test_outputs/..."
	@rm -rf test_outputs/ 2>/dev/null || true
	@echo "✅ test_outputs/ eliminado"

summary-big:
	@echo "📊 Mostrando resumen de casos grandes..."
	@./test/show_big_cases_summary.sh
