# Controller da página inicial (Portal UnB RU) e dos atalhos de sessão rápida
# utilizados em desenvolvimento e nos testes automatizados.
class HomeController < ApplicationController
  # Exibe a página inicial do sistema com a listagem de usuários disponíveis
  # para acesso rápido e atalhos dos módulos do RU.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [ActiveRecord::Relation<Usuario>] Coleção de usuários atribuída a +@usuarios+.
  #
  # Efeitos colaterais:
  # * Executa consulta de leitura na tabela +usuarios+, define +@usuarios+ e renderiza +home/index+.
  def index
    @usuarios = Usuario.all
  end

  # Inicia rapidamente uma sessão autenticada para o usuário escolhido no menu
  # de desenvolvimento ou em testes de requisição.
  #
  # Argumentos:
  # * Nenhum (lê +params[:usuario_id]+).
  #
  # Retorno:
  # * [String] URL de redirecionamento para +root_path+.
  #
  # Efeitos colaterais:
  # * Busca o usuário no banco, grava +session[:usuario_id]+, define +flash[:notice]+ e redireciona para +root_path+.
  def dev_login
    usuario = Usuario.find(params[:usuario_id])
    session[:usuario_id] = usuario.id
    flash[:notice] = "Sessão iniciada como #{usuario.nome} (#{usuario.papel.upcase})"
    redirect_to root_path
  end

  # Encerra a sessão ativa criada pelo login rápido e retorna para a página inicial.
  #
  # Argumentos:
  # * Nenhum.
  #
  # Retorno:
  # * [String] URL de redirecionamento para +root_path+.
  #
  # Efeitos colaterais:
  # * Limpa +session[:usuario_id]+, define +flash[:notice]+ e redireciona para +root_path+.
  def dev_logout
    session[:usuario_id] = nil
    flash[:notice] = "Sessão encerrada com sucesso."
    redirect_to root_path
  end
end
