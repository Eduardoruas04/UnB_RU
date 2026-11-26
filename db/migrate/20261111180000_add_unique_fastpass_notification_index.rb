class AddUniqueFastpassNotificationIndex < ActiveRecord::Migration[8.1]
  # [Descrição] Define um índice único para avisos FastPass por usuário e sorteio.
  # [Argumentos] Nenhum.
  # [Retorno] O resultado de +add_index+ no adaptador do banco.
  # [Efeitos colaterais] Cria o índice na migração de subida e o remove na reversão.
  def change
    add_index :notificacoes, [ :usuario_id, :sorteio_fastpass_id ], unique: true,
      where: "tipo = 'fastpass'", name: "index_notificacoes_fastpass_unicas"
  end
end
