class ItemCardapio < ApplicationRecord
  belongs_to :cardapio

  validates :categoria, :descricao, presence: true
end
