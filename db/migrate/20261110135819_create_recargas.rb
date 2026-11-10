class CreateRecargas < ActiveRecord::Migration[8.1]
  def change
    create_table :recargas do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :carteira, null: false, foreign_key: true
      t.integer :quantidade_refeicoes, null: false
      t.integer :valor_centavos, null: false
      t.string :status, null: false, default: "pendente"
      t.string :metodo_pagamento, null: false
      t.string :txid_pix

      t.timestamps
    end
  end
end
