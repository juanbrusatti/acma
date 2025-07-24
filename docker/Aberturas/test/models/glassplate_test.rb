require "test_helper"

class GlassplateTest < ActiveSupport::TestCase
  def setup
    @glassplate = Glassplate.new(
      width: 600,
      height: 400,
      color: "transparente",
      glass_type: "Incoloro",
      thickness: "4mm",
      standard_measures: "600x400mm",
      quantity: 5,
      location: "Estante A",
      status: "disponible",
      is_scrap: false
    )
  end

  test "should be valid with valid attributes" do
    assert @glassplate.valid?
  end

  test "should require width" do
    @glassplate.width = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:width], "can't be blank"
  end

  test "should require height" do
    @glassplate.height = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:height], "can't be blank"
  end

  test "should require color" do
    @glassplate.color = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:color], "can't be blank"
  end

  test "should require glass_type" do
    @glassplate.glass_type = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:glass_type], "can't be blank"
  end

  test "should require thickness" do
    @glassplate.thickness = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:thickness], "can't be blank"
  end

  test "should require quantity" do
    @glassplate.quantity = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:quantity], "can't be blank"
  end

  test "should validate width is greater than 0" do
    @glassplate.width = 0
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:width], "must be greater than 0"
  end

  test "should validate height is greater than 0" do
    @glassplate.height = -1
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:height], "must be greater than 0"
  end

  test "should validate quantity is greater than or equal to 0" do
    @glassplate.quantity = -1
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:quantity], "must be greater than or equal to 0"
  end

  test "should validate color inclusion" do
    @glassplate.color = "invalid_color"
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:color], "debe ser uno de: transparente, gris, azul, verde, negro, plata, N/A"
  end

  test "should validate glass_type inclusion" do
    @glassplate.glass_type = "Invalid Type"
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:glass_type], "debe ser uno de: Incoloro, Laminado 3+3, DVH 4/9/4, Espejo, Templado, Doble"
  end

  test "should validate status inclusion" do
    @glassplate.status = "invalid_status"
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:status], "is not included in the list"
  end

  test "should validate is_scrap inclusion" do
    @glassplate.is_scrap = nil
    assert_not @glassplate.valid?
    assert_includes @glassplate.errors[:is_scrap], "is not included in the list"
  end

  # Scopes tests
  test "complete_sheets scope should return non-scrap items" do
    complete_sheet = glassplates(:complete_sheet)
    scrap = glassplates(:scrap)

    assert_includes Glassplate.complete_sheets, complete_sheet
    assert_not_includes Glassplate.complete_sheets, scrap
  end

  test "scraps scope should return scrap items" do
    complete_sheet = glassplates(:complete_sheet)
    scrap = glassplates(:scrap)

    assert_includes Glassplate.scraps, scrap
    assert_not_includes Glassplate.scraps, complete_sheet
  end

  test "available scope should return available items" do
    available = glassplates(:available)
    reserved = glassplates(:reserved)

    assert_includes Glassplate.available, available
    assert_not_includes Glassplate.available, reserved
  end

  test "reserved scope should return reserved items" do
    available = glassplates(:available)
    reserved = glassplates(:reserved)

    assert_includes Glassplate.reserved, reserved
    assert_not_includes Glassplate.reserved, available
  end

  # Instance methods tests
  test "measures should return width x height" do
    @glassplate.width = 800
    @glassplate.height = 600
    assert_equal "800x600", @glassplate.measures
  end

  test "full_description should return type thickness and color" do
    assert_equal "Incoloro 4mm - transparente", @glassplate.full_description
  end

  test "available? should return true for disponible status" do
    @glassplate.status = "disponible"
    assert @glassplate.available?
  end

  test "available? should return false for non-disponible status" do
    @glassplate.status = "reservado"
    assert_not @glassplate.available?
  end

  test "reserved? should return true for reservado status" do
    @glassplate.status = "reservado"
    assert @glassplate.reserved?
  end

  test "reserved? should return false for non-reservado status" do
    @glassplate.status = "disponible"
    assert_not @glassplate.reserved?
  end
end
