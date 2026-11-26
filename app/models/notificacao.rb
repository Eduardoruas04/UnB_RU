# Armazena um aviso destinado a um usuário, com associação opcional a um sorteio FastPass.
class Notificacao < ApplicationRecord
  belongs_to :usuario
  belongs_to :sorteio_fastpass, optional: true

  validates :titulo, :mensagem, :tipo, :status_envio, presence: true
end
