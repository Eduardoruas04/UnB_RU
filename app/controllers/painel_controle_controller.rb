# Controlador responsável pela área administrativa restrita aos funcionários do RU.
#
# Garante que apenas usuários autenticados com papel de funcionário e cadastro ativo
# acessem as funcionalidades do painel de controle.
class PainelControleController < ApplicationController
  before_action :exigir_funcionario_autenticado!

  # Exibe a página inicial do painel de controle administrativo.
  #
  # Argumentos::
  #   Nenhum argumento direto; depende da sessão validada pelo filtro +exigir_funcionario_autenticado!+.
  # Retorno::
  #   Renderiza implicitamente a view +painel_controle/index+ (HTTP 200).
  # Efeitos colaterais::
  #   Nenhum efeito colateral no banco de dados ou na sessão.
  def index
  end

  private

  # Filtro de autorização que bloqueia visitantes ou usuários sem permissão administrativa.
  #
  # Argumentos::
  #   Nenhum argumento direto; inspeciona +logged_in?+ e +current_user+.
  # Retorno::
  #   Retorna +nil+ permitindo seguir a ação caso autorizado, ou redireciona
  #   para +login_path+ (HTTP 302) caso não autorizado.
  # Efeitos colaterais::
  #   Quando não autorizado, limpa +session[:usuario_id]+, define +flash[:alert]+
  #   e interrompe o ciclo da requisição via redirecionamento.
  def exigir_funcionario_autenticado!
    return if funcionario_autorizado?

    session[:usuario_id] = nil
    redirect_to login_path, alert: "Acesso restrito. Faça login para continuar."
  end

  # Verifica se o usuário atual está autenticado, ativo e possui papel de funcionário.
  #
  # Argumentos::
  #   Nenhum argumento direto; consulta os helpers +logged_in?+ e +current_user+.
  # Retorno::
  #   Booleano (+true+ se for funcionário autenticado e ativo; +false+ caso contrário).
  # Efeitos colaterais::
  #   Pode acionar consulta de leitura em +usuarios+ via +current_user+.
  def funcionario_autorizado?
    logged_in? && current_user.papel == "funcionario" && current_user.ativo?
  end
end