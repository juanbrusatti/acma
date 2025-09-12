#!/usr/bin/env ruby

# Script para ejecutar todos los tests simples
puts "=== EJECUTANDO TESTS SIMPLES DE HELPERS ==="
puts

# Array con todos los tests simples
test_files = [
  'test/simple_currency_test.rb',
  'test/simple_supplies_test.rb', 
  'test/simple_glass_prices_test.rb',
  'test/simple_pdf_test.rb'
]

total_tests = 0
total_assertions = 0
total_failures = 0
total_errors = 0

test_files.each do |file|
  puts "Ejecutando #{file}..."
  
  # Ejecutar el test y capturar la salida
  output = `ruby #{file} 2>&1`
  
  # Extraer estadísticas de la salida
  if output.match(/(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors/)
    runs = $1.to_i
    assertions = $2.to_i
    failures = $3.to_i
    errors = $4.to_i
    
    total_tests += runs
    total_assertions += assertions
    total_failures += failures
    total_errors += errors
    
    status = (failures == 0 && errors == 0) ? "✅ PASÓ" : "❌ FALLÓ"
    puts "  #{status}: #{runs} tests, #{assertions} assertions"
  else
    puts "  ❌ ERROR: No se pudo ejecutar el test"
    puts "  Salida: #{output}"
    total_errors += 1
  end
  
  puts
end

puts "=== RESUMEN FINAL ==="
puts "Total de tests ejecutados: #{total_tests}"
puts "Total de assertions: #{total_assertions}"
puts "Total de fallos: #{total_failures}"
puts "Total de errores: #{total_errors}"

if total_failures == 0 && total_errors == 0
  puts "🎉 ¡TODOS LOS TESTS PASARON!"
else
  puts "⚠️  Hay tests que fallaron o tuvieron errores"
end
