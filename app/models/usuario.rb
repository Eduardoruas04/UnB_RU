class Usuario < ApplicationRecord
  has_secure_password

  has_one :carteira, dependent: :destroy
  has_many :recargas, dependent: :destroy
  has_many :acessos, dependent: :destroy
  has_many :avaliacoes, dependent: :destroy
  has_many :inscricoes_fastpass, dependent: :destroy
  has_many :notificacoes, dependent: :destroy

  validates :matricula, presence: { message: "Matrícula não pode ficar em branco" },
    uniqueness: { message: "Matrícula já cadastrada" }
  validates :matricula, format: { with: /\A[0-9]+\z/, message: "Matrícula deve conter apenas números" },
    length: { is: 9, message: "Matrícula deve ter 9 dígitos" }, allow_blank: true
  validates :email, presence: true, uniqueness: true
  validates :nome, presence: { message: "Nome é obrigatório" }
  validates :password, presence: { message: "Senha é obrigatória" }, on: :create
  validates :password, length: { minimum: 8, message: "Senha deve ter no mínimo 8 caracteres" },
    allow_blank: true
  validates :papel, presence: true
end
