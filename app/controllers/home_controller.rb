class HomeController < ApplicationController
  def index
    @usuarios = Usuario.all
  end

  # Ação para o botão de Login Rápido (Menu Dev)
  def dev_login
    usuario = Usuario.find(params[:usuario_id])
    session[:usuario_id] = usuario.id
    flash[:notice] = "Sessão iniciada como #{usuario.nome} (#{usuario.papel.upcase})"
    redirect_to root_path
  end

  def dev_logout
    session[:usuario_id] = nil
    flash[:notice] = "Sessão encerrada com sucesso."
    redirect_to root_path
  end
end
