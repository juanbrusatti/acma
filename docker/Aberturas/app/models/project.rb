class Project < ApplicationRecord
  # Associations
  has_many :dvhs, dependent: :destroy
  has_many :glasscuttings, dependent: :destroy

  # Nested attributes for form handling
  accepts_nested_attributes_for :glasscuttings, allow_destroy: true
  accepts_nested_attributes_for :dvhs, allow_destroy: true

  # Validations
  validates :name, presence: { message: "El nombre del proyecto no puede estar en blanco", full_message: false }, length: { maximum: 100, message: "no puede tener más de %{count} caracteres", full_message: false }
  validates :phone, presence: { message: "El teléfono no puede estar en blanco", full_message: false }
   # validates :description, presence: true, length: { minimum: 0, maximum: 500 }
  validates :status, presence: { message: "no puede estar en blanco", full_message: false }, inclusion: {
    in: %w[Pendiente En\ Proceso Terminado],
    message: "debe ser uno de: Pendiente, En Proceso, Terminado"
  }
  # validates :delivery_date, presence: true, comparison: { greater_than: -> { Date.current } }, if: -> { status == "Pendiente" }

  # Scopes for filtering projects by status and dates
  scope :active, -> { where(status: "En Proceso") }
  scope :completed, -> { where(status: "Terminado") }
  scope :pending, -> { where(status: "Pendiente") }
  scope :overdue, -> { where("delivery_date < ?", Date.current) }
  scope :upcoming, -> { where("delivery_date >= ?", Date.current) }

  # Instance methods

  # Check if project is overdue (delivery date passed and not completed)
  def overdue?
    delivery_date.present? && delivery_date < Date.current && status != "Terminado"
  end

  # Calculate days until delivery date
  def days_until_delivery
    return nil unless delivery_date.present?
    (delivery_date - Date.current).to_i
  end

  # Calculate subtotal (use saved price_without_iva or fallback to calculation)
  def subtotal
    # If we have a saved price without IVA, use it directly
    return price_without_iva if price_without_iva.present?

    # Fallback calculation - handle nil prices gracefully
    glasscutting_total = glasscuttings.sum { |g| g.price || 0 }
    dvh_total = dvhs.sum { |d| d.price || 0 }
    glasscutting_total + dvh_total
  end

  # Calculate IVA (21% of subtotal)
  def iva
    subtotal * 0.21
  end

  # Calculate total including IVA
  def total
    subtotal + iva
  end

  # Alias methods for clarity
  def precio_sin_iva
    subtotal
  end

  # Return color class for status display in views
  def status_color
    case status
    when "Terminado"
      "green"
    when "En Proceso"
      "blue"
    when "Pendiente"
      "yellow"
    else
      "gray"
    end
  end

  # Return pieces that can be converted from FLO to LAM
  # Conditions: FLO, 5mm, INC, Aluminio, less than 1800x500
  def convertible_pieces
    result = []

    # Search glasscuttings that meet the conditions
    glasscuttings.each do |cut|
      if is_convertible?(cut.glass_type, cut.thickness, cut.color, cut.type_opening, cut.width, cut.height)
        result << {
          type: 'glasscutting',
          id: cut.id,
          typology: cut.typology,
          width: cut.width,
          height: cut.height,
          glass_type: cut.glass_type,
          thickness: cut.thickness,
          color: cut.color,
          type_opening: cut.type_opening
        }
      end
    end

    # Search DVHs that have at least one glass that meets the conditions
    dvhs.each do |dvh|
      # Check first glass of the DVH
      glass1_convertible = is_convertible?(
        dvh.glasscutting1_type,
        dvh.glasscutting1_thickness,
        dvh.glasscutting1_color,
        dvh.type_opening,
        dvh.width,
        dvh.height
      )

      # Check second glass of the DVH
      glass2_convertible = is_convertible?(
        dvh.glasscutting2_type,
        dvh.glasscutting2_thickness,
        dvh.glasscutting2_color,
        dvh.type_opening,
        dvh.width,
        dvh.height
      )

      # If at least one of the glasses is convertible, add the DVH
      if glass1_convertible || glass2_convertible
        result << {
          type: 'dvh',
          id: dvh.id,
          typology: dvh.typology,
          width: dvh.width,
          height: dvh.height,
          glass1_type: dvh.glasscutting1_type,
          glass1_thickness: dvh.glasscutting1_thickness,
          glass1_color: dvh.glasscutting1_color,
          glass2_type: dvh.glasscutting2_type,
          glass2_thickness: dvh.glasscutting2_thickness,
          glass2_color: dvh.glasscutting2_color,
          type_opening: dvh.type_opening,
          glass1_convertible: glass1_convertible,
          glass2_convertible: glass2_convertible
        }
      end
    end

    result
  end

  private

  # Checks if a glass meets the conditions to be convertible from FLO to LAM
  def is_convertible?(glass_type, thickness, color, type_opening, width, height)
    # Must be FLO, 5mm, INC, Aluminio
    return false unless glass_type == "FLO"
    return false unless thickness == "5mm"
    return false unless color == "INC"
    return false unless type_opening == "Aluminio"

    # Measurements must be less than 1800x500 (in any orientation)
    (width < 1800 && height < 500) || (width < 500 && height < 1800)
  end

end
