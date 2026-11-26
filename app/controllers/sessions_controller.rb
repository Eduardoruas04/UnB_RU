# Controlador responsável pela autenticação de funcionários do Restaurante Universitário.
#
# Gerencia a exibição do formulário de login, a validação de credenciais
# (matrícula, senha, papel e status ativo) e o encerramento da sessão.
class SessionsController < ApplicationController
  # Exibe o formulário de autenticação de funcionário.
  #
  # Argumentos::
  #   Nenhum argumento direto; utiliza o contexto da requisição HTTP GET.
  # Retorno::
  #   Renderiza implicitamente a view +sessions/new+ (HTTP 200).
  # Efeitos colaterais::
  #   Nenhum efeito colateral no banco de dados ou na sessão.
  def new
  end

  # Processa a tentativa de login de um funcionário.
  #
  # Argumentos::
  #   Nenhum argumento direto; lê +params[:matricula]+ e +params[:password]+ da requisição.
  # Retorno::
  #   Redireciona para +painel_controle_path+ em caso de sucesso ou renderiza
  #   +:new+ com status +:unprocessable_entity+ (HTTP 422) em caso de falha.
  # Efeitos colaterais::
  #   Grava +session[:usuario_id]+ e define +flash[:notice]+ no sucesso, ou
  #   preenche +flash.now[:alert]+ em caso de erro de validação.
  def create
    matricula = params[:matricula].to_s.strip
    senha = params[:password].to_s

    return renderizar_erro_login("Matrícula e senha são obrigatórias") unless credenciais_preenchidas?(matricula, senha)

    usuario = autenticar_funcionario(matricula, senha)
    return renderizar_erro_login("Matrícula ou senha inválidos") if usuario.nil?
    return renderizar_erro_login("Conta de funcionário inativa") unless usuario.ativo?

    iniciar_sessao(usuario)
  end

  # Encerra a sessão autenticada do funcionário atual.
  #
  # Argumentos::
  #   Nenhum argumento direto; utiliza a sessão ativa da requisição.
  # Retorno::
  #   Redireciona para +login_path+ (HTTP 302).
  # Efeitos colaterais::
  #   Limpa +session[:usuario_id]+ e define +flash[:notice]+ com mensagem de encerramento.
  def destroy
    session[:usuario_id] = nil
    redirect_to login_path, notice: "Sessão encerrada com sucesso"
  end

  private

  # Verifica se matrícula e senha foram informadas pelo usuário.
  #
  # Argumentos::
  #   +matricula+:: String contendo a matrícula informada.
  #   +senha+:: String contendo a senha informada.
  # Retorno::
  #   Booleano (+true+ se ambos estiverem preenchidos; +false+ caso contrário).
  # Efeitos colaterais::
  #   Nenhum efeito colateral.
  def credenciais_preenchidas?(matricula, senha)
    matricula.present? && senha.present?
  end

  # Localiza o usuário pela matrícula e valida seu papel e senha.
  #
  # Argumentos::
  #   +matricula+:: String com a matrícula do funcionário.
  #   +senha+:: String com a senha em texto plano para verificação via +has_secure_password+.
  # Retorno::
  #   Instância de +Usuario+ se encontrado, com papel +"funcionario"+ e senha válida;
  #   +nil+ caso contrário.
  # Efeitos colaterais::
  #   Executa consulta de leitura na tabela +usuarios+.
  def autenticar_funcionario(matricula, senha)
    usuario = Usuario.find_by(matricula: matricula)
    return nil if usuario.nil? || usuario.papel != "funcionario" || !usuario.authenticate(senha)

    usuario
  end

  # Registra o identificador do funcionário na sessão e redireciona ao painel.
  #
  # Argumentos::
  #   +usuario+:: Instância autenticada e ativa de +Usuario+.
  # Retorno::
  #   Redireciona para +painel_controle_path+ (HTTP 302).
  # Efeitos colaterais::
  #   Grava +session[:usuario_id]+ e define +flash[:notice]+.
  def iniciar_sessao(usuario)
    session[:usuario_id] = usuario.id
    redirect_to painel_controle_path, notice: "Login realizado com sucesso"
  end

  # Exibe novamente a tela de login com uma mensagem de alerta.
  #
  # Argumentos::
  #   +mensagem+:: String com o texto de erro exibido ao usuário.
  # Retorno::
  #   Renderiza +:new+ com status +:unprocessable_entity+ (HTTP 422).
  # Efeitos colaterais::
  #   Define +flash.now[:alert]+ com a mensagem informada.
  def renderizar_erro_login(mensagem)
    flash.now[:alert] = mensagem
    render :new, status: :unprocessable_entity
  end
end
