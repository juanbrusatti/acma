class Supply < ApplicationRecord
  BASICS = ["Tamiz", "Hotmelt", "Cinta"]

  def self.basics
    BASICS.map do |name|
      find_or_create_by(name: name)
    end
  end
end
