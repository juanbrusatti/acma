class GlassplatesController < ApplicationController
  before_action :set_glassplate, only: %i[ show edit update destroy ]

  # GET /glassplates or /glassplates.json
  def index
    load_stock_data
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
        format.json { render :show, status: :ok, location: @glassplate }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @glassplate.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /glassplates/1 or /glassplates/1.json
  def destroy
    @glassplate.destroy!

    respond_to do |format|
      format.html { redirect_to glassplates_path, status: :see_other, notice: "Material eliminado exitosamente." }
      format.json { head :no_content }
    end
  end

  private

  def load_stock_data
    @complete_sheets = Glassplate.complete_sheets
    @scraps = Glassplate.scraps
    @stock_summary = calculate_stock_summary
  end

  def calculate_stock_summary
    {
      total_sheets: Glassplate.complete_sheets.sum(:quantity),
      total_scraps: Glassplate.scraps.count,
      available_scraps: Glassplate.scraps.available.count,
      reserved_scraps: Glassplate.scraps.reserved.count
    }
  end

  def set_glassplate
    @glassplate = Glassplate.find(params[:id])
  end

  def glassplate_params
    params.require(:glassplate).permit(:width, :height, :color, :glass_type, :thickness,
                                      :standard_measures, :quantity, :location, :status, :is_scrap)
  end
end
