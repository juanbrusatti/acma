class AddNewSupplies < ActiveRecord::Migration[8.0]
  def change
    # Add new supplies: Angulos and Perfil separador
    Supply.create!(name: "Angulos", price_usd: 0.0, price_peso: 0.0) unless Supply.exists?(name: "Angulos")
    Supply.create!(name: "Perfil separador", price_usd: 0.0, price_peso: 0.0) unless Supply.exists?(name: "Perfil separador")
  end
end
