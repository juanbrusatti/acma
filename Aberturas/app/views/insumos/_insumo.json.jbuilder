json.extract! insumo, :id, :nombre, :precio, :created_at, :updated_at
json.url insumo_url(insumo, format: :json)
