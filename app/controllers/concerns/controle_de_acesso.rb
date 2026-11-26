# Concern responsável pelo controle de autorização baseado no papel do usuário
# autenticado nos controllers da aplicação.
#
# Fornece filtros (+before_action+) para restringir o acesso de ações apenas
# a administradores ou a funcionários e administradores.
module ControleDeAcesso
  extend ActiveSupport::Concern

  private

  # Verifica se há um usuário autenticado com papel de administrador.
  #
  # Argumentos:
  #   Nenhum (utiliza os helpers +logged_in?+ e +current_user+ do controller).
  # Retorno:::
  #   +nil+ quando o acesso é permitido; caso contrário, retorna o resultado
  #   do redirecionamento HTTP.
  # Efeitos colaterais::
  #   Redireciona para +/login+ se o usuário não estiver autenticado, ou para
  #   +root_path+ com mensagem de alerta se o papel não for +"administrador"+.
  #
  # :doc:
  def exigir_administrador
    return redirect_to("/login") unless logged_in?

    unless current_user.papel == "administrador"
      redirect_to root_path, alert: "Acesso restrito a administradores"
    end
  end

  # Verifica se há um usuário autenticado com papel de funcionário ou
  # administrador.
  #
  # Argumentos::
  #   Nenhum (utiliza os helpers +logged_in?+ e +current_user+ do controller).
  # Retorno::
  #   +nil+ quando o acesso é permitido; caso contrário, retorna o resultado
  #   do redirecionamento HTTP.
  # Efeitos colaterais::
  #   Redireciona para +/login+ se o usuário não estiver autenticado, ou para
  #   +root_path+ com mensagem de alerta se o papel não for +"funcionario"+
  #   nem +"administrador"+.
  #
  # :doc:
  def exigir_funcionario
    return redirect_to("/login") unless logged_in?

    unless %w[funcionario administrador].include?(current_user.papel)
      redirect_to root_path, alert: "Acesso restrito a funcionários"
    end
  end
end