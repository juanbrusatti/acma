class Glassplate < ApplicationRecord
  # Color validation
  validates :color, presence: true
  validates :color, inclusion: {
    in: [ "transparente", "gris", "azul", "verde", "negro" ],
    message: "debe ser uno de: transparente, bronce, gris, azul, verde, negro"
  }


  # Type validation
  validates :type, presence: true
  validates :type, inclusion: {
    in: [ "simple", "doble", "templado", "laminado", "reflectivo" ],
    message: "debe ser uno de: simple, doble, templado, laminado, reflectivo"
  }

  # Validations for width and height
  validates :width, :height, presence: true, numericality: { greater_than: 0 }
end
