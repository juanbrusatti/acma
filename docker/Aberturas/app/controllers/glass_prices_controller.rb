class GlassPricesController < ApplicationController
  before_action :set_glass_price, only: %i[ show edit update destroy ]

  # GET /glass_prices or /glass_prices.json
  def index
    @combinations = helpers.build_glass_price_combinations
  end

  # GET /glass_prices/1 or /glass_prices/1.json
  def show
  end

  # GET /glass_prices/new
  def new
    @glass_price = GlassPrice.new
  end

  # GET /glass_prices/1/edit
  def edit
  end

  # POST /glass_prices or /glass_prices.json
  def create
    @glass_price = GlassPrice.new(glass_price_params)

    respond_to do |format|
      if @glass_price.save
        format.html { redirect_to @glass_price, notice: "Precio vidrio was successfully created." }
        format.json { render :show, status: :created, location: @glass_price }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @glass_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /glass_prices/1 or /glass_prices/1.json
  def update
    respond_to do |format|
      if @glass_price.update(glass_price_params)
        format.html { redirect_to glass_prices_path, notice: "Precio actualizado correctamente." }
        format.json { render :show, status: :ok, location: @glass_price }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @glass_price.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /glass_prices/1 or /glass_prices/1.json
  def destroy
    @glass_price.destroy!

    respond_to do |format|
      format.html { redirect_to glass_prices_path, status: :see_other, notice: "Precio vidrio was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # PATCH /glass_prices/update_all_percentages
  def update_all_percentages
    percentage = params[:percentage].to_f
    
    if percentage >= 0
      # update all glass prices with a buying price greater than 0
      # and recalculate their selling prices based on the new percentage
      glass_prices_with_buying_price = GlassPrice.where.not(buying_price: [nil, 0])
      
      glass_prices_with_buying_price.find_each do |glass_price|
        glass_price.update!(
          percentage: percentage,
          selling_price: glass_price.buying_price * (1 + percentage / 100.0)
        )
      end
      
      respond_to do |format|
        format.html { redirect_to glass_prices_path, notice: "Porcentaje general actualizado correctamente." }
        format.json { render json: { success: true, message: "Porcentaje general actualizado correctamente." } }
        format.turbo_stream { 
          flash.now[:notice] = "Porcentaje general actualizado correctamente."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("glass_prices_table", partial: "glass_prices_table", locals: { combinations: helpers.build_glass_price_combinations })
          ]
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "El porcentaje debe ser mayor o igual a 0." }
        format.json { render json: { success: false, message: "El porcentaje debe ser mayor o igual a 0." } }
        format.turbo_stream {
          flash.now[:alert] = "El porcentaje debe ser mayor o igual a 0."
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
        }
      end
    end
  end

  # PATCH /glass_prices/update_all_supplies_mep
  def update_all_supplies_mep
    mep_rate = params[:mep_rate].to_f
    
    if mep_rate > 0
      # Set the official rate in app config (usando el nuevo sistema)
      AppConfig.set_official_rate(mep_rate)
      
      # Update all supplies with new peso prices
      Supply.all.find_each do |supply|
        supply.update_peso_price_from_usd!(mep_rate)
      end
      
      # Calculate and save innertube prices based on current supply prices
      AppConfig.update_all_innertube_prices
      
      respond_to do |format|
        format.html { redirect_to glass_prices_path, notice: "Dólar oficial actualizado correctamente." }
        format.json { render json: { success: true, message: "Dólar oficial actualizado correctamente." } }
        format.turbo_stream { 
          flash.now[:notice] = "Dólar oficial actualizado correctamente."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("supplies_table", partial: "supplies_table", locals: { supplies: Supply.all })
          ]
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "El valor del dólar oficial debe ser mayor a 0." }
        format.json { render json: { success: false, message: "El valor del dólar oficial debe ser mayor a 0." } }
        format.turbo_stream {
          flash.now[:alert] = "El valor del dólar oficial debe ser mayor a 0."
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
        }
      end
    end
  end

  # POST /glass_prices/update_mep_from_api
  def update_mep_from_api
    begin
      # Obtener cotización desde la API
      api_result = OfficialRateApiService.get_current_official_rate
      
      if api_result[:success]
        rate = api_result[:rate]
        source = api_result[:source]
        
        # Guardar en el historial
        OfficialRateHistory.create_or_update_rate(
          date: Date.current,
          rate: rate,
          source: source,
          notes: "Actualización manual desde API",
          is_manual: true
        )
        
        # Actualizar configuración y precios
        AppConfig.set_official_rate(rate)
        
        Supply.all.find_each do |supply|
          supply.update_peso_price_from_usd!(rate)
        end
        
        AppConfig.update_all_innertube_prices
        
        respond_to do |format|
          format.html { redirect_to glass_prices_path, notice: "Dólar oficial actualizado desde API: $#{rate} (#{source})" }
          format.json { render json: { success: true, message: "Dólar oficial actualizado desde API: $#{rate}", rate: rate, source: source } }
          format.turbo_stream { 
            flash.now[:notice] = "Dólar oficial actualizado desde API: $#{rate} (#{source})"
            render turbo_stream: [
              turbo_stream.replace("flash", partial: "shared/flash"),
              turbo_stream.replace("supplies_table", partial: "supplies_table", locals: { supplies: Supply.all })
            ]
          }
        end
      else
        respond_to do |format|
          format.html { redirect_to glass_prices_path, alert: "Error al obtener cotización: #{api_result[:error]}" }
          format.json { render json: { success: false, message: api_result[:error] } }
          format.turbo_stream {
            flash.now[:alert] = "Error al obtener cotización: #{api_result[:error]}"
            render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
          }
        end
      end
    rescue StandardError => e
      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "Error inesperado: #{e.message}" }
        format.json { render json: { success: false, message: "Error inesperado: #{e.message}" } }
        format.turbo_stream {
          flash.now[:alert] = "Error inesperado: #{e.message}"
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
        }
      end
    end
  end

  # GET /glass_prices/mep_history
  def mep_history
    @history = OfficialRateHistory.recent.limit(30)
    @statistics = OfficialRateHistory.statistics(days: 30)
    @current_rate = AppConfig.current_official_rate
    @change_percentage = AppConfig.official_rate_change_percentage
    render 'official_history'
  end

  # Nuevos métodos para dólar oficial
  # PATCH /glass_prices/update_all_supplies_official
  def update_all_supplies_official
    official_rate = params[:official_rate].to_f
    
    if official_rate > 0
      # Set the official rate in app config
      AppConfig.set_official_rate(official_rate)
      
      # Update all supplies with new peso prices
      Supply.all.find_each do |supply|
        supply.update_peso_price_from_usd!(official_rate)
      end
      
      # Calculate and save innertube prices based on current supply prices
      AppConfig.update_all_innertube_prices
      
      respond_to do |format|
        format.html { redirect_to glass_prices_path, notice: "Dólar oficial actualizado correctamente." }
        format.json { render json: { success: true, message: "Dólar oficial actualizado correctamente." } }
        format.turbo_stream { 
          flash.now[:notice] = "Dólar oficial actualizado correctamente."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("supplies_table", partial: "supplies_table", locals: { supplies: Supply.all })
          ]
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "El valor del dólar oficial debe ser mayor a 0." }
        format.json { render json: { success: false, message: "El valor del dólar oficial debe ser mayor a 0." } }
        format.turbo_stream {
          flash.now[:alert] = "El valor del dólar oficial debe ser mayor a 0."
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
        }
      end
    end
  end

  # POST /glass_prices/update_official_from_api
  def update_official_from_api
    begin
      # Obtener cotización desde la API
      api_result = OfficialRateApiService.get_current_official_rate
      
      if api_result[:success]
        rate = api_result[:rate]
        source = api_result[:source]
        
        # Guardar en el historial
        OfficialRateHistory.create_or_update_rate(
          date: Date.current,
          rate: rate,
          source: source,
          notes: "Actualización manual desde API",
          is_manual: true
        )
        
        # Actualizar configuración y precios
        AppConfig.set_official_rate(rate)
        
        Supply.all.find_each do |supply|
          supply.update_peso_price_from_usd!(rate)
        end
        
        AppConfig.update_all_innertube_prices
        
        respond_to do |format|
          format.html { redirect_to glass_prices_path, notice: "Dólar oficial actualizado desde API: $#{rate} (#{source})" }
          format.json { render json: { success: true, message: "Dólar oficial actualizado desde API: $#{rate}", rate: rate, source: source } }
          format.turbo_stream { 
            flash.now[:notice] = "Dólar oficial actualizado desde API: $#{rate} (#{source})"
            render turbo_stream: [
              turbo_stream.replace("flash", partial: "shared/flash"),
              turbo_stream.replace("supplies_table", partial: "supplies_table", locals: { supplies: Supply.all })
            ]
          }
        end
      else
        respond_to do |format|
          format.html { redirect_to glass_prices_path, alert: "Error al obtener cotización: #{api_result[:error]}" }
          format.json { render json: { success: false, message: api_result[:error] } }
          format.turbo_stream {
            flash.now[:alert] = "Error al obtener cotización: #{api_result[:error]}"
            render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
          }
        end
      end
    rescue StandardError => e
      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "Error inesperado: #{e.message}" }
        format.json { render json: { success: false, message: "Error inesperado: #{e.message}" } }
        format.turbo_stream {
          flash.now[:alert] = "Error inesperado: #{e.message}"
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
        }
      end
    end
  end

  # GET /glass_prices/official_history
  def official_history
    @history = OfficialRateHistory.recent.limit(30)
    @statistics = OfficialRateHistory.statistics(days: 30)
    @current_rate = AppConfig.current_official_rate
    @change_percentage = AppConfig.official_rate_change_percentage
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_glass_price
      @glass_price = GlassPrice.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def glass_price_params
      params.require(:glass_price).permit(:glass_type, :thickness, :color, :buying_price, :selling_price, :percentage)
    end
end
