class InscricaoFastpass < ApplicationRecord
  belongs_to :sorteio_fastpass
  belongs_to :usuario

  validates :status, presence: true
end
