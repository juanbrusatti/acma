class PrecioVidriosController < ApplicationController
  before_action :set_precio_vidrio, only: %i[ show edit update destroy ]

  # GET /precio_vidrios or /precio_vidrios.json
  def index
    @precio_vidrios = PrecioVidrio.all
  end

  # GET /precio_vidrios/1 or /precio_vidrios/1.json
  def show
  end

  # GET /precio_vidrios/new
  def new
    @precio_vidrio = PrecioVidrio.new
  end

  # GET /precio_vidrios/1/edit
  def edit
  end

  # POST /precio_vidrios or /precio_vidrios.json
  def create
    @precio_vidrio = PrecioVidrio.new(precio_vidrio_params)

    respond_to do |format|
      if @precio_vidrio.save
        format.html { redirect_to @precio_vidrio, notice: "Precio vidrio was successfully created." }
        format.json { render :show, status: :created, location: @precio_vidrio }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @precio_vidrio.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /precio_vidrios/1 or /precio_vidrios/1.json
  def update
    respond_to do |format|
      if @precio_vidrio.update(precio_vidrio_params)
        format.html { redirect_to @precio_vidrio, notice: "Precio vidrio was successfully updated." }
        format.json { render :show, status: :ok, location: @precio_vidrio }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @precio_vidrio.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /precio_vidrios/1 or /precio_vidrios/1.json
  def destroy
    @precio_vidrio.destroy!

    respond_to do |format|
      format.html { redirect_to precio_vidrios_path, status: :see_other, notice: "Precio vidrio was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_precio_vidrio
      @precio_vidrio = PrecioVidrio.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def precio_vidrio_params
      params.expect(precio_vidrio: [ :alto, :ancho, :color, :tipo, :grosor, :precio ])
    end
end
