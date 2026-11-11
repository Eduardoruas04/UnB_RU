class Restaurante < ApplicationRecord
  has_many :catracas
  has_many :cardapios, dependent: :destroy

  before_validation { self.ativo = true if ativo.nil? }
  before_destroy :nao_remover_com_catracas, prepend: true

  validates :nome, presence: { message: "não pode ficar em branco" }
  validate :nome_unico

  private

  def nome_unico
    return if nome.blank?

    outros = Restaurante.where("LOWER(nome) = ?", nome.strip.downcase)
    outros = outros.where.not(id: id) if persisted?
    errors.add(:base, "Já existe um restaurante com este nome") if outros.exists?
  end

  def nao_remover_com_catracas
    return unless catracas.exists?

    errors.add(:base, "Remova as catracas deste restaurante antes de excluí-lo")
    throw :abort
  end
end