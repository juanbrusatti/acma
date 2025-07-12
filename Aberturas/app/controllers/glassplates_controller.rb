class GlassplatesController < ApplicationController
  before_action :set_glassplate, only: %i[ show edit update destroy ]

  # GET /glassplates or /glassplates.json
  def index
    @glassplates = Glassplate.all
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
        format.html { redirect_to @glassplate, notice: "Glassplate was successfully created." }
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
        format.html { redirect_to @glassplate, notice: "Glassplate was successfully updated." }
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
      format.html { redirect_to glassplates_path, status: :see_other, notice: "Glassplate was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_glassplate
      @glassplate = Glassplate.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def glassplate_params
      params.expect(glassplate: [ :width, :height, :color, :type ])
    end
end
