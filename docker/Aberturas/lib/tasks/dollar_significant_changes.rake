namespace :dollar_test do
  desc "Simular cambios significativos en el dólar para probar notificaciones"
  task :significant_changes => :environment do
    puts "⚠️  Simulando cambios significativos en el dólar..."
    puts "=" * 60
    
    # Obtener cotización base
    base_rate = AppConfig.current_mep_rate || 1000.0
    puts "📊 Cotización base: ARS $#{base_rate}"
    
    # Crear escenarios de cambios significativos
    scenarios = [
      { date: Date.current + 1.day, rate: base_rate * 1.05, description: "Subida del 5%" },
      { date: Date.current + 2.days, rate: base_rate * 1.10, description: "Subida del 10%" },
      { date: Date.current + 3.days, rate: base_rate * 0.95, description: "Bajada del 5%" },
      { date: Date.current + 4.days, rate: base_rate * 0.90, description: "Bajada del 10%" },
      { date: Date.current + 5.days, rate: base_rate * 1.15, description: "Subida del 15%" },
      { date: Date.current + 6.days, rate: base_rate * 0.85, description: "Bajada del 15%" }
    ]
    
    puts "\n📅 Escenarios de cambios significativos:"
    scenarios.each_with_index do |scenario, index|
      change_percent = ((scenario[:rate] - base_rate) / base_rate * 100).round(2)
      puts "  #{index + 1}. #{scenario[:date].strftime('%d/%m/%Y')}: ARS $#{scenario[:rate].round(2)} (#{change_percent > 0 ? '+' : ''}#{change_percent}%) - #{scenario[:description]}"
    end
    
    puts "\n🔄 Procesando escenarios..."
    
    scenarios.each_with_index do |scenario, index|
      date = scenario[:date]
      rate = scenario[:rate].round(2)
      description = scenario[:description]
      
      puts "\n📅 Escenario #{index + 1}: #{date.strftime('%d/%m/%Y')} - #{description}"
      puts "  💰 Cotización: ARS $#{rate}"
      
      begin
        # Crear registro de cotización
        rate_history = OfficialRateHistory.create_with_change_calculation(
          rate: rate,
          source: 'simulation',
          rate_date: date,
          manual_update: false
        )
        
        # Actualizar precios de insumos
        updated_supplies = 0
        Supply.all.find_each do |supply|
          if supply.price_usd.present? && supply.price_usd > 0
            supply.update_peso_price_from_usd!(rate)
            updated_supplies += 1
          end
        end
        
        # Actualizar MEP rate
        AppConfig.set_mep_rate(rate)
        
        puts "  ✅ Cotización creada exitosamente"
        puts "  💼 Precios actualizados: #{updated_supplies} insumos"
        puts "  📈 Cambio: #{rate_history.formatted_change_percentage}" if rate_history.previous_rate
        
        # Verificar si es un cambio significativo
        if rate_history.significant_change?
          puts "  ⚠️  CAMBIO SIGNIFICATIVO DETECTADO!"
          puts "  📊 Porcentaje de cambio: #{rate_history.formatted_change_percentage}"
          
          # Simular notificación
          puts "  🔔 Notificación enviada: Cambio significativo en cotización oficial"
        else
          puts "  ℹ️  Cambio dentro del rango normal"
        end
        
        puts "  🏦 Dólar oficial: ARS $#{AppConfig.current_mep_rate}"
        
      rescue => e
        puts "  ❌ Error: #{e.message}"
      end
      
      # Pausa para visualización
      sleep(0.5)
    end
    
    puts "\n🎉 Simulación de cambios significativos completada!"
    puts "=" * 60
    
    # Mostrar resumen de cambios significativos
    show_significant_changes_summary
  end
  
  desc "Crear un escenario específico de cambio significativo"
  task :create_change, [:date, :rate, :description] => :environment do |t, args|
    date_str = args[:date] || (Date.current + 1.day).strftime('%Y-%m-%d')
    rate = args[:rate]&.to_f || 1200.0
    description = args[:description] || "Cambio significativo simulado"
    
    date = Date.parse(date_str)
    
    puts "📅 Creando cambio significativo:"
    puts "  Fecha: #{date.strftime('%d/%m/%Y')}"
    puts "  Cotización: ARS $#{rate}"
    puts "  Descripción: #{description}"
    
    begin
      # Crear registro
      rate_history = OfficialRateHistory.create_with_change_calculation(
        rate: rate,
        source: 'simulation',
        rate_date: date,
        manual_update: false
      )
      
      # Actualizar precios
      Supply.all.find_each do |supply|
        if supply.price_usd.present? && supply.price_usd > 0
          supply.update_peso_price_from_usd!(rate)
        end
      end
      
      # Actualizar MEP rate
      AppConfig.set_mep_rate(rate)
      
      puts "✅ Cambio creado exitosamente"
      
      if rate_history.significant_change?
        puts "⚠️  CAMBIO SIGNIFICATIVO DETECTADO!"
        puts "📊 Porcentaje: #{rate_history.formatted_change_percentage}"
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
  
  desc "Mostrar todos los cambios significativos"
  task :show_significant => :environment do
    puts "⚠️  Cambios Significativos en Cotizaciones"
    puts "=" * 50
    
    significant_changes = OfficialRateHistory.significant_changes.order(rate_date: :desc)
    
    if significant_changes.empty?
      puts "ℹ️  No hay cambios significativos registrados"
    else
      puts "📊 Total de cambios significativos: #{significant_changes.count}"
      puts "\n📅 Historial de cambios significativos:"
      
      significant_changes.each do |change|
        puts "  #{change.rate_date.strftime('%d/%m/%Y')}: ARS $#{change.rate} (#{change.formatted_change_percentage}) - #{change.source}"
      end
    end
    
    puts "\n💡 Para crear un cambio significativo:"
    puts "  rails dollar_test:create_change[2025-09-15,1200.0,'Subida del 20%']"
  end
  
  desc "Limpiar todos los datos de simulación"
  task :cleanup_all => :environment do
    puts "🧹 Limpiando todos los datos de simulación..."
    
    # Eliminar registros de simulación
    simulation_count = OfficialRateHistory.where(source: 'simulation').count
    OfficialRateHistory.where(source: 'simulation').delete_all
    
    puts "✅ Eliminados #{simulation_count} registros de simulación"
    
    # Mostrar estado actual
    puts "\n📊 Estado actual del sistema:"
    puts "  Total registros: #{OfficialRateHistory.count}"
    puts "  MEP rate: ARS $#{AppConfig.current_mep_rate}"
    puts "  Cambios significativos: #{OfficialRateHistory.significant_changes.count}"
  end
  
  private
  
  def show_significant_changes_summary
    puts "\n📊 RESUMEN DE CAMBIOS SIGNIFICATIVOS:"
    
    significant_changes = OfficialRateHistory.significant_changes.order(rate_date: :desc)
    
    if significant_changes.empty?
      puts "ℹ️  No se detectaron cambios significativos en esta simulación"
    else
      puts "⚠️  Total de cambios significativos: #{significant_changes.count}"
      
      puts "\n📅 Cambios detectados:"
      significant_changes.each do |change|
        puts "  #{change.rate_date.strftime('%d/%m/%Y')}: ARS $#{change.rate} (#{change.formatted_change_percentage})"
      end
      
      # Estadísticas adicionales
      puts "\n📊 Estadísticas:"
      puts "  Mayor subida: #{significant_changes.maximum(:change_percentage)&.round(2)}%"
      puts "  Mayor bajada: #{significant_changes.minimum(:change_percentage)&.round(2)}%"
      puts "  Promedio de cambio: #{significant_changes.average(:change_percentage)&.round(2)}%"
    end
    
    puts "\n💡 Para ver todos los cambios significativos:"
    puts "  rails dollar_test:show_significant"
  end
end
