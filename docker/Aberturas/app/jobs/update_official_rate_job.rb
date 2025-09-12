class UpdateOfficialRateJob < ApplicationJob
  queue_as :default
  
  # Reintentar el job hasta 3 veces si falla
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(source = 'automatic')
    Rails.logger.info "Iniciando actualización automática de cotización oficial del dólar"
    
    begin
      # Obtener la cotización desde las APIs
      rate = OfficialRateApiService.fetch_official_rate
      
      if rate.nil?
        Rails.logger.error "No se pudo obtener la cotización oficial del dólar"
        raise StandardError, "No se pudo obtener la cotización oficial del dólar"
      end
      
      # Verificar si ya existe una cotización para hoy
      today = Date.current
      existing_rate = OfficialRateHistory.by_date(today).first
      
      if existing_rate
        Rails.logger.info "Ya existe una cotización para hoy (#{today}), actualizando..."
        existing_rate.update!(
          rate: rate,
          source: source,
          manual_update: source == 'manual'
        )
        rate_history = existing_rate
      else
        Rails.logger.info "Creando nueva cotización para hoy (#{today}): ARS $#{rate}"
        rate_history = OfficialRateHistory.create_with_change_calculation(
          rate: rate,
          source: source,
          rate_date: today,
          manual_update: source == 'manual'
        )
      end
      
      # Actualizar el MEP rate en AppConfig para mantener compatibilidad
      AppConfig.set_mep_rate(rate)
      
      # Actualizar todos los precios de insumos
      update_supply_prices(rate)
      
      # Verificar si hay cambios significativos y enviar notificación
      check_significant_change(rate_history)
      
      Rails.logger.info "Actualización de cotización oficial completada exitosamente"
      
    rescue => e
      Rails.logger.error "Error en actualización automática de cotización: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def update_supply_prices(rate)
    Rails.logger.info "Actualizando precios de insumos con nueva cotización: ARS $#{rate}"
    
    updated_count = 0
    Supply.all.find_each do |supply|
      if supply.price_usd.present? && supply.price_usd > 0
        supply.update_peso_price_from_usd!(rate)
        updated_count += 1
      end
    end
    
    # Recalcular precios de cámaras de aire
    AppConfig.update_all_innertube_prices
    
    Rails.logger.info "Precios de insumos actualizados: #{updated_count} insumos procesados"
  end

  def check_significant_change(rate_history)
    return unless rate_history.significant_change?
    
    Rails.logger.warn "Cambio significativo detectado: #{rate_history.formatted_change_percentage}"
    
    # Enviar notificación por cambio significativo
    NotificationService.notify_significant_rate_change(rate_history)
    
    Rails.logger.info "Cambio significativo en cotización oficial: #{rate_history.formatted_rate} (#{rate_history.formatted_change_percentage})"
  end
end
