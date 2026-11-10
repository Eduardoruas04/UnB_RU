class CreateCarteiras < ActiveRecord::Migration[8.1]
  def change
    create_table :carteiras do |t|
      t.references :usuario, null: false, foreign_key: true, index: { unique: true }
      t.integer :saldo_centavos, null: false, default: 0

      t.timestamps
    end
  end
end
