require 'test_helper'

class ScrapTest < ActiveSupport::TestCase
  test "requires all mandatory attributes" do
    scrap = Scrap.new
    assert_not scrap.valid?
    assert_includes scrap.errors[:ref_number], "El número de referencia no puede estar en blanco"
    assert_includes scrap.errors[:input_work], "La obra de procedencia no puede estar en blanco"
    assert_includes scrap.errors[:scrap_type], "El tipo de vidrio no puede estar en blanco"
    assert_includes scrap.errors[:thickness], "El grosor del retazo no puede estar en blanco"
    assert_includes scrap.errors[:color], "El color no puede estar en blanco"
    assert_includes scrap.errors[:width], "El ancho del retazo no puede estar en blanco"
    assert_includes scrap.errors[:height], "El alto del retazo no puede estar en blanco"
  end

  test "validates enum values" do
    scrap = Scrap.new(
      ref_number: "TEST001",
      input_work: "OBRA TEST 1",
      scrap_type: "INVALID",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
    )

    assert_not scrap.valid?
    assert_includes scrap.errors[:scrap_type], "El tipo debe ser uno de: LAM, FLO, COL"
  end

  test "creates a valid record with all required attributes" do
    scrap = Scrap.new(
      ref_number: "TEST001",
      input_work: "OBRA TEST 1",
      scrap_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
    )

    assert scrap.valid?, scrap.errors.full_messages.join(", ")
  end
end
