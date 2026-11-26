# Controller responsável por exibir o histórico de acessos de uma catraca
# selecionada para funcionários autenticados.
class HistoricosController < ApplicationController
  include ControleDeAcesso
  before_action :exigir_funcionario

  # Exibe os acessos de uma catraca específica ou orienta a seleção/ajuste
  # quando não há catraca válida ou quando não existem registros.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +params[:catraca_id]+ e
  #   +session[:catraca_id]+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação de controller Rails; pode
  #   encerrar a execução precocemente via +return+ quando a catraca não está
  #   selecionada ou não é encontrada).
  # Efeitos colaterais::
  #   Atualiza +session[:catraca_id]+ se +params[:catraca_id]+ estiver
  #   presente, remove +:catraca_id+ da sessão se a catraca for inválida,
  #   realiza consultas no banco e preenche +@catracas+, +@catraca+,
  #   +@acessos+ e +@mensagem+.
  def show
    atualizar_catraca_selecionada
    @catracas = Catraca.includes(:restaurante).order(:codigo_identificador)

    if session[:catraca_id].blank?
      @mensagem = "Selecione uma catraca para ver o histórico"
      return
    end

    @catraca = Catraca.find_by(id: session[:catraca_id])
    return if catraca_invalida?

    carregar_acessos
  end

  private

  # :doc:
  # Atualiza o identificador da catraca na sessão caso venha preenchido nos
  # parâmetros da requisição.
  #
  # Argumentos::
  #   Nenhum argumento explícito (lê +params[:catraca_id]+).
  # Retorno::
  #   O valor gravado em +session[:catraca_id]+ se +params[:catraca_id]+
  #   estiver presente, ou +nil+ caso contrário.
  # Efeitos colaterais::
  #   Altera +session[:catraca_id]+ quando +params[:catraca_id].present?+ é
  #   verdadeiro.
  def atualizar_catraca_selecionada
    session[:catraca_id] = params[:catraca_id] if params[:catraca_id].present?
  end

  # :doc:
  # Verifica se +@catraca+ não foi encontrada e, nesse caso, limpa a sessão e
  # define a mensagem de erro correspondente.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@catraca+ e +session+).
  # Retorno::
  #   Retorna +true+ quando +@catraca+ é +nil+; caso contrário, retorna +nil+.
  # Efeitos colaterais::
  #   Remove +:catraca_id+ de +session+ e atribui a mensagem de catraca não
  #   encontrada a +@mensagem+ quando +@catraca+ é +nil+.
  def catraca_invalida?
    return unless @catraca.nil?

    session.delete(:catraca_id)
    @mensagem = "Catraca não encontrada"
    true
  end

  # :doc:
  # Carrega os acessos da catraca atual em ordem decrescente de data e hora e
  # define uma mensagem caso não haja acessos.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@catraca+).
  # Retorno::
  #   A mensagem de ausência de acessos se +@acessos+ estiver vazio, ou +nil+
  #   caso contrário.
  # Efeitos colaterais::
  #   Consulta os acessos e usuários associados a +@catraca+ no banco e
  #   atribui +@acessos+ (e +@mensagem+ quando vazio).
  def carregar_acessos
    @acessos = @catraca.acessos.includes(:usuario).order(data_hora: :desc)
    @mensagem = "Nenhum acesso registrado nesta catraca" if @acessos.empty?
  end
end