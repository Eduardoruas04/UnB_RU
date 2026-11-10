class Cardapio < ApplicationRecord
  belongs_to :restaurante
  belongs_to :turno
  has_many :itens_cardapio, dependent: :destroy

  validates :data_refeicao, presence: true
end
