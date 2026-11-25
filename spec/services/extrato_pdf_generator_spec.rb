
require "rails_helper"

RSpec.describe ExtratoPdfGenerator, type: :service do
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

  def criar_recarga
    usuario.recargas.create!(
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 2250,
      status: "paga",
      metodo_pagamento: "PIX Instantâneo"
    )
  end

  def criar_acesso
    usuario.acessos.create!(
      catraca: catraca,
      turno: turno,
      data_hora: Time.current,
      autorizado: true,
      valor_pago_centavos: 450,
      forma_acesso: "QR Code App"
    )
  end

  def gerar_pdf
    service = ExtratoService.new(usuario)
    described_class.new(
      usuario: usuario,
      extrato_service: service
    ).gerar
  end

  describe "geração do documento" do
    it "gera um PDF válido em formato binário" do
      criar_recarga
      criar_acesso

      pdf = gerar_pdf

      expect(pdf).to be_a(String)
      expect(pdf).to start_with("%PDF-")
      expect(pdf.bytesize).to be > 0
    end

    it "gera o documento mesmo sem lançamentos" do
      pdf = gerar_pdf

      expect(pdf).to be_a(String)
      expect(pdf).to start_with("%PDF-")
    end

    it "gera o documento com lançamentos de crédito e débito" do
      criar_recarga
      criar_acesso

      pdf = gerar_pdf

      expect(pdf).to start_with("%PDF-")
    end
  end

  describe "normalização de caracteres" do
    it "remove acentos de caracteres maiúsculos e minúsculos" do
      service = ExtratoService.new(usuario)
      generator = described_class.new(
        usuario: usuario,
        extrato_service: service
      )

      resultado = generator.send(
        :normalizar,
        "Brasília, Almoço, Refeição, Coração"
      )

      expect(resultado).to eq("Brasilia, Almoco, Refeicao, Coracao")
    end

    it "converte valores não textuais para string" do
      service = ExtratoService.new(usuario)
      generator = described_class.new(
        usuario: usuario,
        extrato_service: service
      )

      expect(generator.send(:normalizar, 123)).to eq("123")
    end
  end

  describe "paginação" do
    it "cria novas páginas quando existem muitos lançamentos" do
      40.times { criar_acesso }

      pdf = gerar_pdf

      expect(pdf).to start_with("%PDF-")
      expect(pdf.scan(/\/Type\s*\/Page\b/).size).to be > 1
    end
  end
end
