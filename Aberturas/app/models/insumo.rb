class Insumo < ApplicationRecord
  BASICOS = ["Tamiz", "Hotmelt", "Cinta"]

  def self.basicos
    BASICOS.map do |nombre|
      find_or_create_by(nombre: nombre)
    end
  end
end
