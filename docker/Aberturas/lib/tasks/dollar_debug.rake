namespace :dollar_debug do
  desc "Verificar qué tipo de dólar está obteniendo el sistema"
  task :verify_dollar_type => :environment do
    puts "🔍 Verificación del Sistema de Dólar"
    puts "=" * 50
    
    puts "\n🌐 Probando APIs:"
    
    # Probar DolarAPI oficial
    puts "📡 DolarAPI Oficial:"
    begin
      response = HTTParty.get('https://dolarapi.com/v1/dolares/oficial', timeout: 10)
      if response.success?
        data = response.parsed_response
        puts "  ✅ Disponible"
        puts "  💰 Compra: ARS $#{data['compra']}"
        puts "  💰 Venta: ARS $#{data['venta']}"
        puts "  📅 Actualizado: #{data['fechaActualizacion']}"
      else
        puts "  ❌ Error HTTP: #{response.code}"
      end
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end
    
    # Probar DolarAPI MEP
    puts "\n📡 DolarAPI MEP:"
    begin
      response = HTTParty.get('https://dolarapi.com/v1/dolares/mep', timeout: 10)
      if response.success?
        data = response.parsed_response
        puts "  ✅ Disponible"
        puts "  💰 Compra: ARS $#{data['compra']}"
        puts "  💰 Venta: ARS $#{data['venta']}"
        puts "  📅 Actualizado: #{data['fechaActualizacion']}"
      else
        puts "  ❌ Error HTTP: #{response.code}"
      end
    rescue => e
      puts "  ❌ Error: #{e.message}"
    end
    
    puts "\n🔧 Estado del Sistema:"
    puts "  Sistema activo: #{AppConfig.official_rate_system_active? ? '✅ Sí' : '❌ No'}"
    puts "  Dólar oficial guardado: ARS $#{AppConfig.current_mep_rate}"
    puts "  Última cotización oficial: #{OfficialRateHistory.latest_rate || 'N/A'}"
    
    puts "\n📊 Comparación:"
    api_official = OfficialRateApiService.fetch_official_rate
    stored_rate = AppConfig.current_mep_rate
    
    puts "  API Dólar Oficial: ARS $#{api_official}"
    puts "  Sistema guardado: ARS $#{stored_rate}"
    
    if api_official && stored_rate
      difference = ((api_official - stored_rate) / stored_rate * 100).round(2)
      puts "  Diferencia: #{difference > 0 ? '+' : ''}#{difference}%"
      
      if difference.abs > 5
        puts "  ⚠️  GRAN DIFERENCIA DETECTADA!"
      else
        puts "  ✅ Diferencia normal"
      end
    end
    
    puts "\n💡 Conclusión:"
    puts "  El sistema SÍ obtiene el dólar OFICIAL de las APIs"
    puts "  PERO la nomenclatura 'MEP rate' es confusa"
    puts "  En realidad debería llamarse 'official_rate'"
  end
  
  desc "Actualizar con dólar oficial real"
  task :update_real => :environment do
    puts "🔄 Actualizando con dólar oficial real..."
    
    begin
      # Obtener dólar oficial real
      real_rate = OfficialRateApiService.fetch_official_rate
      
      if real_rate
        puts "💰 Dólar oficial obtenido: ARS $#{real_rate}"
        
        # Crear registro para hoy
        OfficialRateHistory.create_with_change_calculation(
          rate: real_rate,
          source: 'manual',
          rate_date: Date.current,
          manual_update: true
        )
        
        # Actualizar AppConfig
        AppConfig.set_mep_rate(real_rate)
        
        # Actualizar precios de insumos
        Supply.all.find_each do |supply|
          if supply.price_usd.present? && supply.price_usd > 0
            supply.update_peso_price_from_usd!(real_rate)
          end
        end
        
        puts "✅ Sistema actualizado con dólar oficial real"
        puts "🏦 Dólar oficial: ARS $#{AppConfig.current_mep_rate}"
        
      else
        puts "❌ No se pudo obtener el dólar oficial"
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
  
  desc "Mostrar todos los tipos de dólar disponibles"
  task :show_all_types => :environment do
    puts "💱 Todos los Tipos de Dólar Disponibles"
    puts "=" * 50
    
    begin
      response = HTTParty.get('https://dolarapi.com/v1/dolares', timeout: 10)
      
      if response.success?
        data = response.parsed_response
        
        puts "\n📊 Cotizaciones disponibles:"
        
        data.each do |dollar_type|
          puts "\n🏦 #{dollar_type['nombre']} (#{dollar_type['casa']}):"
          puts "  💰 Compra: ARS $#{dollar_type['compra']}"
          puts "  💰 Venta: ARS $#{dollar_type['venta']}"
          puts "  📅 Actualizado: #{dollar_type['fechaActualizacion']}"
        end
        
        puts "\n🎯 El sistema usa: OFICIAL"
        puts "❌ El sistema NO usa: MEP, Blue, CCL, etc."
        
      else
        puts "❌ Error al obtener datos: #{response.code}"
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
end
