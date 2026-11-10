class CreateCardapios < ActiveRecord::Migration[8.1]
  def change
    create_table :cardapios do |t|
      t.references :restaurante, null: false, foreign_key: true
      t.references :turno, null: false, foreign_key: true
      t.date :data_refeicao, null: false

      t.timestamps
    end
  end
end
