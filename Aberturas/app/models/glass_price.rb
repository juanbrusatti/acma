class GlassPrice < ApplicationRecord
  TYPES = {
    "LAM" => [
      { thickness: "3+3", colors: ["INC", "BLS"] },
      { thickness: "4+4", colors: ["INC"] },
      { thickness: "5+5", colors: ["INC"] }
    ],
    "FLO" => [
      { thickness: "5mm", colors: ["GRS", "BRC", "INC"] }
    ],
    "COL" => [
      { thickness: "4+4", colors: ["STB", "STG", "NTR"] }
    ]
  }

  # Callbacks para calcular automáticamente el precio de venta
  before_save :calculate_selling_price_from_percentage

  def self.combinations_possible
    TYPES.flat_map do |glass_type, thickness_color_combinations|
      thickness_color_combinations.flat_map do |combination|
        combination[:colors].map do |color|
          { glass_type: glass_type, thickness: combination[:thickness], color: color }
        end
      end
    end
  end

  def self.find_or_build_by_comb(glass_type:, thickness:, color:)
    find_or_initialize_by(glass_type: glass_type, thickness: thickness, color: color)
  end

  private

  def calculate_selling_price_from_percentage
    if buying_price.present? && percentage.present?
      self.selling_price = buying_price * (1 + percentage / 100.0)
    end
  end
end
