class GlassplatesController < ApplicationController
  before_action :set_glassplate, only: %i[ show edit update destroy ]

  # GET /glassplates or /glassplates.json
  def index
    @glassplates = Glassplate.all
    @scraps = Scrap.all
  end

  # GET /glassplates/1 or /glassplates/1.json
  def show
  end

  # GET /glassplates/new
  def new
    @glassplate = Glassplate.new
  end

  # GET /glassplates/1/edit
  def edit
  end

  # POST /glassplates or /glassplates.json
  def create
    @glassplate = Glassplate.new(glassplate_params)

    respond_to do |format|
      if @glassplate.save
        format.html { redirect_to glassplates_path, notice: "Material agregado exitosamente al stock." }
        format.json { render :show, status: :created, location: @glassplate }
      else
        # Filtrar mensajes de error para eliminar redundancias
        filter_duplicate_errors
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @glassplate.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /glassplates/1 or /glassplates/1.json
  def update
    respond_to do |format|
      if @glassplate.update(glassplate_params)
        format.html { redirect_to glassplates_path, notice: "Material actualizado exitosamente." }
        format.json { render json: { success: true, quantity: @glassplate.quantity }, status: :ok }
      else
        # Filtrar mensajes de error para eliminar redundancias
        filter_duplicate_errors
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @glassplate.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /glassplates/1 or /glassplates/1.json
  def destroy
    @glassplate.destroy!

    respond_to do |format|
      format.html { redirect_to glassplates_path, status: :see_other, notice: "Plancha eliminada exitosamente de la base de datos." }
      format.json { head :no_content }
    end
  end

  private

  def set_glassplate
    @glassplate = Glassplate.find(params[:id])
  end

  def glassplate_params
    params.require(:glassplate).permit(:width, :height, :color, :glass_type, :thickness, :quantity)
  end
  
  private
  
  def filter_duplicate_errors
    # Eliminar mensajes de error de presencia si hay otros errores para el mismo atributo
    @glassplate.errors.messages.each do |attribute, messages|
      if messages.size > 1
        # Mantener solo el último mensaje de error para cada atributo
        @glassplate.errors.delete(attribute)
        @glassplate.errors.add(attribute, messages.last)
      end
    end
  end

end
