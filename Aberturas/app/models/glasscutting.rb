class Glasscutting < ApplicationRecord
  belongs_to :project
  belongs_to :dvh, optional: true
  belongs_to :glassplate, optional: true

  validates :height, :width, presence: true, numericality: { greater_than: 0 }
  validates :glass_type, :thickness, :color, :location, presence: true
end
