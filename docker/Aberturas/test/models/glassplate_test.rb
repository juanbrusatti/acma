require 'test_helper'

class GlassplateTest < ActiveSupport::TestCase
  test "debe tener atributos requeridos" do
    glassplate = Glassplate.new
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:glass_type], "El tipo de vidrio no puede estar en blanco"
    assert_includes glassplate.errors[:thickness], "El espesor no puede estar en blanco"
    assert_includes glassplate.errors[:color], "El color no puede estar en blanco"
    assert_includes glassplate.errors[:width], "El ancho no puede estar en blanco"
    assert_includes glassplate.errors[:height], "El alto no puede estar en blanco"
    assert_includes glassplate.errors[:quantity], "La cantidad no puede estar en blanco"
  end

  test "debe validar valores de enumeraciones" do
    glassplate = Glassplate.new(
      glass_type: "INVALID",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:glass_type], "El tipo de vidrio debe ser uno de: LAM, FLO, COL"
  end

  test "debe crear un registro válido" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert glassplate.valid?
  end
end