class DvhsController < ApplicationController
    before_action :set_project, only: [ :create ]

    def create
      @dvh = @project.dvhs.new(dvh_params)

      if @dvh.save
        redirect_to edit_project_path(@project), notice: "DVH agregado correctamente."
      else
        redirect_to edit_project_path(@project), alert: "Error al agregar DVH."
      end
    end

    private

    def set_project
      @project = Project.find(params[:project_id])
    end

    def dvh_params
      params.require(:dvh).permit(
        :innertube, :location, :height, :width,
        :glasscutting1_type, :glasscutting1_thickness, :glasscutting1_color,
        :glasscutting2_type, :glasscutting2_thickness, :glasscutting2_color,
        :price
      )
    end
end
