class Avaliacao < ApplicationRecord
  belongs_to :usuario
  belongs_to :acesso

  validates :nota, presence: true, inclusion: { in: 1..5 }
  validates :acesso_id, uniqueness: true
end
