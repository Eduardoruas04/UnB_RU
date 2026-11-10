class Restaurante < ApplicationRecord
  has_many :catracas, dependent: :destroy
  has_many :cardapios, dependent: :destroy

  validates :nome, :campus, presence: true
end
