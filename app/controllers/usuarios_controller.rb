class UsuariosController < ApplicationController
  def new
    @usuario = Usuario.new
  end

  def create
    @usuario = Usuario.new(usuario_params)
    @usuario.papel = "estudante"
    @usuario.ativo = true

    Usuario.transaction do
      @usuario.save!
      @usuario.create_carteira!(saldo_centavos: 0)
    end

    redirect_to root_path, notice: "Cadastro realizado com sucesso", status: :see_other
  rescue ActiveRecord::RecordInvalid => erro
    if erro.record != @usuario
      @usuario.errors.add(:base, "Não foi possível criar a carteira. Tente novamente.")
    end
    render :new, status: :unprocessable_content
  end

  private

  def usuario_params
    params.require(:usuario).permit(:nome, :matricula, :email, :password, :password_confirmation)
  end
end
