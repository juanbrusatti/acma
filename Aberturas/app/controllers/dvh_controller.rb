class DvhsController < ApplicationController
    before_action :set_project, only: [:create]
  
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
        :camera, :location, :height, :width,
        :glassplate1_type, :glassplate1_thickness, :glassplate1_color,
        :glassplate2_type, :glassplate2_thickness, :glassplate2_color,
        :gas_type
      )
    end
  end
  