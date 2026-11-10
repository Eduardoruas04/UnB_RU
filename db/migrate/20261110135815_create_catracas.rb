class CreateCatracas < ActiveRecord::Migration[8.1]
  def change
    create_table :catracas do |t|
      t.references :restaurante, null: false, foreign_key: true
      t.string :codigo_identificador, null: false
      t.string :status, null: false, default: "ativa"

      t.timestamps
    end
    add_index :catracas, :codigo_identificador, unique: true
  end
end
