require "rails_helper"

RSpec.describe SorteioFastpass, type: :model do
  let(:turno) { FactoryBot.create(:turno, horario_inicio: "00:30", horario_fim: "02:00") }
  subject(:sorteio) do
    FactoryBot.build(:sorteio_fastpass, turno: turno, data_sorteio: Date.new(2026, 11, 12), status: "realizado")
  end

  it "agenda a notificação na véspera quando o turno começa depois da meia-noite" do
    sorteio.save!
    brasilia = Time.find_zone!("America/Sao_Paulo")

    expect(sorteio.horario_fastpass).to eq(brasilia.local(2026, 11, 12, 0, 30))
    expect(sorteio.horario_notificacao).to eq(brasilia.local(2026, 11, 11, 23, 30))
  end

  it "rejeita quantidade negativa de vagas" do
    sorteio.vagas_disponiveis = -1

    expect(sorteio.save).to be(false)
    expect(sorteio.errors.of_kind?(:vagas_disponiveis, :greater_than_or_equal_to)).to be(true)
  end
end
