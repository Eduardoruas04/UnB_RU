class CreateInscricoesFastpass < ActiveRecord::Migration[8.1]
  def change
    create_table :inscricoes_fastpass do |t|
      t.references :sorteio_fastpass, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.string :status, null: false, default: "pendente"

      t.timestamps
    end
    add_index :inscricoes_fastpass, [:sorteio_fastpass_id, :usuario_id], unique: true, name: "idx_inscricoes_fastpass_unique"
  end
end
