# frozen_string_literal: true

# ==============================================================================
# Testes Unitários de Service (RSpec): ExtratoService (spec/services/extrato_service_spec.rb)
# ==============================================================================
# Valida consolidação contábil, ordenação, filtros, totalizadores e formatação
# do serviço de extrato do estudante (Happy Path e Sad Path).
# ==============================================================================

require "rails_helper"

RSpec.describe ExtratoService, type: :service do
  let!(:usuario) do
    Usuario.find_or_create_by!(matricula: "221045888") do |u|
      u.nome = "Estudante Extrato"
      u.email = "extrato_service@unb.br"
      u.password = "password123"
      u.papel = "estudante"
      u.ativo = true
    end
  end

  let!(:carteira) do
    c = usuario.carteira || usuario.create_carteira!(saldo_centavos: 1800)
    c.update!(saldo_centavos: 1800)
    c
  end

  let!(:restaurante) do
    Restaurante.find_or_create_by!(nome: "Restaurante Universitário - Darcy Ribeiro") do |r|
      r.campus = "Darcy Ribeiro"
      r.ativo = true
    end
  end

  let!(:catraca) do
    Catraca.find_or_create_by!(codigo_identificador: "CAT-EXT-01") do |c|
      c.restaurante = restaurante
      c.status = "ativa"
    end
  end

  let!(:turno_almoco) do
    Turno.find_or_create_by!(nome: "Almoço") do |t|
      t.horario_inicio = "11:00"
      t.horario_fim = "14:00"
      t.valor_refeicao_centavos = 450
    end
  end

  let!(:turno_jantar) do
    Turno.find_or_create_by!(nome: "Jantar") do |t|
      t.horario_inicio = "17:00"
      t.horario_fim = "19:30"
      t.valor_refeicao_centavos = 450
    end
  end

  before do
    usuario.recargas.destroy_all
    usuario.acessos.destroy_all

    # Recarga paga recente (hoje)
    @recarga_recente = usuario.recargas.create!(
      carteira: carteira,
      quantidade_refeicoes: 10,
      valor_centavos: 4500,
      status: "paga",
      metodo_pagamento: "PIX Instantâneo",
      created_at: 2.days.ago
    )

    # Recarga pendente (nao deve aparecer no extrato)
    usuario.recargas.create!(
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 2250,
      status: "pendente",
      metodo_pagamento: "PIX Instantâneo",
      created_at: 1.day.ago
    )

    # Acesso autorizado recente (hoje - Almoco)
    @acesso_recente = usuario.acessos.create!(
      catraca: catraca,
      turno: turno_almoco,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: "QR Code App",
      data_hora: Time.current
    )

    # Acesso autorizado antigo (45 dias atras - Jantar)
    @acesso_antigo = usuario.acessos.create!(
      catraca: catraca,
      turno: turno_jantar,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: "Carteirinha Física",
      data_hora: 45.days.ago
    )

    # Acesso recusado (nao deve aparecer no extrato)
    usuario.acessos.create!(
      catraca: catraca,
      turno: turno_almoco,
      valor_pago_centavos: 0,
      autorizado: false,
      motivo_recusa: "Saldo insuficiente",
      forma_acesso: "QR Code App",
      data_hora: Time.current
    )
  end

  describe "consolidação e ordenação (Happy Path)" do
    it "unifica apenas recargas pagas e acessos autorizados em ordem decrescente" do
      service = described_class.new(usuario)

      expect(service.lancamentos.size).to eq(3)
      expect(service.lancamentos.first.id).to eq("acesso-#{@acesso_recente.id}")
      expect(service.lancamentos.last.id).to eq("acesso-#{@acesso_antigo.id}")
    end

    it "calcula corretamente os indicadores contábeis e o saldo atual" do
      service = described_class.new(usuario)

      expect(service.total_gasto_centavos).to eq(900)
      expect(service.total_gasto_formatado).to eq("R$ 9,00")
      expect(service.refeicoes_realizadas_count).to eq(2)
      expect(service.total_recarregado_centavos).to eq(4500)
      expect(service.total_recarregado_formatado).to eq("R$ 45,00")
      expect(service.saldo_atual_formatado).to eq("R$ 18,00")
      expect(service.saldo_atual_refeicoes).to eq(4)
    end
  end

  describe "filtros (Happy Path e Sad Path)" do
    it "filtra pelos últimos 7 dias" do
      service = described_class.new(usuario, periodo: "Últimos 7 dias")
      expect(service.lancamentos.size).to eq(2)
    end

    it "filtra pelos últimos 30 dias" do
      service = described_class.new(usuario, periodo: "Últimos 30 dias")
      expect(service.lancamentos.size).to eq(2)
    end

    it "filtra pelo mês atual" do
      service = described_class.new(usuario, periodo: "Mês Atual")
      ids = service.lancamentos.map(&:id)
      expect(ids).to include("acesso-#{@acesso_recente.id}")
      expect(ids).not_to include("acesso-#{@acesso_antigo.id}")
    end

    it "mantém todos os registros quando o período não corresponde a uma regra conhecida" do
      service = described_class.new(usuario, periodo: "Todo o período")
      expect(service.lancamentos.size).to eq(3)
    end

    it "filtra apenas recargas quando tipo_refeicao inclui recarga" do
      service = described_class.new(usuario, tipo_refeicao: "Recarga de Saldo")
      expect(service.lancamentos.size).to eq(1)
      expect(service.lancamentos.first).to be_credito
    end

    it "filtra por tipo de refeição específico" do
      service = described_class.new(usuario, tipo_refeicao: "Almoço")
      expect(service.lancamentos.size).to eq(1)
      expect(service.lancamentos.first.evento).to eq("Almoço")
    end

    it "filtra por forma de acesso" do
      service = described_class.new(usuario, forma_acesso: "QR Code App")
      expect(service.lancamentos.size).to eq(1)
      expect(service.lancamentos.first.forma_acesso).to eq("QR Code App")
    end

    it "ignora filtros quando valor é 'Todas'" do
      service = described_class.new(usuario, tipo_refeicao: "Todas", forma_acesso: "Todas")
      expect(service.lancamentos.size).to eq(3)
    end

    it "retorna lista vazia quando nenhum lançamento atende ao filtro (Sad Path)" do
      service = described_class.new(usuario, tipo_refeicao: "Café da Manhã")
      expect(service.lancamentos).to be_empty
    end
  end

  describe "casos de borda e helpers do Struct Lancamento" do
    it "formata valores positivos, negativos e datas corretamente" do
      service = described_class.new(usuario)
      credito = service.lancamentos.find(&:credito?)
      debito = service.lancamentos.find(&:debito?)

      expect(credito.valor_formatado).to eq("+ R$ 45,00")
      expect(credito.debito?).to be(false)
      expect(debito.valor_formatado).to eq("- R$ 4,50")
      expect(debito.credito?).to be(false)
      expect(debito.data_formatada).to match(%r{\A\d{2}/\d{2}/\d{4} às \d{2}:\d{2}\z})
    end

    it "retorna saldo zerado quando o estudante não possui carteira (Sad Path)" do
      usuario_sem_carteira = Usuario.create!(
        matricula: "221045777",
        nome: "Sem Carteira",
        email: "sem_carteira@unb.br",
        password: "password123",
        papel: "estudante",
        ativo: true
      )
      service = described_class.new(usuario_sem_carteira)

      expect(service.saldo_atual_formatado).to eq("R$ 0,00")
      expect(service.saldo_atual_refeicoes).to eq(0)
    end

    it "retorna fallback 'Darcy Ribeiro' quando restaurante é nulo e limpa prefixo do nome" do
      service = described_class.new(usuario)
      restaurante_sem_campus = Restaurante.new(nome: "Restaurante Universitário - Planaltina", campus: nil)

      expect(service.send(:formatar_restaurante, nil)).to eq("Darcy Ribeiro")
      expect(service.send(:formatar_restaurante, restaurante_sem_campus)).to eq("Planaltina")
    end
  end
end
