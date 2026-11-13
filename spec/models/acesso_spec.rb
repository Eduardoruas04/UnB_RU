require "rails_helper"

RSpec.describe Acesso, type: :model do
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro") }
  let(:catraca_um) { Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-01") }
  let(:catraca_dois) { Catraca.create!(restaurante: restaurante, codigo_identificador: "CAT-02") }
  let(:turno) do
    Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00",
                  valor_refeicao_centavos: 450)
  end
  let(:aluno) do
    Usuario.create!(matricula: "190012345", nome: "Aluno Teste", email: "aluno@aluno.unb.br",
                    password: "senha123", papel: "estudante", ativo: true)
  end

  def registrar(catraca, quando, valor: 450)
    Acesso.create!(usuario: aluno, catraca: catraca, turno: turno, data_hora: quando,
                   autorizado: true, valor_pago_centavos: valor)
  end

  def hora(h, m)
    Time.zone.local(2026, 11, 12, h, m)
  end

  describe "validações" do
    it "é válido com data e hora e valor" do
      expect(registrar(catraca_um, hora(12, 0))).to be_persisted
    end

    it "é inválido sem data e hora" do
      acesso = Acesso.new(usuario: aluno, catraca: catraca_um, turno: turno,
                          valor_pago_centavos: 450)

      expect(acesso).not_to be_valid
      expect(acesso.errors[:data_hora]).not_to be_empty
    end

    it "é inválido com valor pago negativo" do
      acesso = Acesso.new(usuario: aluno, catraca: catraca_um, turno: turno,
                          data_hora: hora(12, 0), valor_pago_centavos: -1)

      expect(acesso).not_to be_valid
      expect(acesso.errors[:valor_pago_centavos]).not_to be_empty
    end
  end

  describe "histórico de uma catraca" do
    it "pertence à catraca em que foi registrado" do
      acesso = registrar(catraca_um, hora(12, 0))

      expect(acesso.catraca).to eq(catraca_um)
    end

    it "lista apenas os acessos da própria catraca" do
      na_um = registrar(catraca_um, hora(12, 0))
      na_dois = registrar(catraca_dois, hora(12, 10))

      expect(catraca_um.acessos).to contain_exactly(na_um)
      expect(catraca_dois.acessos).to contain_exactly(na_dois)
    end

    it "ordena do acesso mais recente para o mais antigo" do
      antigo = registrar(catraca_um, hora(12, 0))
      recente = registrar(catraca_um, hora(12, 30))

      expect(catraca_um.acessos.order(data_hora: :desc).to_a).to eq([ recente, antigo ])
    end
  end
end
