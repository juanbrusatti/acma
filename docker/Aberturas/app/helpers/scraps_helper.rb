module ScrapsHelper
  def define_number_ref(type, thickness, color)
    last_scrap = Scrap.where(scrap_type: type, thickness: thickness, color: color).order(ref_number: :desc).first
    if last_scrap
      return last_scrap.ref_number + 1
    else
      return 1
    end
  end
end
