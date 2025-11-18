class ScrapsController < ApplicationController
  include ScrapsHelper
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
    @scrap.ref_number = define_number_ref(@scrap.scrap_type, @scrap.thickness, @scrap.color)

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

  # POST /scraps/import
  def import
    unless params[:file].present?
      respond_to do |format|
        format.html { redirect_to glassplates_path(tab: 'sobrantes'), alert: "Por favor selecciona un archivo." }
        format.json { render json: { success: false, errors: ["Por favor selecciona un archivo."] }, status: :unprocessable_entity }
      end
      return
    end

    # Validar extensión del archivo
    unless params[:file].original_filename.match?(/\.(xlsx|xls)$/i)
      respond_to do |format|
        format.html { redirect_to glassplates_path(tab: 'sobrantes'), alert: "El archivo debe ser un Excel (.xlsx o .xls)." }
        format.json { render json: { success: false, errors: ["El archivo debe ser un Excel (.xlsx o .xls)."] }, status: :unprocessable_entity }
      end
      return
    end

    # Guardar archivo temporalmente
    uploaded_file = params[:file]
    temp_file = Tempfile.new(['scrap_import', File.extname(uploaded_file.original_filename)])
    temp_file.binmode
    
    # Copiar el contenido del archivo subido al archivo temporal
    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
    temp_file.write(uploaded_file.read)
    temp_file.rewind

    # Procesar el archivo
    importer = ScrapImporter.new(temp_file.path)
    result = importer.import

    # Limpiar archivo temporal
    temp_file.close
    temp_file.unlink

    respond_to do |format|
      if result[:success]
        format.html do
          redirect_to glassplates_path(tab: 'sobrantes'),
                      notice: "Importación exitosa: #{result[:success_count]} sobrantes importados de #{result[:total_rows]} filas procesadas."
        end
        format.json { render json: { success: true, success_count: result[:success_count], total_rows: result[:total_rows] }, status: :ok }
      else
        message = "Importación finalizada con errores. #{result[:success_count]} de #{result[:total_rows]} filas se importaron correctamente."
        format.html { redirect_to glassplates_path(tab: 'sobrantes'), alert: message }
        format.json { render json: { success: false, errors: result[:errors], success_count: result[:success_count] }, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scrap
      @scrap = Scrap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def scrap_params
      params.require(:scrap).permit(:scrap_type, :color, :thickness, :width, :height, :input_work)
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
