class OfficialRateApiService
  include HTTParty
  
  # APIs gratuitas para obtener cotizaciones del dólar oficial del Banco Nación
  DOLARAPI_OFFICIAL_URL = 'https://dolarapi.com/v1/dolares/oficial'
  DOLARAPI_ALL_URL = 'https://dolarapi.com/v1/dolares'
  BCRA_OFFICIAL_URL = 'https://api.bcra.gob.ar/estadisticas/v1/datosvariable/7930'
  
  # Timeout para las requests HTTP
  TIMEOUT = 10
  
  # Headers para las requests
  HEADERS = {
    'User-Agent' => 'ACMA-OfficialRateService/1.0',
    'Accept' => 'application/json'
  }

  class << self
    # Método principal para obtener la cotización oficial
    def fetch_official_rate
      Rails.logger.info "Iniciando obtención de cotización oficial del dólar"
      
      # Intentar con la API principal primero
      rate = fetch_from_dolarapi
      
      # Si falla, usar API de respaldo
      if rate.nil?
        Rails.logger.warn "API principal falló, intentando con API de respaldo"
        rate = fetch_from_bcra
      end
      
      if rate
        Rails.logger.info "Cotización obtenida exitosamente: ARS $#{rate}"
        rate
      else
        Rails.logger.error "Todas las APIs fallaron al obtener la cotización oficial"
        nil
      end
    end

    # Obtener cotización desde DolarAPI (API principal)
    def fetch_from_dolarapi
      begin
        Rails.logger.info "Consultando DolarAPI: #{DOLARAPI_OFFICIAL_URL}"
        
        response = HTTParty.get(
          DOLARAPI_OFFICIAL_URL,
          headers: HEADERS,
          timeout: TIMEOUT
        )
        
        if response.success?
          data = response.parsed_response
          rate = data['venta']
          
          if rate && rate > 0
            Rails.logger.info "DolarAPI exitosa: ARS $#{rate}"
            return rate.to_f
          else
            Rails.logger.warn "DolarAPI: Datos inválidos recibidos"
          end
        else
          Rails.logger.warn "DolarAPI: Error HTTP #{response.code}"
        end
      rescue => e
        Rails.logger.error "DolarAPI: Error de conexión - #{e.message}"
        NotificationService.notify_api_failure('DolarAPI', e.message)
      end
      
      nil
    end

    # Obtener cotización desde BCRA (API de respaldo)
    def fetch_from_bcra
      begin
        Rails.logger.info "Consultando BCRA: #{BCRA_OFFICIAL_URL}"
        
        response = HTTParty.get(
          BCRA_OFFICIAL_URL,
          headers: HEADERS,
          timeout: TIMEOUT
        )
        
        if response.success?
          data = response.parsed_response
          
          # BCRA devuelve un array de datos, tomar el más reciente
          if data.is_a?(Array) && data.any?
            latest_data = data.first
            rate = latest_data['valor']
            
            if rate && rate > 0
              Rails.logger.info "BCRA exitosa: ARS $#{rate}"
              return rate.to_f
            else
              Rails.logger.warn "BCRA: Datos inválidos recibidos"
            end
          else
            Rails.logger.warn "BCRA: Estructura de datos inesperada"
          end
        else
          Rails.logger.warn "BCRA: Error HTTP #{response.code}"
        end
      rescue => e
        Rails.logger.error "BCRA: Error de conexión - #{e.message}"
        NotificationService.notify_api_failure('BCRA', e.message)
      end
      
      nil
    end

    # Obtener todas las cotizaciones disponibles desde DolarAPI
    def fetch_all_rates
      begin
        Rails.logger.info "Consultando todas las cotizaciones desde DolarAPI"
        
        response = HTTParty.get(
          DOLARAPI_ALL_URL,
          headers: HEADERS,
          timeout: TIMEOUT
        )
        
        if response.success?
          data = response.parsed_response
          Rails.logger.info "Todas las cotizaciones obtenidas exitosamente"
          return data
        else
          Rails.logger.warn "Error al obtener todas las cotizaciones: HTTP #{response.code}"
        end
      rescue => e
        Rails.logger.error "Error de conexión al obtener todas las cotizaciones: #{e.message}"
      end
      
      nil
    end

    # Verificar si las APIs están disponibles
    def check_api_availability
      availability = {
        dolarapi: false,
        bcra: false
      }
      
      # Verificar DolarAPI
      begin
        response = HTTParty.get(
          DOLARAPI_OFFICIAL_URL,
          headers: HEADERS,
          timeout: 5
        )
        availability[:dolarapi] = response.success?
      rescue
        availability[:dolarapi] = false
      end
      
      # Verificar BCRA
      begin
        response = HTTParty.get(
          BCRA_OFFICIAL_URL,
          headers: HEADERS,
          timeout: 5
        )
        availability[:bcra] = response.success?
      rescue
        availability[:bcra] = false
      end
      
      availability
    end

    # Obtener información detallada de las APIs
    def api_status_info
      availability = check_api_availability
      
      {
        primary_api: {
          name: 'DolarAPI',
          url: DOLARAPI_OFFICIAL_URL,
          status: availability[:dolarapi] ? 'available' : 'unavailable'
        },
        backup_api: {
          name: 'BCRA',
          url: BCRA_OFFICIAL_URL,
          status: availability[:bcra] ? 'available' : 'unavailable'
        },
        last_check: Time.current,
        overall_status: availability.values.any? ? 'operational' : 'down'
      }
    end
  end
end
