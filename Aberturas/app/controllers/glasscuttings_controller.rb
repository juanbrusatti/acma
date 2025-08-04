class GlasscuttingsController < ApplicationController
    before_action :set_project, only: [ :create ]

    def create
      @glasscutting = @project.glasscuttings.new(glasscutting_params)

      if @glasscutting.save
        respond_to do |format|
          format.html { redirect_to edit_project_path(@project), notice: "Vidrio simple agregado correctamente." }
          format.json { render json: @glasscutting, status: :created }
        end
      else
        respond_to do |format|
          format.html { redirect_to edit_project_path(@project), alert: "Error al agregar vidrio simple." }
          format.json { render json: @glasscutting.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_project
      @project = Project.find(params[:project_id])
    end

    def glasscutting_params
      params.require(:glasscutting).permit(:glass_type, :thickness, :height, :width, :color, :typology, :price)
    end
end
