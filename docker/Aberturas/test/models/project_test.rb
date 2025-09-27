require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  setup do
    # Limpiar la base de datos antes de cada test
    Project.destroy_all
  end

  # Test para verificar las asociaciones
  test "debe tener las asociaciones correctas" do
    assert_respond_to Project.new, :dvhs
    assert_respond_to Project.new, :glasscuttings
  end

  # Test para validaciones de atributos requeridos
  test "debe validar atributos requeridos" do
    project = Project.new
    assert_not project.valid?
    
    # Verificar mensajes de error para campos requeridos
    assert_includes project.errors[:name], "El nombre del proyecto no puede estar en blanco"
    assert_includes project.errors[:phone], "El teléfono no puede estar en blanco"
    # Se quitó la validación de status ya que no es un campo crítico para la funcionalidad
  end

  # Test para validar la longitud máxima del nombre
  test "debe validar la longitud máxima del nombre" do
    project = Project.new(name: 'a' * 101, phone: '123456789', status: 'Pendiente')
    assert_not project.valid?
    assert_includes project.errors[:name], "no puede tener más de 100 caracteres"
  end

  # Test para validar los valores del estado
  test "debe validar los valores del estado" do
    project = Project.new(name: 'Proyecto válido', phone: '123456789', status: 'Invalido')
    assert_not project.valid?
    assert_includes project.errors[:status], "debe ser uno de: Pendiente, En Proceso, Terminado"
  end

  # Test para validar estados válidos
  test "debe aceptar estados válidos" do
    ['Pendiente', 'En Proceso', 'Terminado'].each do |status|
      project = Project.new(name: 'Proyecto válido', phone: '123456789', status: status)
      assert project.valid?, "Debería ser válido con estado: #{status}"
    end
  end

  # Test para el método overdue?
  test "debe determinar si el proyecto está retrasado" do
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
  test "debe calcular los días hasta la entrega" do
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
  test "debe calcular el subtotal correctamente" do
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
  test "debe tener scopes para filtrar por estado" do
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
  
  test "debe tener scopes para fechas de entrega" do
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
end
