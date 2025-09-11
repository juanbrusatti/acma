class OfficialRateApiService
  include HTTParty
  
  # APIs gratuitas para obtener cotizaciones del dólar oficial del Banco Nación
  DOLARAPI_OFFICIAL_URL = 'https://dolarapi.com/v1/dolares/oficial'
  DOLARAPI_ALL_URL = 'https://dolarapi.com/v1/dolares'
  BCRA_OFFICIAL_URL = 'https://api.bcra.gob.ar/estadisticas/v1/datosvariable/7930'
  
  def self.fetch_official_rate_from_dolarapi
    begin
      response = get(DOLARAPI_OFFICIAL_URL, timeout: 10)
      
      if response.success?
        data = response.parsed_response
        
        # DolarAPI devuelve directamente el dólar oficial
        if data['compra'] && data['compra'].is_a?(Numeric) && data['compra'] > 0
          {
            success: true,
            rate: data['compra'].to_f,
            source: 'dolarapi_oficial',
            timestamp: Time.current
          }
        else
          {
            success: false,
            error: 'No se pudo obtener una cotización válida del dólar oficial desde DolarAPI'
          }
        end
      else
        {
          success: false,
          error: "Error HTTP DolarAPI: #{response.code} - #{response.message}"
        }
      end
    rescue Timeout::Error
      {
        success: false,
        error: 'Timeout al conectar con DolarAPI'
      }
    rescue StandardError => e
      {
        success: false,
        error: "Error inesperado en DolarAPI: #{e.message}"
      }
    end
  end
  
  def self.fetch_official_rate_from_dolarapi_all
    begin
      response = get(DOLARAPI_ALL_URL, timeout: 10)
      
      if response.success?
        data = response.parsed_response
        
        # Buscar específicamente el dólar oficial en la lista
        official_data = data.find { |dollar| dollar['casa'] == 'oficial' }
        
        if official_data && official_data['compra'] && official_data['compra'].to_f > 0
          {
            success: true,
            rate: official_data['compra'].to_f,
            source: 'dolarapi_oficial_all',
            timestamp: Time.current
          }
        else
          {
            success: false,
            error: 'No se encontró cotización del dólar oficial en DolarAPI'
          }
        end
      else
        {
          success: false,
          error: "Error HTTP DolarAPI All: #{response.code} - #{response.message}"
        }
      end
    rescue Timeout::Error
      {
        success: false,
        error: 'Timeout al conectar con DolarAPI All'
      }
    rescue StandardError => e
      {
        success: false,
        error: "Error inesperado en DolarAPI All: #{e.message}"
      }
    end
  end
  
  def self.fetch_official_rate_from_bcra
    begin
      response = get(BCRA_OFFICIAL_URL, timeout: 10, verify: false)
      
      if response.success?
        data = response.parsed_response
        
        # BCRA devuelve un array de datos, buscar el más reciente
        if data.is_a?(Array) && data.any?
          latest_data = data.first
          if latest_data['valor'] && latest_data['valor'].to_f > 0
            {
              success: true,
              rate: latest_data['valor'].to_f,
              source: 'bcra_oficial',
              timestamp: Time.current
            }
          else
            {
              success: false,
              error: 'No se encontró valor válido en BCRA'
            }
          end
        else
          {
            success: false,
            error: 'Respuesta inválida de BCRA'
          }
        end
      else
        {
          success: false,
          error: "Error HTTP BCRA: #{response.code} - #{response.message}"
        }
      end
    rescue Timeout::Error
      {
        success: false,
        error: 'Timeout al conectar con BCRA'
      }
    rescue StandardError => e
      {
        success: false,
        error: "Error inesperado en BCRA: #{e.message}"
      }
    end
  end
  
  # Método principal que intenta todas las APIs en orden de preferencia
  def self.get_current_official_rate
    # Intentar primero con DolarAPI específico para oficial
    result = fetch_official_rate_from_dolarapi
    
    # Si falla, intentar con DolarAPI general
    if !result[:success]
      Rails.logger.warn "DolarAPI Oficial falló: #{result[:error]}. Intentando DolarAPI All..."
      result = fetch_official_rate_from_dolarapi_all
    end
    
    # Si falla, intentar con BCRA como último recurso
    if !result[:success]
      Rails.logger.warn "DolarAPI All falló: #{result[:error]}. Intentando BCRA..."
      result = fetch_official_rate_from_bcra
    end
    
    # Si todas fallan, registrar el error
    if !result[:success]
      Rails.logger.error "Todas las APIs fallaron. Último error: #{result[:error]}"
    end
    
    result
  end
  
  # Método para obtener información sobre las APIs disponibles
  def self.api_status
    apis = [
      { name: 'DolarAPI Oficial', url: DOLARAPI_OFFICIAL_URL },
      { name: 'DolarAPI All', url: DOLARAPI_ALL_URL },
      { name: 'BCRA Oficial', url: BCRA_OFFICIAL_URL }
    ]
    
    apis.map do |api|
      begin
        options = { timeout: 5 }
        options[:verify] = false if api[:name] == 'BCRA Oficial'
        response = get(api[:url], options)
        {
          name: api[:name],
          status: response.success? ? 'online' : 'error',
          code: response.code
        }
      rescue StandardError => e
        {
          name: api[:name],
          status: 'offline',
          error: e.message
        }
      end
    end
  end
end
