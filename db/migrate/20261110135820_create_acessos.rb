class CreateAcessos < ActiveRecord::Migration[8.1]
  def change
    create_table :acessos do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :catraca, null: false, foreign_key: true
      t.references :turno, null: false, foreign_key: true
      t.integer :valor_pago_centavos, null: false, default: 450
      t.boolean :autorizado, null: false, default: true
      t.string :motivo_recusa
      t.datetime :data_hora, null: false

      t.timestamps
    end
  end
end
