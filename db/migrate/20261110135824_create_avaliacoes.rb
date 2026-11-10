class CreateAvaliacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :avaliacoes do |t|
      t.references :usuario, null: false, foreign_key: true
      t.references :acesso, null: false, foreign_key: true, index: { unique: true }
      t.integer :nota, null: false
      t.text :comentario

      t.timestamps
    end
  end
end
