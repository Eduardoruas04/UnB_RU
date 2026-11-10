class CreateItensCardapio < ActiveRecord::Migration[8.1]
  def change
    create_table :itens_cardapio do |t|
      t.references :cardapio, null: false, foreign_key: true
      t.string :categoria, null: false
      t.string :descricao, null: false

      t.timestamps
    end
  end
end
