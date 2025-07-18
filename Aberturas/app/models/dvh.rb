class Dvh < ApplicationRecord
  belongs_to :project
  has_many :glasscuttings, dependent: :nullify

  # Si usás glassplates como modelos separados, agregalos también
  # belongs_to :glassplate1, class_name: "Glassplate", optional: true
  # belongs_to :glassplate2, class_name: "Glassplate", optional: true

  validates :innertube, :location, :height, :width, presence: true
  validates :height, :width, numericality: { greater_than: 0 }
end
