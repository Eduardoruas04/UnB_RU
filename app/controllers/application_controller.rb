# Controller base da aplicação UnB RU. Centraliza os auxiliares de sessão e
# autenticação compartilhados entre todos os controllers e views.
class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  # Retorna o usuário autenticado na sessão atual, armazenando o resultado em
  # cache na instância do controller durante o ciclo da requisição.
  #
  # Argumentos:
  # * Nenhum (lê +session[:usuario_id]+).
  #
  # Retorno:
  # * [Usuario, nil] Instância do usuário autenticado ou +nil+ quando não há sessão ativa.
  #
  # Efeitos colaterais:
  # * Consulta a tabela +usuarios+ no banco na primeira chamada da requisição e memoriza em +@current_user+.
  def current_user
    @current_user ||= Usuario.find_by(id: session[:usuario_id]) if session[:usuario_id]
  end

  # Informa se existe um usuário autenticado na sessão atual.
  #
  # Argumentos:
  # * Nenhum (utiliza +#current_user+).
  #
  # Retorno:
  # * [Boolean] +true+ quando há usuário autenticado; +false+ caso contrário.
  #
  # Efeitos colaterais:
  # * Pode disparar a consulta de +#current_user+ caso ainda não tenha sido carregado.
  def logged_in?
    current_user.present?
  end

  # Filtro de proteção que exige sessão autenticada antes de executar uma action,
  # redirecionando visitantes não autenticados para a tela de login.
  #
  # Argumentos:
  # * Nenhum (verifica +#logged_in?+).
  #
  # Retorno:
  # * [String, nil] URL de redirecionamento para +"/login"+ quando deslogado, ou +nil+ quando autenticado.
  #
  # Efeitos colaterais:
  # * Quando não há sessão ativa, define +flash[:alert]+ e redireciona para +"/login"+.
  def autenticar_usuario!
    unless logged_in?
      flash[:alert] = "Você precisa estar autenticado para acessar esta página."
      redirect_to "/login"
    end
  end
end
