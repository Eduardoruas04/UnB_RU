module ControleDeAcesso
  extend ActiveSupport::Concern

  private

  def exigir_administrador
    return redirect_to("/login") unless logged_in?

    unless current_user.papel == "administrador"
      redirect_to root_path, alert: "Acesso restrito a administradores"
    end
  end

  def exigir_funcionario
    return redirect_to("/login") unless logged_in?

    unless %w[funcionario administrador].include?(current_user.papel)
      redirect_to root_path, alert: "Acesso restrito a funcionários"
    end
  end
end