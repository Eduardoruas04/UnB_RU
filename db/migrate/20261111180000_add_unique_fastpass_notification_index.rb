class AddUniqueFastpassNotificationIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :notificacoes, [ :usuario_id, :sorteio_fastpass_id ], unique: true,
      where: "tipo = 'fastpass'", name: "index_notificacoes_fastpass_unicas"
  end
end
