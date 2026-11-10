class Catraca < ApplicationRecord
  belongs_to :restaurante
  has_many :acessos, dependent: :destroy

  validates :codigo_identificador, presence: true, uniqueness: true
  validates :status, presence: true
end
