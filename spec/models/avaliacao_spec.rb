require "rails_helper"

RSpec.describe Avaliacao, type: :model do
  it "aceita notas de 1 a 5 e rejeita notas ausentes ou fora do intervalo" do
    avaliacao = described_class.new

    aggregate_failures do
      (1..5).each do |nota|
        avaliacao.nota = nota
        avaliacao.validate
        expect(avaliacao.errors[:nota]).to be_empty
      end

      [ nil, 0, 6 ].each do |nota|
        avaliacao.nota = nota
        avaliacao.validate
        expect(avaliacao.errors[:nota]).not_to be_empty
      end
    end
  end
end
