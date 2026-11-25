# Controlador responsável pelo fluxo de avaliação das refeições do Restaurante Universitário.
#
# Permite que usuários autenticados que registraram acesso autorizado no dia atual
# enviem uma nota e um comentário opcional sobre a refeição consumida.
class AvaliacoesController < ApplicationController
  before_action :exigir_usuario_autenticado!

  # Exibe o formulário de avaliação de refeição.
  #
  # Argumentos::
  #   Nenhum argumento direto; utiliza o usuário autenticado na sessão.
  # Retorno::
  #   Renderiza implicitamente a view +avaliacoes/new+ (HTTP 200).
  # Efeitos colaterais::
  #   Instancia +@avaliacao+ em memória sem persistir no banco de dados.
  def new
    @avaliacao = Avaliacao.new
  end

  # Valida as regras de negócio e registra uma nova avaliação de refeição.
  #
  # Argumentos::
  #   Nenhum argumento direto; lê +params[:avaliacao]+ (+:nota+ e +:comentario+).
  # Retorno::
  #   Redireciona para +new_avaliacao_path+ (HTTP 302) em caso de sucesso ou
  #   renderiza +:new+ com status +:unprocessable_entity+ (HTTP 422) em caso de falha.
  # Efeitos colaterais::
  #   Insere um registro na tabela +avaliacoes+ vinculado ao usuário e ao acesso
  #   do dia no sucesso, ou preenche +flash.now[:alert]+ em caso de erro.
  def create
    @avaliacao = Avaliacao.new(avaliacao_params)
    acesso_hoje = buscar_acesso_disponivel_hoje

    return renderizar_erro_avaliacao("Você precisa ter consumido uma refeição hoje para avaliar") if acesso_hoje.nil?
    return renderizar_erro_avaliacao("Selecione uma nota para a refeição") if avaliacao_params[:nota].blank?

    salvar_avaliacao(acesso_hoje)
  end

  private

  # Filtro que exige um usuário logado antes de acessar o formulário ou enviar avaliação.
  #
  # Argumentos::
  #   Nenhum argumento direto; consulta o helper +logged_in?+.
  # Retorno::
  #   Retorna +nil+ se autenticado ou redireciona para +login_path+ (HTTP 302).
  # Efeitos colaterais::
  #   Define +flash[:alert]+ e interrompe a ação via redirecionamento quando não logado.
  def exigir_usuario_autenticado!
    return if logged_in?

    redirect_to login_path, alert: "Faça login para avaliar a refeição"
  end

  # Filtra e permite apenas os parâmetros seguros enviados pelo formulário de avaliação.
  #
  # Argumentos::
  #   Nenhum argumento direto; extrai +:avaliacao+ de +params+.
  # Retorno::
  #   Instância de +ActionController::Parameters+ contendo +:nota+ e +:comentario+.
  # Efeitos colaterais::
  #   Lança +ActionController::ParameterMissing+ se a chave +:avaliacao+ estiver ausente.
  def avaliacao_params
    params.require(:avaliacao).permit(:nota, :comentario)
  end

  # Busca o acesso autorizado mais recente do usuário no dia atual ainda não avaliado.
  #
  # Argumentos::
  #   Nenhum argumento direto; utiliza +current_user+ e +Time.current.all_day+.
  # Retorno::
  #   Instância de +Acesso+ elegível para avaliação ou +nil+ se nenhum for encontrado.
  # Efeitos colaterais::
  #   Executa consulta de leitura nas tabelas +acessos+ e +avaliacoes+.
  def buscar_acesso_disponivel_hoje
    current_user.acessos
                .where(autorizado: true, data_hora: Time.current.all_day)
                .where.not(id: Avaliacao.select(:acesso_id))
                .order(data_hora: :desc)
                .first
  end

  # Associa usuário e acesso à avaliação e tenta persistir no banco de dados.
  #
  # Argumentos::
  #   +acesso_hoje+:: Instância de +Acesso+ autorizado no dia atual.
  # Retorno::
  #   Redireciona para +new_avaliacao_path+ no sucesso ou renderiza +:new+ (HTTP 422).
  # Efeitos colaterais::
  #   Persiste o registro em +avaliacoes+ e define +flash[:notice]+ ou +flash.now[:alert]+.
  def salvar_avaliacao(acesso_hoje)
    @avaliacao.usuario = current_user
    @avaliacao.acesso = acesso_hoje

    if @avaliacao.save
      redirect_to new_avaliacao_path, notice: "Obrigado pelo seu feedback!"
    else
      renderizar_erro_avaliacao("Selecione uma nota para a refeição")
    end
  end

  # Reexibe o formulário de avaliação com mensagem de validação.
  #
  # Argumentos::
  #   +mensagem+:: String com o alerta de validação a ser exibido.
  # Retorno::
  #   Renderiza +:new+ com status +:unprocessable_entity+ (HTTP 422).
  # Efeitos colaterais::
  #   Preenche +flash.now[:alert]+ com a mensagem informada.
  def renderizar_erro_avaliacao(mensagem)
    flash.now[:alert] = mensagem
    render :new, status: :unprocessable_entity
  end
end