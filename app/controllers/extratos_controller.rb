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

  # GET /extrato
  # Exibe o extrato consolidado com cards de resumo e filtros interativos
  def show
    @usuario = current_user
    @filtros = extrair_filtros
    @extrato_service = ExtratoService.new(@usuario, @filtros)

    @lancamentos = @extrato_service.lancamentos
    @total_gasto = @extrato_service.total_gasto_formatado
    @refeicoes_realizadas = @extrato_service.refeicoes_realizadas_count
    @total_recarregado = @extrato_service.total_recarregado_formatado
    @saldo_atual = @extrato_service.saldo_atual_formatado
    @saldo_refeicoes = @extrato_service.saldo_atual_refeicoes
  end

  # GET /extrato/exportar_pdf
  # Gera e dispara o download do arquivo PDF filtrado
  def exportar_pdf
    @usuario = current_user
    @filtros = extrair_filtros
    @extrato_service = ExtratoService.new(@usuario, @filtros)
    @lancamentos = @extrato_service.lancamentos

    # Cenários Tristes 5 e 6: filtro sem resultados ou histórico zerado
    if @lancamentos.empty?
      flash[:alert] = "Não há registros para exportar"
      redirect_to extrato_path(@filtros)
      return
    end

    # Cenário Triste 8: tratamento de falha no serviço gerador de PDF
    begin
      raise StandardError, "Serviço indisponível" if defined?($pdf_service_indisponivel) && $pdf_service_indisponivel

      pdf_bytes = ExtratoPdfGenerator.new(usuario: @usuario, extrato_service: @extrato_service).gerar
      send_data(
        pdf_bytes,
        filename: "extrato_refeicoes_#{@usuario.matricula}.pdf",
        type: "application/pdf",
        disposition: "attachment"
      )
    rescue StandardError => e
      Rails.logger.error("Erro na geracao de PDF: #{e.message}")
      flash[:alert] = "Não foi possível gerar o PDF. Tente novamente"
      redirect_to extrato_path(@filtros)
    end
  end

  private

  # Sanitiza e extrai os parâmetros de filtro da URL
  def extrair_filtros
    params.permit(:periodo, :tipo_refeicao, :forma_acesso)
  end
end
