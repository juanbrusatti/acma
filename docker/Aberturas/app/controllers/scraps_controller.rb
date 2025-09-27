class ScrapsController < ApplicationController
  before_action :set_scrap, only: %i[ edit update destroy ]

  # GET /scraps/new
  def new
    @scrap = Scrap.new
  end

  # GET /scraps/1/edit
  def edit
  end

  # POST /scraps or /scraps.json
  def create
    @scrap = Scrap.new(scrap_params)

    respond_to do |format|
      if @scrap.save
        format.html { redirect_to glassplates_path, notice: "Retazo agregado exitosamente al stock." }
        format.json { render json: { status: 'success', message: 'Retazo agregado exitosamente.', scrap: @scrap }, status: :created }
      else
        # Filtrar mensajes de error para eliminar redundancias
        filter_duplicate_errors
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { status: 'error', errors: @scrap.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scraps/1 or /scraps/1.json
  def update
    respond_to do |format|
      if @scrap.update(scrap_params)
        format.html { redirect_to glassplates_path, notice: "Retazo actualizado exitosamente." }
        format.json { render json: { status: 'success', message: 'Retazo actualizado exitosamente.', scrap: @scrap } }
      else
        # Filtrar mensajes de error para eliminar redundancias
        filter_duplicate_errors
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { status: 'error', errors: @scrap.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scraps/1 or /scraps/1.json
  def destroy
    @scrap.destroy!

    respond_to do |format|
      format.html { redirect_to glassplates_path, status: :see_other, notice: "Retazo eliminado exitosamente de la base de datos." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scrap
      @scrap = Scrap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def scrap_params
      params.require(:scrap).permit(:ref_number, :scrap_type, :color, :thickness, :width, :height, :output_work, :status)
    end
    
    def filter_duplicate_errors
      # Eliminar mensajes de error de presencia si hay otros errores para el mismo atributo
      @scrap.errors.messages.each do |attribute, messages|
        if messages.size > 1
          # Mantener solo el último mensaje de error para cada atributo
          @scrap.errors.delete(attribute)
          @scrap.errors.add(attribute, messages.last)
        end
      end
    end
end
