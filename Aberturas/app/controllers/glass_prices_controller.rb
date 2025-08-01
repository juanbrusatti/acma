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
      # Set the MEP rate in app config
      AppConfig.set_mep_rate(mep_rate)
      
      # Update all supplies with new peso prices
      Supply.all.find_each do |supply|
        supply.update_peso_price_from_usd!(mep_rate)
      end
      
      respond_to do |format|
        format.html { redirect_to glass_prices_path, notice: "Dólar MEP actualizado correctamente." }
        format.json { render json: { success: true, message: "Dólar MEP actualizado correctamente." } }
        format.turbo_stream { 
          flash.now[:notice] = "Dólar MEP actualizado correctamente."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("supplies_table", partial: "supplies_table", locals: { supplies: Supply.all })
          ]
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to glass_prices_path, alert: "El valor del dólar MEP debe ser mayor a 0." }
        format.json { render json: { success: false, message: "El valor del dólar MEP debe ser mayor a 0." } }
        format.turbo_stream {
          flash.now[:alert] = "El valor del dólar MEP debe ser mayor a 0."
          render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash")
        }
      end
    end
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
