class ScrapsController < ApplicationController
  before_action :set_scrap, only: %i[ show edit update destroy ]

  # GET /scraps or /scraps.json
  def index
    @scraps = Scrap.all
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: @scraps }
    end
  end

  # GET /scraps/list
  def list
    @scraps = Scrap.all
  end

  # GET /scraps/1 or /scraps/1.json
  def show
  end

  # GET /scraps/new
  def new
    @scrap = Scrap.new
    last_ref = Scrap.maximum("CAST(SUBSTRING(ref_number, 5) AS INTEGER)") || 0
    @scrap.ref_number = "REF-" + "%03d" % (last_ref + 1)
  end

  # GET /scraps/1/edit
  def edit
  end

  # POST /scraps or /scraps.json
  def create
    @scrap = Scrap.new(scrap_params)

    respond_to do |format|
      if @scrap.save
        format.html { redirect_to glassplates_path, notice: "El retazo fue creado exitosamente." }
        format.json { render :show, status: :created, location: @scrap }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @scrap.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scraps/1 or /scraps/1.json
  def update
    respond_to do |format|
      if @scrap.update(scrap_params)
        format.html { redirect_to glassplates_path, notice: "El retazo fue actualizado exitosamente." }
        format.json { render :show, status: :ok, location: @scrap }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @scrap.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scraps/1 or /scraps/1.json
  def destroy
    @scrap.destroy!

    respond_to do |format|
      format.html { redirect_to scraps_path, status: :see_other, notice: "Scrap was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_scrap
      @scrap = Scrap.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def scrap_params
      params.expect(scrap: [ :ref_number, :scrap_type, :color, :thickness, :width, :height, :output_work, :status ])
    end
end
