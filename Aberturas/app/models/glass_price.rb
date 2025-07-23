class GlassPrice < ApplicationRecord
  TYPES = {
    "LAM" => {
      thicknesses: ["3+3", "4+4", "5+5"],
      colors: ["INC", "esmerilado"]
    },
    "FLO" => {
      thicknesses: ["5mm"],
      colors: ["INC", "gris", "bronce"]
    },
    "COL" => {
      thicknesses: ["4+4"],
      colors: ["INC"]
    }
  }

  def self.combinations_possible
    TYPES.flat_map do |glass_type, options|
      options[:thicknesses].product(options[:colors]).map do |thickness, color|
        { glass_type: glass_type, thickness: thickness, color: color }
      end
    end
  end

  def self.find_or_build_by_comb(glass_type:, thickness:, color:)
    find_or_initialize_by(glass_type: glass_type, thickness: thickness, color: color)
  end
end
