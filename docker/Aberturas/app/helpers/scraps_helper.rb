module ScrapsHelper
  def define_number_ref(type, thickness, color)
    last_scrap = Scrap.where(scrap_type: type, thickness: thickness, color: color).order(ref_number: :desc).first
    if last_scrap
      last_scrap_ref_number_int = last_scrap.ref_number.to_i
      last_scrap_ref_number_int += 1
      return last_scrap_ref_number_int.to_s
    else
      return "1"
    end
  end
end
