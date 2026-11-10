class CreateRestaurantes < ActiveRecord::Migration[8.1]
  def change
    create_table :restaurantes do |t|
      t.string :nome, null: false
      t.string :campus, null: false
      t.boolean :ativo, null: false, default: true

      t.timestamps
    end
  end
end
