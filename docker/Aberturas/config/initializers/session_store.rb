# Cambiar almacenamiento de sesión de cookies a cache
# Esto evita el CookieOverflow cuando hay datos grandes
Rails.application.config.session_store :cache_store,
  key: '_aberturas_session',
  expire_after: 24.hours
