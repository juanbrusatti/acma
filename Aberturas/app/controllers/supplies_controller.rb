class SuppliesController < ApplicationController
  before_action :set_supply, only: %i[ show edit update destroy ]

  # GET /supplies or /supplies.json
  def index
    @supplies = Supply.all
  end

  # GET /supplies/1 or /supplies/1.json
  def show
  end

  # GET /supplies/new
  def new
    @supply = Supply.new
  end

  # GET /supplies/1/edit
  def edit
  end

  # POST /supplies or /supplies.json
  def create
    @supply = Supply.new(supply_params)

    respond_to do |format|
      if @supply.save
        format.html { redirect_to @supply, notice: "Insumo was successfully created." }
        format.json { render :show, status: :created, location: @supply }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /supplies/1 or /supplies/1.json
  def update
    respond_to do |format|
      if @supply.update(supply_params)
        format.html { redirect_to supplies_path, notice: "Precio de insumo actualizado correctamente." }
        format.json { render :show, status: :ok, location: @supply }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /supplies/1 or /supplies/1.json
  def destroy
    @supply.destroy!

    respond_to do |format|
      format.html { redirect_to supplies_path, status: :see_other, notice: "Insumo was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_supply
      @supply = Supply.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def supply_params
      params.require(:supply).permit(:name, :price)
    end
end
