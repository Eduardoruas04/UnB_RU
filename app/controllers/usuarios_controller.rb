# Recebe cadastros de estudantes e apresenta o formulário de inscrição.
class UsuariosController < ApplicationController
  # [Descrição] Prepara o formulário de cadastro.
  # [Argumentos] Nenhum.
  # [Retorno] Um Usuario novo, ainda sem persistência.
  # [Efeitos colaterais] Define +@usuario+ para a view, que o Rails renderiza implicitamente.
  def new
    @usuario = Usuario.new
  end

  # [Descrição] Cadastra um estudante ativo e sua carteira zerada em uma transação.
  # [Argumentos] Nenhum argumento Ruby. Lê os dados de +params[:usuario]+.
  # [Retorno] O status 303 no sucesso ou o conteúdo HTML do formulário em caso de validação inválida.
  # [Efeitos colaterais] Persiste usuário e carteira juntos e redireciona com aviso de sucesso. Se a validação impedir a gravação, desfaz a transação e renderiza o formulário com status 422.
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

  # [Descrição] Filtra os campos aceitos no cadastro.
  # [Argumentos] Nenhum argumento Ruby. Lê +params+ da requisição.
  # [Retorno] Um ActionController::Parameters permitido. Lança ActionController::ParameterMissing se +usuario+ estiver ausente ou vazio.
  # [Efeitos colaterais] Nenhum.
  def usuario_params
    params.require(:usuario).permit(:nome, :matricula, :email, :password, :password_confirmation)
  end
end
