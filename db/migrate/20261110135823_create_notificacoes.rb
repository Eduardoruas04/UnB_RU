class CreateNotificacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :notificacoes do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :sorteio_fastpass, null: true, foreign_key: true
      t.string :titulo, null: false
      t.text :mensagem, null: false
      t.boolean :lida, null: false, default: false
      t.string :tipo, null: false
      t.string :status_envio, null: false, default: "pendente"
      t.datetime :enviado_em

      t.timestamps
    end
  end
end
