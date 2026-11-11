class Catraca < ApplicationRecord
  belongs_to :restaurante, optional: true
  has_many :acessos, dependent: :destroy

  before_validation { self.status = "ativa" if status.blank? }

  validates :status, presence: true
  validate :validar_restaurante_e_identificador

  private

  def validar_restaurante_e_identificador
    errors.add(:base, "Selecione um restaurante") if restaurante.blank?

    if codigo_identificador.blank?
      errors.add(:base, "Identificador não pode ficar em branco")
    elsif Catraca.where.not(id: id).exists?(codigo_identificador: codigo_identificador)
      errors.add(:base, "Já existe uma catraca com este identificador")
    end
  end
end