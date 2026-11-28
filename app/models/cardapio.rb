# Cardápio de uma refeição: o que um restaurante serve em um turno
# (café da manhã, almoço ou jantar) numa data. Os pratos ficam em
# ItemCardapio, um por categoria.
class Cardapio < ApplicationRecord
  belongs_to :restaurante
  belongs_to :turno
  has_many :itens_cardapio, dependent: :destroy

  validates :data_refeicao, presence: true
end
