# Pruebas Automatizadas

Este directorio contiene las pruebas automatizadas para la aplicación. A continuación se detalla la estructura y cómo ejecutar las pruebas.

## Estructura de Directorios

- `controllers/`: Pruebas para los controladores
- `fixtures/`: Datos de prueba para los modelos
- `integration/`: Pruebas de integración
- `models/`: Pruebas para los modelos
- `system/`: Pruebas del sistema (pruebas de navegador)

## Ejecutando las Pruebas

Para ejecutar todas las pruebas:

```bash
bin/rails test
```

Para ejecutar pruebas específicas:

```bash
# Ejecutar pruebas de un archivo específico
bin/rails test test/models/glassplate_test.rb

# Ejecutar una prueba específica por nombre
bin/rails test test/models/glassplate_test.rb -n "test_debe_tener_atributos_requeridos"

# Ejecutar pruebas con salida detallada
bin/rails test --verbose
```

## Convenciones de Nombrado

- Los archivos de prueba deben terminar en `_test.rb`
- Los fixtures deben estar en `test/fixtures/` con el mismo nombre que el modelo en plural (ej: `glassplates.yml`)
- Los nombres de las pruebas deben ser descriptivos y en minúsculas con guiones bajos

## Mejores Prácticas

1. **Una aserción por prueba**: Cada prueba debe verificar solo una cosa
2. **Usar fixtures**: Para datos de prueba reutilizables
3. **Pruebas independientes**: Cada prueba debe poder ejecutarse de forma aislada
4. **Nombres descriptivos**: Los nombres de las pruebas deben describir claramente lo que están probando

## Depuración

Para depurar pruebas, puedes usar `byebug` o `debugger` en tu código de prueba:

```ruby
test "debe crear un registro válido" do
  glassplate = Glassplate.new(/* atributos */)
  debugger # La ejecución se detendrá aquí
  assert glassplate.valid?
end
```

## Recursos

- [Guía de Pruebas de Rails](https://guides.rubyonrails.org/testing.html)
- [Documentación de Minitest](https://github.com/seattlerb/minitest)
- [Betterspecs](https://www.betterspecs.org/) - Buenas prácticas para pruebas en Ruby
