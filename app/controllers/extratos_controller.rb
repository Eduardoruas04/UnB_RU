# frozen_string_literal: true

# Controller responsável pela Issue #11 (Bônus): Extrato e Exportação em PDF.
# Exibe a interface web com filtros e métricas contábeis (Figma US04), exporta
# o histórico filtrado em PDF timbrado via Prawn e trata cenários de lista vazia
# ou indisponibilidade do serviço gerador.
class ExtratosController < ApplicationController
  before_action :autenticar_usuario!
  before_action :carregar_extrato, only: [ :show, :exportar_pdf ]

  # Exibe o extrato consolidado do estudante (GET /extrato) com os indicadores
  # financeiros de resumo e os lançamentos filtrados.
  #
  # Argumentos:
  # * Nenhum (lê os filtros de URL carregados pelo +before_action :carregar_extrato+).
  #
  # Retorno:
  # * [Integer] Saldo atual em refeições atribuído a +@saldo_refeicoes+.
  #
  # Efeitos colaterais:
  # * Define +@total_gasto+, +@refeicoes_realizadas+, +@total_recarregado+, +@saldo_atual+ e +@saldo_refeicoes+.
  # * Renderiza a view HTML +extratos/show+.
  def show
    @total_gasto = @extrato_service.total_gasto_formatado
    @refeicoes_realizadas = @extrato_service.refeicoes_realizadas_count
    @total_recarregado = @extrato_service.total_recarregado_formatado
    @saldo_atual = @extrato_service.saldo_atual_formatado
    @saldo_refeicoes = @extrato_service.saldo_atual_refeicoes
  end

  # Gera e dispara o download do extrato filtrado em formato PDF (GET /extrato/exportar_pdf),
  # tratando lista vazia e falhas inesperadas do serviço gerador.
  #
  # Argumentos:
  # * Nenhum (utiliza +@usuario+, +@filtros+, +@extrato_service+ e +@lancamentos+).
  #
  # Retorno:
  # * [String] Resposta binária do PDF (quando há registros) ou URL de redirecionamento em caso de alerta/erro.
  #
  # Efeitos colaterais:
  # * Em sucesso, envia o arquivo +application/pdf+ como anexo HTTP.
  # * Em lista vazia ou erro, registra log (em exceções), define +flash[:alert]+ e redireciona para +extrato_path(@filtros)+.
  def exportar_pdf
    return redirecionar_sem_registros if @lancamentos.empty?

    gerar_e_enviar_pdf
  rescue StandardError => e
    tratar_erro_pdf(e)
  end

  private

  # Inicializa o estudante autenticado, os filtros permitidos, o serviço contábil e a lista de lançamentos.
  #
  # Argumentos:
  # * Nenhum (utiliza +current_user+ e +params+).
  #
  # Retorno:
  # * [Array<ExtratoService::Lancamento>] Lista consolidada e filtrada atribuída a +@lancamentos+.
  #
  # Efeitos colaterais:
  # * Define +@usuario+, +@filtros+, +@extrato_service+ e +@lancamentos+.
  # * Executa consultas de leitura nas tabelas +recargas+ e +acessos+.
  def carregar_extrato
    @usuario = current_user
    @filtros = extrair_filtros
    @extrato_service = ExtratoService.new(@usuario, @filtros)
    @lancamentos = @extrato_service.lancamentos
  end

  # Sanitiza e extrai os parâmetros de filtro permitidos da URL da requisição.
  #
  # Argumentos:
  # * Nenhum (lê +params+).
  #
  # Retorno:
  # * [ActionController::Parameters] Parâmetros filtrados contendo apenas +:periodo+, +:tipo_refeicao+ e +:forma_acesso+.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def extrair_filtros
    params.permit(:periodo, :tipo_refeicao, :forma_acesso)
  end

  # Redireciona o estudante de volta ao extrato quando não há lançamentos para exportar.
  #
  # Argumentos:
  # * Nenhum (utiliza +@filtros+).
  #
  # Retorno:
  # * [String] URL de redirecionamento para +extrato_path(@filtros)+.
  #
  # Efeitos colaterais:
  # * Define +flash[:alert]+ com +"Não há registros para exportar"+ e redireciona para +extrato_path(@filtros)+.
  def redirecionar_sem_registros
    flash[:alert] = "Não há registros para exportar"
    redirect_to extrato_path(@filtros)
  end

  # Verifica disponibilidade do gerador, constrói os bytes do PDF e envia como download HTTP.
  #
  # Argumentos:
  # * Nenhum (utiliza +@usuario+ e +@extrato_service+).
  #
  # Retorno:
  # * [String] Corpo binário enviado na resposta HTTP.
  #
  # Efeitos colaterais:
  # * Levanta +StandardError+ quando o serviço de PDF está sinalizado como indisponível.
  # * Envia o binário +application/pdf+ com cabeçalho +Content-Disposition: attachment+.
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

  # Indica se a flag global de simulação de indisponibilidade do serviço de PDF está ativa.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [Boolean, nil] Valor verdade da variável global +$pdf_service_indisponivel+ quando definida; +nil+/+false+ caso contrário.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def servico_pdf_indisponivel?
    defined?($pdf_service_indisponivel) && $pdf_service_indisponivel
  end

  # Registra em log qualquer falha ocorrida durante a geração do PDF e informa o estudante.
  #
  # Argumentos:
  # * +erro+ [StandardError] - Exceção capturada durante a geração ou envio do PDF.
  #
  # Retorno:
  # * [String] URL de redirecionamento para +extrato_path(@filtros)+.
  #
  # Efeitos colaterais:
  # * Escreve a mensagem da exceção em +Rails.logger.error+.
  # * Define +flash[:alert]+ com mensagem amigável e redireciona para +extrato_path(@filtros)+.
  def tratar_erro_pdf(erro)
    Rails.logger.error("Erro na geracao de PDF: #{erro.message}")
    flash[:alert] = "Não foi possível gerar o PDF. Tente novamente"
    redirect_to extrato_path(@filtros)
  end
end
