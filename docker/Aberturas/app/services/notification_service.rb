class NotificationService
  class << self
    # Enviar notificación por cambios significativos en la cotización
    def notify_significant_rate_change(rate_history)
      return unless rate_history.significant_change?
      
      Rails.logger.warn "NOTIFICACIÓN: Cambio significativo en cotización oficial"
      Rails.logger.warn "Cotización: #{rate_history.formatted_rate}"
      Rails.logger.warn "Cambio: #{rate_history.formatted_change_percentage}"
      Rails.logger.warn "Fecha: #{rate_history.rate_date.strftime('%d/%m/%Y')}"
      
      # Aquí se pueden agregar más canales de notificación:
      # - Email
      # - Slack
      # - SMS
      # - Push notifications
      
      # Por ahora solo logueamos el cambio significativo
      log_significant_change(rate_history)
    end

    # Enviar notificación cuando las APIs fallan
    def notify_api_failure(api_name, error_message)
      Rails.logger.error "NOTIFICACIÓN: Fallo en API de cotización"
      Rails.logger.error "API: #{api_name}"
      Rails.logger.error "Error: #{error_message}"
      
      # Aquí se pueden agregar notificaciones por otros canales
      log_api_failure(api_name, error_message)
    end

    # Enviar notificación cuando el sistema se activa por primera vez
    def notify_system_activation(rate)
      Rails.logger.info "NOTIFICACIÓN: Sistema de cotizaciones oficiales activado"
      Rails.logger.info "Primera cotización: #{rate}"
      
      log_system_activation(rate)
    end

    private

    def log_significant_change(rate_history)
      # Crear un registro de notificación en la base de datos
      # Esto se puede expandir para crear un sistema de notificaciones más robusto
      Rails.logger.info "Registrando cambio significativo en cotización oficial"
    end

    def log_api_failure(api_name, error_message)
      # Registrar fallos de API para monitoreo
      Rails.logger.info "Registrando fallo de API: #{api_name}"
    end

    def log_system_activation(rate)
      # Registrar activación del sistema
      Rails.logger.info "Sistema de cotizaciones oficiales activado con cotización: #{rate}"
    end
  end
end
