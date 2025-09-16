namespace :dollar_sim do
  desc "Simular el sistema automático del dólar para múltiples días"
  task :simulate_days, [:days] => :environment do |t, args|
    days = (args[:days] || 10).to_i
    
    puts "🚀 Simulando #{days} días del sistema automático del dólar..."
    puts "=" * 60
    
    # Verificar que el sistema esté activo
    unless AppConfig.official_rate_system_active?
      puts "⚠️  El sistema de cotizaciones oficiales no está activo."
      puts "   Ejecuta: rails official_rates:activate"
      exit 1
    end
    
    # Obtener cotización base
    base_rate = AppConfig.current_mep_rate || 1000.0
    puts "📊 Cotización base: ARS $#{base_rate}"
    
    # Generar cotizaciones simuladas
    puts "\n📅 Generando cotizaciones para #{days} días..."
    
    simulated_data = []
    current_rate = base_rate
    
    days.times do |i|
      date = Date.current + i.days
      
      # Saltar domingos (no hay cotización)
      next if date.sunday?
      
      # Generar variación realista (±1.5% máximo por día)
      variation = rand(-0.015..0.015)
      current_rate = current_rate * (1 + variation)
      
      # Mantener cotización dentro de rangos realistas
      current_rate = [current_rate, 800.0].max
      current_rate = [current_rate, 1200.0].min
      
      simulated_data << {
        date: date,
        rate: current_rate.round(2)
      }
      
      puts "  #{date.strftime('%d/%m/%Y')}: ARS $#{current_rate.round(2)}"
    end
    
    puts "\n🔄 Procesando días..."
    
    simulated_data.each_with_index do |data, index|
      date = data[:date]
      rate = data[:rate]
      
      puts "\n📅 Día #{index + 1}: #{date.strftime('%d/%m/%Y')} - ARS $#{rate}"
      
      # Crear registro de cotización
      begin
        # Verificar si ya existe una cotización para esta fecha
        existing_rate = OfficialRateHistory.find_by(rate_date: date)
        
        if existing_rate
          puts "  ⚠️  Ya existe cotización para #{date.strftime('%d/%m/%Y')}, actualizando..."
          existing_rate.update!(
            rate: rate,
            source: 'simulation',
            manual_update: false
          )
          rate_history = existing_rate
        else
          puts "  ✅ Creando nueva cotización..."
          rate_history = OfficialRateHistory.create_with_change_calculation(
            rate: rate,
            source: 'simulation',
            rate_date: date,
            manual_update: false
          )
        end
        
        # Actualizar precios de insumos
        updated_supplies = 0
        Supply.all.find_each do |supply|
          if supply.price_usd.present? && supply.price_usd > 0
            supply.update_peso_price_from_usd!(rate)
            updated_supplies += 1
          end
        end
        
        # Actualizar MEP rate en AppConfig
        AppConfig.set_mep_rate(rate)
        
        puts "  💰 Precios actualizados: #{updated_supplies} insumos"
        puts "  📈 Cambio: #{rate_history.formatted_change_percentage}" if rate_history.previous_rate
        puts "  🏦 Dólar oficial: ARS $#{AppConfig.current_mep_rate}"
        
        # Verificar si es un cambio significativo
        if rate_history.significant_change?
          puts "  ⚠️  CAMBIO SIGNIFICATIVO DETECTADO!"
        end
        
      rescue => e
        puts "  ❌ Error: #{e.message}"
      end
      
      # Pequeña pausa para visualización
      sleep(0.3)
    end
    
    puts "\n🎉 Simulación completada!"
    puts "=" * 60
    
    # Mostrar resumen final
    show_simulation_summary(days)
  end
  
  desc "Probar el sistema con una cotización real"
  task :test_real => :environment do
    puts "🌐 Probando sistema con API real..."
    puts "=" * 50
    
    # Verificar APIs
    availability = OfficialRateApiService.check_api_availability
    puts "🌐 Estado de APIs:"
    puts "  DolarAPI: #{availability[:dolarapi] ? '✅ Disponible' : '❌ No disponible'}"
    puts "  BCRA: #{availability[:bcra] ? '✅ Disponible' : '❌ No disponible'}"
    
    if availability[:dolarapi] || availability[:bcra]
      puts "\n🔄 Ejecutando actualización automática..."
      begin
        UpdateOfficialRateJob.perform_now('automatic')
        puts "✅ Actualización completada exitosamente"
        
        # Mostrar resultados
        latest = OfficialRateHistory.order(rate_date: :desc).first
        if latest
          puts "\n📊 Resultados:"
          puts "  📅 Fecha: #{latest.rate_date.strftime('%d/%m/%Y')}"
          puts "  💰 Cotización: ARS $#{latest.rate}"
          puts "  📈 Cambio: #{latest.formatted_change_percentage}" if latest.previous_rate
          puts "  🔄 Fuente: #{latest.source}"
        end
        
      rescue => e
        puts "❌ Error: #{e.message}"
      end
    else
      puts "\n⚠️  APIs no disponibles, usando datos simulados..."
      simulate_single_day(Date.current, 1050.0)
    end
  end
  
  desc "Limpiar datos de simulación"
  task :cleanup => :environment do
    puts "🧹 Limpiando datos de simulación..."
    
    deleted_count = OfficialRateHistory.where(source: 'simulation').delete_all
    
    puts "✅ Eliminados #{deleted_count} registros de simulación"
  end
  
  desc "Mostrar estadísticas del sistema"
  task :stats => :environment do
    puts "📊 Estadísticas del Sistema de Cotizaciones"
    puts "=" * 50
    
    puts "🔧 Configuración:"
    puts "  Sistema activo: #{AppConfig.official_rate_system_active? ? '✅ Sí' : '❌ No'}"
    puts "  Dólar oficial actual: ARS $#{AppConfig.current_mep_rate}"
    
    puts "\n📈 Cotizaciones:"
    puts "  Total registros: #{OfficialRateHistory.count}"
    puts "  Última cotización: #{OfficialRateHistory.latest_rate || 'N/A'}"
    puts "  Cotización de hoy: #{OfficialRateHistory.today_rate || 'N/A'}"
    puts "  Cotización de ayer: #{OfficialRateHistory.yesterday_rate || 'N/A'}"
    
    puts "\n📊 Tipos de actualización:"
    puts "  Automáticas: #{OfficialRateHistory.automatic_updates.count}"
    puts "  Manuales: #{OfficialRateHistory.manual_updates.count}"
    puts "  Simulaciones: #{OfficialRateHistory.where(source: 'simulation').count}"
    
    puts "\n⚠️  Cambios significativos: #{OfficialRateHistory.significant_changes.count}"
    
    puts "\n📅 Últimas 5 cotizaciones:"
    OfficialRateHistory.order(rate_date: :desc).limit(5).each do |history|
      change_indicator = history.significant_change? ? " ⚠️" : ""
      puts "  #{history.rate_date.strftime('%d/%m/%Y')}: ARS $#{history.rate} (#{history.source})#{change_indicator}"
    end
    
    puts "\n💼 Insumos:"
    puts "  Total: #{Supply.count}"
    puts "  Con precio USD: #{Supply.where.not(price_usd: nil).count}"
    puts "  Con precio ARS: #{Supply.where.not(price_peso: nil).count}"
  end
  
  private
  
  def simulate_single_day(date, rate)
    puts "🎭 Simulando día: #{date.strftime('%d/%m/%Y')} con ARS $#{rate}"
    
    OfficialRateHistory.create_with_change_calculation(
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
    
    AppConfig.set_mep_rate(rate)
    
    puts "✅ Día simulado exitosamente"
  end
  
  def show_simulation_summary(days)
    puts "\n📊 RESUMEN DE SIMULACIÓN:"
    puts "Período simulado: #{days} días"
    puts "Total registros: #{OfficialRateHistory.count}"
    
    # Estadísticas por tipo
    automatic_count = OfficialRateHistory.automatic_updates.count
    manual_count = OfficialRateHistory.manual_updates.count
    simulation_count = OfficialRateHistory.where(source: 'simulation').count
    
    puts "\n📊 Tipos de actualización:"
    puts "  Automáticas: #{automatic_count}"
    puts "  Manuales: #{manual_count}"
    puts "  Simulaciones: #{simulation_count}"
    
    # Cambios significativos
    significant_count = OfficialRateHistory.significant_changes.count
    puts "\n⚠️  Cambios significativos: #{significant_count}"
    
    if significant_count > 0
      puts "  Detalles:"
      OfficialRateHistory.significant_changes.limit(3).each do |change|
        puts "    #{change.rate_date.strftime('%d/%m/%Y')}: #{change.formatted_change_percentage}"
      end
    end
    
    # Últimas cotizaciones
    puts "\n📈 Últimas cotizaciones:"
    OfficialRateHistory.order(rate_date: :desc).limit(5).each do |history|
      change_indicator = history.significant_change? ? " ⚠️" : ""
      puts "  #{history.rate_date.strftime('%d/%m/%Y')}: ARS $#{history.rate} (#{history.source})#{change_indicator}"
    end
    
    puts "\n💡 Para ver más detalles: rails dollar_sim:stats"
  end
end
