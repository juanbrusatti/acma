class InsumosController < ApplicationController
  before_action :set_insumo, only: %i[ show edit update destroy ]

  # GET /insumos or /insumos.json
  def index
    @insumos = Insumo.all
  end

  # GET /insumos/1 or /insumos/1.json
  def show
  end

  # GET /insumos/new
  def new
    @insumo = Insumo.new
  end

  # GET /insumos/1/edit
  def edit
  end

  # POST /insumos or /insumos.json
  def create
    @insumo = Insumo.new(insumo_params)

    respond_to do |format|
      if @insumo.save
        format.html { redirect_to @insumo, notice: "Insumo was successfully created." }
        format.json { render :show, status: :created, location: @insumo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @insumo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /insumos/1 or /insumos/1.json
  def update
    respond_to do |format|
      if @insumo.update(insumo_params)
        format.html { redirect_to insumos_path, notice: "Precio de insumo actualizado correctamente." }
        format.json { render :show, status: :ok, location: @insumo }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @insumo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /insumos/1 or /insumos/1.json
  def destroy
    @insumo.destroy!

    respond_to do |format|
      format.html { redirect_to insumos_path, status: :see_other, notice: "Insumo was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_insumo
      @insumo = Insumo.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def insumo_params
      params.expect(insumo: [ :nombre, :precio ])
    end
end
