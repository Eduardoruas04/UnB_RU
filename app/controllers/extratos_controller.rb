# frozen_string_literal: true

# ==============================================================================
# Controller do Extrato do Estudante (app/controllers/extratos_controller.rb)
# ==============================================================================
# Responsável por:
# 1. Renderizar a interface web com filtros e métricas (Figma US04)
# 2. Exportar o histórico consolidado em formato PDF (Prawn)
# 3. Validar privacidade do aluno e tratar cenários de lista vazia / falha de serviço
# ==============================================================================
class ExtratosController < ApplicationController
  before_action :autenticar_usuario!
  before_action :carregar_extrato, only: [ :show, :exportar_pdf ]

  # GET /extrato
  # Exibe o extrato consolidado com cards de resumo e filtros interativos
  def show
    @total_gasto = @extrato_service.total_gasto_formatado
    @refeicoes_realizadas = @extrato_service.refeicoes_realizadas_count
    @total_recarregado = @extrato_service.total_recarregado_formatado
    @saldo_atual = @extrato_service.saldo_atual_formatado
    @saldo_refeicoes = @extrato_service.saldo_atual_refeicoes
  end

  # GET /extrato/exportar_pdf
  # Gera e dispara o download do arquivo PDF filtrado
  def exportar_pdf
    return redirecionar_sem_registros if @lancamentos.empty?

    gerar_e_enviar_pdf
  rescue StandardError => e
    tratar_erro_pdf(e)
  end

  private

  def carregar_extrato
    @usuario = current_user
    @filtros = extrair_filtros
    @extrato_service = ExtratoService.new(@usuario, @filtros)
    @lancamentos = @extrato_service.lancamentos
  end

  # Sanitiza e extrai os parâmetros de filtro da URL
  def extrair_filtros
    params.permit(:periodo, :tipo_refeicao, :forma_acesso)
  end

  def redirecionar_sem_registros
    flash[:alert] = "Não há registros para exportar"
    redirect_to extrato_path(@filtros)
  end

  def gerar_e_enviar_pdf
    raise StandardError, "Serviço indisponível" if servico_pdf_indisponivel?

    pdf_bytes = ExtratoPdfGenerator.new(usuario: @usuario, extrato_service: @extrato_service).gerar
    send_data(
      pdf_bytes,
      filename: "extrato_refeicoes_#{@usuario.matricula}.pdf",
      type: "application/pdf",
      disposition: "attachment"
    )
  end

  def servico_pdf_indisponivel?
    defined?($pdf_service_indisponivel) && $pdf_service_indisponivel
  end

  def tratar_erro_pdf(erro)
    Rails.logger.error("Erro na geracao de PDF: #{erro.message}")
    flash[:alert] = "Não foi possível gerar o PDF. Tente novamente"
    redirect_to extrato_path(@filtros)
  end
end
