ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Métodos de ayuda para pruebas
    
    # Verifica que un atributo tenga un mensaje de error específico
    def assert_error_message(record, attribute, message)
      assert_includes record.errors[attribute], message
    end
    
    # Verifica que un atributo sea válido
    def assert_valid_attr(record, attribute, valid_values)
      valid_values.each do |value|
        record.send("#{attribute}=", value)
        assert record.valid?, "#{attribute} debería ser válido con valor: #{value}"
      end
    end
    
    # Verifica que un atributo no sea válido
    def assert_invalid_attr(record, attribute, invalid_values, error_message)
      invalid_values.each do |value|
        record.send("#{attribute}=", value)
        assert_not record.valid?, "#{attribute} no debería ser válido con valor: #{value}"
        assert_error_message(record, attribute, error_message)
      end
    end
  end
end

# Configuración para System Tests
class ActionDispatch::SystemTestCase
  driven_by :rack_test
end
