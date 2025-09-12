namespace :official_rates do
  desc "Probar el sistema de cotizaciones oficiales"
  task test: :environment do
    puts "🧪 Probando sistema de cotizaciones oficiales..."
    
    # Verificar estado de las APIs
    puts "\n📡 Verificando estado de las APIs..."
    availability = OfficialRateApiService.check_api_availability
    puts "DolarAPI: #{availability[:dolarapi] ? '✅ Disponible' : '❌ No disponible'}"
    puts "BCRA: #{availability[:bcra] ? '✅ Disponible' : '❌ No disponible'}"
    
    # Intentar obtener cotización
    puts "\n💰 Obteniendo cotización oficial..."
    rate = OfficialRateApiService.fetch_official_rate
    
    if rate
      puts "✅ Cotización obtenida: ARS $#{rate}"
      
      # Crear registro de prueba
      puts "\n📝 Creando registro de prueba..."
      rate_history = OfficialRateHistory.create_with_change_calculation(
        rate: rate,
        source: 'test',
        rate_date: Date.current,
        manual_update: true,
        notes: 'Prueba del sistema'
      )
      
      if rate_history.persisted?
        puts "✅ Registro creado exitosamente"
        puts "   ID: #{rate_history.id}"
        puts "   Cotización: #{rate_history.formatted_rate}"
        puts "   Cambio: #{rate_history.formatted_change_percentage}"
        puts "   Significativo: #{rate_history.significant_change? ? 'Sí' : 'No'}"
      else
        puts "❌ Error al crear registro: #{rate_history.errors.full_messages.join(', ')}"
      end
    else
      puts "❌ No se pudo obtener la cotización"
    end
    
    # Mostrar estadísticas
    puts "\n📊 Estadísticas del sistema:"
    puts "Total de registros: #{OfficialRateHistory.count}"
    puts "Sistema activo: #{AppConfig.official_rate_system_active? ? 'Sí' : 'No'}"
    puts "Última cotización: #{OfficialRateHistory.latest_rate || 'N/A'}"
    puts "Cotización de ayer: #{OfficialRateHistory.yesterday_rate || 'N/A'}"
    
    puts "\n✅ Prueba completada!"
  end

  desc "Ejecutar actualización manual de cotización"
  task update: :environment do
    puts "🔄 Ejecutando actualización manual de cotización..."
    
    begin
      UpdateOfficialRateJob.perform_now('manual')
      puts "✅ Actualización completada exitosamente"
    rescue => e
      puts "❌ Error en la actualización: #{e.message}"
    end
  end

  desc "Mostrar estado del sistema"
  task status: :environment do
    puts "📊 Estado del Sistema de Cotizaciones Oficiales"
    puts "=" * 50
    
    puts "\n🔧 Configuración:"
    puts "Sistema activo: #{AppConfig.official_rate_system_active? ? '✅ Sí' : '❌ No'}"
    puts "MEP rate actual: ARS $#{AppConfig.current_mep_rate}"
    puts "Cotización oficial para precios: ARS $#{AppConfig.current_official_rate_for_pricing}"
    
    puts "\n📈 Cotizaciones:"
    puts "Última cotización: #{OfficialRateHistory.latest_rate || 'N/A'}"
    puts "Cotización de hoy: #{OfficialRateHistory.today_rate || 'N/A'}"
    puts "Cotización de ayer: #{OfficialRateHistory.yesterday_rate || 'N/A'}"
    
    puts "\n📊 Estadísticas:"
    puts "Total de registros: #{OfficialRateHistory.count}"
    puts "Actualizaciones manuales: #{OfficialRateHistory.manual_updates.count}"
    puts "Actualizaciones automáticas: #{OfficialRateHistory.automatic_updates.count}"
    puts "Cambios significativos: #{OfficialRateHistory.significant_changes.count}"
    
    puts "\n🌐 Estado de APIs:"
    availability = OfficialRateApiService.check_api_availability
    puts "DolarAPI: #{availability[:dolarapi] ? '✅ Disponible' : '❌ No disponible'}"
    puts "BCRA: #{availability[:bcra] ? '✅ Disponible' : '❌ No disponible'}"
    
    puts "\n⏰ Jobs programados:"
    puts "Lunes a Viernes: 9:00 AM"
    puts "Sábados: 10:00 AM"
    puts "Domingos: No se ejecuta"
  end
end
