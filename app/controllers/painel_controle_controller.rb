class PainelControleController < ApplicationController
  before_action :exigir_funcionario_autenticado!

  def index
  end

  private

  def exigir_funcionario_autenticado!
    return if logged_in? && current_user.papel == "funcionario" && current_user.ativo?

    session[:usuario_id] = nil
    redirect_to login_path, alert: "Acesso restrito. Faça login para continuar."
  end
end
