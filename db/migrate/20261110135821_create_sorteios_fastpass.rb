class CreateSorteiosFastpass < ActiveRecord::Migration[8.1]
  def change
    create_table :sorteios_fastpass do |t|
      t.references :turno, null: false, foreign_key: true
      t.date :data_sorteio, null: false
      t.string :status, null: false, default: "aberto"
      t.integer :vagas_disponiveis, null: false

      t.timestamps
    end
  end
end
