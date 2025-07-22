class GlassPrice < ApplicationRecord
  TYPES = {
    "Laminated" => {
      thicknesses: ["3+3", "4+4", "5+5"],
      colors: ["incolor", "esmerilado"]
    },
    "Float" => {
      thicknesses: ["5mm"],
      colors: ["incolor", "gris", "bronce"]
    },
    "Cool lite" => {
      thicknesses: ["4+4"],
      colors: ["incolor"]
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
