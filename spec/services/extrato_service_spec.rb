
require "rails_helper"

RSpec.describe ExtratoService, type: :service do
  let!(:usuario) do
    Usuario.create!(
      matricula: "221045999",
      nome: "Estudante Teste",
      email: "estudante@teste.com",
      password: "password123",
      papel: "estudante",
      ativo: true
    )
  end

  let!(:carteira) do
    Carteira.create!(
      usuario: usuario,
      saldo_centavos: 2250
    )
  end

  let!(:restaurante) do
    Restaurante.create!(
      nome: "Restaurante Universitário",
      campus: "RU Darcy Ribeiro",
      ativo: true
    )
  end

  let!(:catraca) do
    Catraca.create!(
      restaurante: restaurante,
      codigo_identificador: "CAT-001",
      status: "ativa"
    )
  end

  let!(:turno) do
    Turno.create!(
      nome: "Almoço",
      horario_inicio: "11:00",
      horario_fim: "14:00",
      valor_refeicao_centavos: 450
    )
  end

  def criar_recarga(atributos = {})
    usuario.recargas.create!(
      {
        carteira: carteira,
        quantidade_refeicoes: 5,
        valor_centavos: 2250,
        status: "paga",
        metodo_pagamento: "PIX Instantâneo"
      }.merge(atributos)
    )
  end

  def criar_acesso(atributos = {})
    usuario.acessos.create!(
      {
        catraca: catraca,
        turno: turno,
        data_hora: Time.current,
        autorizado: true,
        valor_pago_centavos: 450,
        forma_acesso: "QR Code App"
      }.merge(atributos)
    )
  end

  describe "inicialização" do
    it "armazena o usuário e converte as chaves dos filtros para símbolos" do
      service = described_class.new(usuario, {
        "periodo" => "Últimos 30 dias",
        "tipo_refeicao" => "Almoço"
      })

      expect(service.usuario).to eq(usuario)
      expect(service.filtros).to eq({
        periodo: "Últimos 30 dias",
        tipo_refeicao: "Almoço"
      })
    end
  end

  describe ExtratoService::Lancamento do
    let(:lancamento) do
      described_class.new(
        "recarga-1",
        :recarga,
        Time.zone.parse("2026-11-25 12:30"),
        "Recarga de Saldo",
        "Portal Online",
        "PIX Instantâneo",
        :credito,
        4500
      )
    end

    it "identifica um lançamento de crédito" do
      expect(lancamento.credito?).to be true
      expect(lancamento.debito?).to be false
    end

    it "formata o valor de um crédito" do
      expect(lancamento.valor_formatado).to eq("+ R$ 45,00")
    end

    it "formata a data e o horário" do
      expect(lancamento.data_formatada).to eq("25/11/2026 às 12:30")
    end

    it "identifica e formata um lançamento de débito" do
      debito = lancamento.dup
      debito.tipo_fluxo = :debito

      expect(debito.credito?).to be false
      expect(debito.debito?).to be true
      expect(debito.valor_formatado).to eq("- R$ 45,00")
    end
  end

  describe "consolidação de lançamentos" do
    it "consolida recargas pagas e acessos autorizados" do
      criar_recarga
      criar_recarga(status: "pendente")
      criar_acesso
      criar_acesso(autorizado: false)

      lancamentos = described_class.new(usuario).lancamentos

      expect(lancamentos.size).to eq(2)
      expect(lancamentos.map(&:tipo_registro)).to contain_exactly(
        :recarga,
        :acesso
      )
    end

    it "ordena os lançamentos do mais recente para o mais antigo" do
      criar_recarga(created_at: 2.days.ago)
      criar_acesso(data_hora: 1.day.ago)

      lancamentos = described_class.new(usuario).lancamentos

      expect(lancamentos.first.tipo_registro).to eq(:acesso)
      expect(lancamentos.last.tipo_registro).to eq(:recarga)
    end

    it "utiliza os valores padrão quando faltam informações do acesso" do
      acesso = criar_acesso
      acesso.update_columns(
        forma_acesso: nil,
        valor_pago_centavos: nil,
        data_hora: nil
      )

      lancamento = described_class.new(usuario).lancamentos.first

      expect(lancamento.forma_acesso).to eq("QR Code App")
      expect(lancamento.valor_centavos).to eq(450)
      expect(lancamento.evento).to eq("Almoço")
    end

    it "utiliza o nome padrão quando o acesso não possui catraca" do
      acesso = criar_acesso

      allow(acesso).to receive(:catraca).and_return(nil)
      allow(usuario).to receive_message_chain(:acessos, :where, :includes, :find_each)
        .and_yield(acesso)

      lancamento = described_class.new(usuario).lancamentos.first

      expect(lancamento.restaurante).to eq("Darcy Ribeiro")
    end

    it "utiliza o nome do restaurante sem o prefixo RU" do
      criar_acesso

      lancamento = described_class.new(usuario).lancamentos.first

      expect(lancamento.restaurante).to eq("Darcy Ribeiro")
    end

    it "utiliza PIX Instantâneo como forma padrão de uma recarga sem método informado" do
      recarga = criar_recarga
      recarga.update_column(:metodo_pagamento, nil)

      lancamento = described_class.new(usuario).lancamentos.first

      expect(lancamento.forma_acesso).to eq("PIX Instantâneo")
    end

    it "retorna uma lista vazia quando não existem movimentações" do
      expect(described_class.new(usuario).lancamentos).to be_empty
    end

    it "reutiliza os lançamentos já consolidados" do
      criar_recarga

      service = described_class.new(usuario)

      primeira_chamada = service.lancamentos
      segunda_chamada = service.lancamentos

      expect(primeira_chamada).to equal(segunda_chamada)
    end
  end

  describe "indicadores financeiros" do
    it "calcula o total gasto em acessos autorizados" do
      criar_acesso
      criar_acesso

      service = described_class.new(usuario)

      expect(service.total_gasto_centavos).to eq(900)
      expect(service.total_gasto_formatado).to eq("R$ 9,00")
    end

    it "calcula a quantidade de refeições realizadas" do
      criar_acesso
      criar_acesso
      criar_recarga

      expect(
        described_class.new(usuario).refeicoes_realizadas_count
      ).to eq(2)
    end

    it "calcula o total recarregado" do
      criar_recarga
      criar_recarga(valor_centavos: 4500)

      service = described_class.new(usuario)

      expect(service.total_recarregado_centavos).to eq(6750)
      expect(service.total_recarregado_formatado).to eq("R$ 67,50")
    end

    it "formata o saldo atual da carteira" do
      service = described_class.new(usuario)

      expect(service.saldo_atual_formatado).to eq("R$ 22,50")
      expect(service.saldo_atual_refeicoes).to eq(5)
    end

    it "retorna saldo zerado quando o usuário não possui carteira" do
      outro_usuario = Usuario.create!(
        matricula: "221045998",
        nome: "Outro Estudante",
        email: "outro@teste.com",
        password: "password123",
        papel: "estudante",
        ativo: true
      )

      service = described_class.new(outro_usuario)

      expect(service.saldo_atual_formatado).to eq("R$ 0,00")
      expect(service.saldo_atual_refeicoes).to eq(0)
    end
  end

  describe "filtros" do
    it "filtra lançamentos dos últimos 30 dias" do
      criar_recarga(created_at: 40.days.ago)
      criar_recarga(created_at: 10.days.ago)

      lancamentos = described_class.new(
        usuario,
        periodo: "Últimos 30 dias"
      ).lancamentos

      expect(lancamentos.size).to eq(1)
      expect(lancamentos.first.data_hora).to be >= 30.days.ago.beginning_of_day
    end

    it "filtra lançamentos dos últimos 7 dias" do
      criar_recarga(created_at: 10.days.ago)
      criar_recarga(created_at: 2.days.ago)

      lancamentos = described_class.new(
        usuario,
        periodo: "Últimos 7 dias"
      ).lancamentos

      expect(lancamentos.size).to eq(1)
    end

    it "filtra lançamentos do mês atual" do
      criar_recarga(created_at: 40.days.ago)
      criar_recarga(created_at: Time.current)

      lancamentos = described_class.new(
        usuario,
        periodo: "Este mês"
      ).lancamentos

      expect(lancamentos.size).to eq(1)
    end

    it "filtra lançamentos por recarga" do
      criar_recarga
      criar_acesso

      lancamentos = described_class.new(
        usuario,
        tipo_refeicao: "Recarga"
      ).lancamentos

      expect(lancamentos.size).to eq(1)
      expect(lancamentos.first.tipo_registro).to eq(:recarga)
    end

    it "filtra lançamentos pelo tipo de refeição" do
      criar_acesso
      criar_recarga

      lancamentos = described_class.new(
        usuario,
        tipo_refeicao: "Almoço"
      ).lancamentos

      expect(lancamentos.size).to eq(1)
      expect(lancamentos.first.evento).to eq("Almoço")
    end

    it "filtra lançamentos pela forma de acesso" do
      criar_acesso(forma_acesso: "QR Code App")
      criar_acesso(forma_acesso: "Carteirinha Física")

      lancamentos = described_class.new(
        usuario,
        forma_acesso: "Carteirinha"
      ).lancamentos

      expect(lancamentos.size).to eq(1)
      expect(lancamentos.first.forma_acesso).to eq("Carteirinha Física")
    end

    it "não aplica o filtro quando o tipo é Todas" do
      criar_recarga
      criar_acesso

      lancamentos = described_class.new(
        usuario,
        tipo_refeicao: "Todas"
      ).lancamentos

      expect(lancamentos.size).to eq(2)
    end

    it "não aplica o filtro quando a forma de acesso é Todas" do
      criar_acesso(forma_acesso: "QR Code App")
      criar_acesso(forma_acesso: "Carteirinha Física")

      lancamentos = described_class.new(
        usuario,
        forma_acesso: "Todas"
      ).lancamentos

      expect(lancamentos.size).to eq(2)
    end
  end
end
