class GlassPricesController < ApplicationController
  before_action :set_glass_price, only: %i[ show edit update destroy ]

  # GET /glass_prices or /glass_prices.json
  def index
    @combinations = GlassPrice.combinations_possible.map do |comb|
      record = GlassPrice.find_or_initialize_by(comb)
      if record.new_record?
        record.save(validate: false)
      end
      record
    end
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
