class UpdateOfficialRateJob < ApplicationJob
  queue_as :default
  
  def perform(date: Date.current)
    Rails.logger.info "Iniciando actualización automática del dólar oficial para #{date}"
    
    # Obtener la cotización desde la API
    api_result = OfficialRateApiService.get_current_official_rate
    
    if api_result[:success]
      rate = api_result[:rate]
      source = api_result[:source]
      
      Rails.logger.info "Cotización obtenida: $#{rate} desde #{source}"
      
      # Guardar en el historial
      begin
        history_record = OfficialRateHistory.create_or_update_rate(
          date: date,
          rate: rate,
          source: source,
          notes: "Actualización automática",
          is_manual: false
        )
        
        Rails.logger.info "Historial guardado: #{history_record.id}"
        
        # Actualizar la configuración actual de la aplicación
        AppConfig.set_official_rate(rate)
        
        # Actualizar todos los precios de insumos
        update_supply_prices(rate)
        
        # Recalcular precios de cámaras de aire
        AppConfig.update_all_innertube_prices
        
        Rails.logger.info "Actualización automática del dólar oficial completada exitosamente"
        
        # Enviar notificación si hay cambios significativos
        notify_significant_change(rate) if should_notify?(rate)
        
      rescue StandardError => e
        Rails.logger.error "Error al guardar el historial: #{e.message}"
        raise e
      end
      
    else
      Rails.logger.error "Error al obtener cotización del dólar oficial: #{api_result[:error]}"
      
      # Si es un día hábil y no hay cotización, usar la del día anterior
      if date.on_weekday? && OfficialRateHistory.today_rate.nil?
        previous_rate = OfficialRateHistory.previous_day_rate
        if previous_rate
          Rails.logger.info "Usando cotización del día anterior: $#{previous_rate}"
          AppConfig.set_official_rate(previous_rate)
          
          # Guardar como registro manual con nota
          OfficialRateHistory.create_or_update_rate(
            date: date,
            rate: previous_rate,
            source: 'previous_day_fallback',
            notes: "Cotización del día anterior (API no disponible)",
            is_manual: false
          )
        end
      end
      
      raise StandardError, "No se pudo obtener la cotización del dólar oficial: #{api_result[:error]}"
    end
  end
  
  private
  
  def update_supply_prices(official_rate)
    Rails.logger.info "Actualizando precios de insumos con dólar oficial: $#{official_rate}"
    
    updated_count = 0
    Supply.all.find_each do |supply|
      if supply.price_usd.present? && supply.price_usd > 0
        supply.update_peso_price_from_usd!(official_rate)
        updated_count += 1
      end
    end
    
    Rails.logger.info "Precios de insumos actualizados: #{updated_count} registros"
  end
  
  def should_notify?(current_rate)
    previous_rate = OfficialRateHistory.previous_day_rate
    return false unless previous_rate
    
    # Notificar si hay un cambio mayor al 5%
    change_percentage = ((current_rate - previous_rate) / previous_rate * 100).abs
    change_percentage > 5.0
  end
  
  def notify_significant_change(current_rate)
    previous_rate = OfficialRateHistory.previous_day_rate
    change_percentage = ((current_rate - previous_rate) / previous_rate * 100)
    
    Rails.logger.warn "CAMBIO SIGNIFICATIVO EN DÓLAR OFICIAL: #{change_percentage.round(2)}%"
    Rails.logger.warn "Día anterior: $#{previous_rate} | Hoy: $#{current_rate}"
    
    # Aquí podrías agregar notificaciones por email, Slack, etc.
    # Por ejemplo:
    # NotificationMailer.official_rate_change_notification(current_rate, previous_rate).deliver_now
  end
end
