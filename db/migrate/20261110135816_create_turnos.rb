class CreateTurnos < ActiveRecord::Migration[8.1]
  def change
    create_table :turnos do |t|
      t.string :nome, null: false
      t.time :horario_inicio, null: false
      t.time :horario_fim, null: false
      t.integer :valor_refeicao_centavos, null: false, default: 450

      t.timestamps
    end
  end
end
