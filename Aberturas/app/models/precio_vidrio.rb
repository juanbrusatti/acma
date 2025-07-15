class PrecioVidrio < ApplicationRecord
  TIPOS = {
    "Laminado" => {
      grosores: ["3+3", "4+4", "5+5"],
      colores: ["incoloro", "esmerilado"]
    },
    "Float" => {
      grosores: ["5mm"],
      colores: ["incoloro", "gris", "bronce"]
    },
    "Cool lite" => {
      grosores: ["4+4"],
      colores: ["incoloro"]
    }
  }

  def self.combinaciones_posibles
    TIPOS.flat_map do |tipo, opciones|
      opciones[:grosores].product(opciones[:colores]).map do |grosor, color|
        { tipo: tipo, grosor: grosor, color: color }
      end
    end
  end

  def self.find_or_build_by_comb(tipo:, grosor:, color:)
    find_or_initialize_by(tipo: tipo, grosor: grosor, color: color)
  end
end
