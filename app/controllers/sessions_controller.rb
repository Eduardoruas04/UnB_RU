class SessionsController < ApplicationController
  def new
  end

  def create
    matricula = params[:matricula].to_s.strip
    senha = params[:password].to_s

    if matricula.blank? || senha.blank?
      flash.now[:alert] = "Matrícula e senha são obrigatórias"
      return render :new, status: :unprocessable_entity
    end

    usuario = Usuario.find_by(matricula: matricula)

    if usuario.nil? || usuario.papel != "funcionario" || !usuario.authenticate(senha)
      flash.now[:alert] = "Matrícula ou senha inválidos"
      return render :new, status: :unprocessable_entity
    end

    unless usuario.ativo?
      flash.now[:alert] = "Conta de funcionário inativa"
      return render :new, status: :unprocessable_entity
    end

    session[:usuario_id] = usuario.id
    redirect_to painel_controle_path, notice: "Login realizado com sucesso"
  end

  def destroy
    session[:usuario_id] = nil
    redirect_to login_path, notice: "Sessão encerrada com sucesso"
  end
end
