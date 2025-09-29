require 'test_helper'

# Test para Glassplate
class GlassplateTest < ActiveSupport::TestCase
  test "requires all mandatory attributes" do
    glassplate = Glassplate.new
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:glass_type], "El tipo de vidrio no puede estar en blanco"
    assert_includes glassplate.errors[:thickness], "El espesor no puede estar en blanco"
    assert_includes glassplate.errors[:color], "El color no puede estar en blanco"
    assert_includes glassplate.errors[:width], "El ancho no puede estar en blanco"
    assert_includes glassplate.errors[:height], "El alto no puede estar en blanco"
    assert_includes glassplate.errors[:quantity], "La cantidad no puede estar en blanco"
  end

  # Test para validar valores de enumeraciones
  test "validates enum values" do
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

  # Test para crear un registro válido
  test "creates a valid record" do
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

  # Pruebas para el método full_description
  test "returns full glass description" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_equal "LAM 3+3 - INC", glassplate.full_description
  end

  # Pruebas de valores límite para width y height
  test "must validate that the width is greater than 0" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 0,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:width], "El ancho debe ser mayor que 0"
  end

  test "must validate that the height is greater than 0" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 0,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:height], "El alto debe ser mayor que 0"
  end

  test "must validate that the quantity is greater than or equal to 0" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 100,
      height: 100,
      quantity: -1
    )
    
    assert_not glassplate.valid?
    assert_not_empty glassplate.errors[:quantity], "Debería haber un error de validación para cantidad"
  end

  # Pruebas de inclusión para glass_type
  test "must validate that the glass type is LAM, FLO or COL" do
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

  # Pruebas de inclusión para thickness
  test "must validate that the thickness is valid" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "2+2",  # Inválido
      color: "INC",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:thickness], "El espesor debe ser uno de: 3+3, 4+4, 5+5, 5mm"
  end

  # Pruebas de inclusión para color
  test "must validate that the color is valid" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INVALID",
      width: 100,
      height: 100,
      quantity: 1
    )
    
    assert_not glassplate.valid?
    assert_includes glassplate.errors[:color], "El color debe ser uno de: INC, STB, GRS, BRC, BLS, STG, NTR"
  end

  # Prueba de borde: valores mínimos válidos
  test "must be valid with minimum values" do
    glassplate = Glassplate.new(
      glass_type: "LAM",
      thickness: "3+3",
      color: "INC",
      width: 0.1,  # Valor mínimo mayor que 0
      height: 0.1, # Valor mínimo mayor que 0
      quantity: 0   # Valor mínimo permitido
    )
    
    assert glassplate.valid?
  end
end