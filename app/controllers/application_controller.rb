class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  def current_user
    @current_user ||= Usuario.find_by(id: session[:usuario_id]) if session[:usuario_id]
  end

  def logged_in?
    current_user.present?
  end

  def autenticar_usuario!
    unless logged_in?
      flash[:alert] = "Você precisa estar autenticado para acessar esta página."
      redirect_to "/login"
    end
  end
end
