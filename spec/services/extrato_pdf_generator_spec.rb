# frozen_string_literal: true

# ==============================================================================
# Testes Unitários de Service (RSpec): ExtratoPdfGenerator (spec/services/extrato_pdf_generator_spec.rb)
# ==============================================================================
# Valida a renderização de PDF institucional via Prawn:
# - Geração de binário PDF válido com dados do estudante, resumo e lançamentos
# - Normalização de acentuação para fontes AFM do Prawn
# - Quebra automática de página quando o volume de lançamentos excede uma página
# ==============================================================================

require "rails_helper"

RSpec.describe ExtratoPdfGenerator, type: :service do
  let(:usuario) do
    Usuario.new(
      matricula: "221045999",
      nome: "João Ávila Conceição",
      email: "joao.avila@unb.br"
    )
  end

  let(:lancamento_credito) do
    ExtratoService::Lancamento.new(
      "recarga-1",
      :recarga,
      Time.current,
      "Recarga de Saldo",
      "Portal Online",
      "PIX Instantâneo",
      :credito,
      4500
    )
  end

  let(:lancamento_debito) do
    ExtratoService::Lancamento.new(
      "acesso-1",
      :acesso,
      Time.current,
      "Almoço",
      "Darcy Ribeiro",
      "QR Code App",
      :debito,
      450
    )
  end

  def build_service_double(lista)
    instance_double(
      ExtratoService,
      lancamentos: lista,
      saldo_atual_formatado: "R$ 40,50",
      saldo_atual_refeicoes: 9,
      total_gasto_formatado: "R$ 4,50",
      refeicoes_realizadas_count: 1,
      total_recarregado_formatado: "R$ 45,00"
    )
  end

  def extrair_texto_pdf(pdf_bytes)
    pdf_bytes.scan(/\[(.*?)\]\s*TJ/m).flatten.map do |bloco|
      bloco.scan(/<([0-9a-fA-F]+)>/).flatten.map { |hex| [ hex ].pack("H*") }.join
    end.join("\n")
  end

  describe "#gerar" do
    it "gera um binário PDF válido com dados normalizados, resumo e lançamentos (Happy Path)" do
      service = build_service_double([ lancamento_credito, lancamento_debito ])
      pdf_bytes = described_class.new(usuario: usuario, extrato_service: service).gerar
      texto = extrair_texto_pdf(pdf_bytes)

      expect(pdf_bytes).to start_with("%PDF-")
      expect(texto).to include("Joao Avila Conceicao")
      expect(texto).to include("221045999")
      expect(texto).to include("Total Gasto: R$ 4,50")
      expect(texto).to include("LANCAMENTOS REGISTRADOS (2)")
      expect(texto).to include("Almoco")
      expect(texto).to include("Recarga de Saldo")
    end

    it "realiza quebra automática de página quando há muitos lançamentos" do
      muitos_lancamentos = Array.new(45) do |idx|
        idx.even? ? lancamento_credito : lancamento_debito
      end
      service = build_service_double(muitos_lancamentos)

      pdf_bytes = described_class.new(usuario: usuario, extrato_service: service).gerar
      texto = extrair_texto_pdf(pdf_bytes)

      expect(pdf_bytes).to start_with("%PDF-")
      expect(texto).to include("LANCAMENTOS REGISTRADOS (45)")
      expect(pdf_bytes.scan("/Type /Page\n").size).to be >= 2
    end
  end
end
