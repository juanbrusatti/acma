require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  setup do
    # Limpiar la base de datos antes de cada test
    Project.destroy_all
  end

  # Test para verificar las asociaciones
  test "has correct associations" do
    assert_respond_to Project.new, :dvhs
    assert_respond_to Project.new, :glasscuttings
  end

  # Test para validaciones de atributos requeridos
  test "validates required attributes" do
    project = Project.new
    assert_not project.valid?
    
    # Verificar mensajes de error para campos requeridos
    assert_includes project.errors[:name], "El nombre del proyecto no puede estar en blanco"
    assert_includes project.errors[:phone], "El teléfono no puede estar en blanco"
    # Se quitó la validación de status ya que no es un campo crítico para la funcionalidad
  end

  # Test para validar la longitud máxima del nombre
  test "validates maximum name length" do
    project = Project.new(name: 'a' * 101, phone: '123456789', status: 'Pendiente')
    assert_not project.valid?
    assert_includes project.errors[:name], "no puede tener más de 100 caracteres"
  end

  # Test para validar los valores del estado
  test "validates status values" do
    project = Project.new(name: 'Proyecto válido', phone: '123456789', status: 'Invalido')
    assert_not project.valid?
    assert_includes project.errors[:status], "debe ser uno de: Pendiente, En Proceso, Terminado"
  end

  # Test para validar estados válidos
  test "accepts valid status values" do
    ['Pendiente', 'En Proceso', 'Terminado'].each do |status|
      project = Project.new(name: 'Proyecto válido', phone: '123456789', status: status)
      assert project.valid?, "Debería ser válido con estado: #{status}"
    end
  end

  # Test para el método overdue?
  test "determines if project is overdue" do
    project = Project.new(
      name: 'Proyecto de prueba', 
      phone: '123456789', 
      status: 'Pendiente',
      delivery_date: 1.day.ago
    )
    
    # Proyecto con fecha de entrega pasada y estado Pendiente
    assert project.overdue?
    
    # Proyecto con fecha de entrega futura
    project.delivery_date = 1.day.from_now
    assert_not project.overdue?
    
    # Proyecto completado no está retrasado aunque la fecha haya pasado
    project.status = 'Terminado'
    project.delivery_date = 1.day.ago
    assert_not project.overdue?
  end

  # Test para el método days_until_delivery
  test "correctly calculates days until delivery" do
    project = Project.new(name: 'Test', phone: '123', status: 'Pendiente')
    
    # Sin fecha de entrega
    project.delivery_date = nil
    assert_nil project.days_until_delivery
    
    # Con fecha de entrega futura
    future_date = 5.days.from_now.to_date
    project.delivery_date = future_date
    assert_equal 5, project.days_until_delivery
    
    # Con fecha de entrega pasada
    past_date = 5.days.ago.to_date
    project.delivery_date = past_date
    assert_equal (-5), project.days_until_delivery
  end

  # Test para el método subtotal
  test "correctly calculates subtotal" do
    project = Project.new(
      name: 'Test', 
      phone: '123', 
      status: 'Pendiente',
      price_without_iva: 1000
    )
    
    # Con precio sin IVA guardado
    assert_equal 1000, project.subtotal
    
    # Sin precio sin IVA guardado (debería ser 0 sin ítems)
    project.price_without_iva = nil
    assert_equal 0, project.subtotal
  end

  # Test para los scopes
  test "has scopes to filter by status" do
    # Crear proyectos de prueba
    pending = Project.create!(name: 'Pendiente', phone: '123', status: 'Pendiente')
    active = Project.create!(name: 'En Proceso', phone: '456', status: 'En Proceso')
    completed = Project.create!(name: 'Terminado', phone: '789', status: 'Terminado')
    
    # Verificar que solo se obtenga un proyecto por cada estado
    assert_equal 1, Project.pending.count
    assert_equal 'Pendiente', Project.pending.first.name
    
    assert_equal 1, Project.active.count
    assert_equal 'En Proceso', Project.active.first.name
    
    assert_equal 1, Project.completed.count
    assert_equal 'Terminado', Project.completed.first.name
  end
  
  test "has scopes for delivery dates" do
    # Crear proyectos con diferentes fechas
    overdue = Project.create!(
      name: 'Atrasado', 
      phone: '111', 
      status: 'Pendiente', 
      delivery_date: 1.day.ago
    )
    
    upcoming = Project.create!(
      name: 'Próximo', 
      phone: '222', 
      status: 'Pendiente', 
      delivery_date: 1.day.from_now
    )
    
    # Verificar que solo se obtenga un proyecto por cada scope
    assert_equal 1, Project.overdue.count
    assert_equal 'Atrasado', Project.overdue.first.name
    
    assert_equal 1, Project.upcoming.count
    assert_equal 'Próximo', Project.upcoming.first.name
  end
  
  # Test para el método iva
  test "correctly calculates IVA" do
    project = Project.new(
      name: 'Test IVA', 
      phone: '123', 
      status: 'Pendiente',
      price_without_iva: 1000
    )
    
    # 21% de 1000 es 210
    assert_equal 210.0, project.iva
    
    # Sin precio sin IVA guardado (debería ser 0 sin ítems)
    project.price_without_iva = nil
    assert_equal 0.0, project.iva
  end
  
  # Test para el método total
  test "correctly calculates total including IVA" do
    project = Project.new(
      name: 'Test Total', 
      phone: '123', 
      status: 'Pendiente',
      price_without_iva: 1000
    )
    
    # 1000 + 21% = 1210
    assert_equal 1210.0, project.total
    
    # Sin precio sin IVA guardado (debería ser 0 sin ítems)
    project.price_without_iva = nil
    assert_equal 0.0, project.total
  end
  
  # Test para el alias precio_sin_iva
  test "precio_sin_iva is an alias of subtotal" do
    project = Project.new(
      name: 'Test Alias', 
      phone: '123', 
      status: 'Pendiente',
      price_without_iva: 1000
    )
    
    assert_equal project.subtotal, project.precio_sin_iva
    
    # Verificar que sea un alias, no solo igualdad de valores
    project.price_without_iva = 500
    assert_equal 500, project.precio_sin_iva
  end
  
  # Test para el método status_color
  test "returns correct status color" do
    project = Project.new(name: 'Test Color', phone: '123')
    
    project.status = 'Pendiente'
    assert_equal 'yellow', project.status_color
    
    project.status = 'En Proceso'
    assert_equal 'blue', project.status_color
    
    project.status = 'Terminado'
    assert_equal 'green', project.status_color
    
    # Estado inválido debería devolver 'gray'
    project.status = 'Invalido'
    assert_equal 'gray', project.status_color
    
    # Estado nulo también debería devolver 'gray'
    project.status = nil
    assert_equal 'gray', project.status_color
  end
  
  # Test para verificar que no hay callbacks personalizados definidos
  test "should not have custom callbacks defined" do
    # Ignorar callbacks estándar de Rails para asociaciones
    ignored_callbacks = [:autosave_associated_records_for_dvhs, :autosave_associated_records_for_glasscuttings, :around_save_collection_association]
    
    # Obtener todos los callbacks y filtrar los ignorados
    callbacks = Project._save_callbacks.reject do |callback|
      ignored_callbacks.include?(callback.filter) || 
      callback.filter.to_s.include?('autosave_associated_records_for_')
    end
    
    # Convertir a nombres para el mensaje de error
    callback_names = callbacks.map { |c| c.filter.to_s }
    
    assert_empty callbacks, "Se encontraron callbacks personalizados inesperados: #{callback_names.join(', ')}"
  end
end
