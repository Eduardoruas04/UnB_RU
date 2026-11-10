class Usuario < ApplicationRecord
  has_secure_password

  has_one :carteira, dependent: :destroy
  has_many :recargas, dependent: :destroy
  has_many :acessos, dependent: :destroy
  has_many :avaliacoes, dependent: :destroy
  has_many :inscricoes_fastpass, dependent: :destroy
  has_many :notificacoes, dependent: :destroy

  validates :matricula, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :nome, presence: true
  validates :papel, presence: true
end
