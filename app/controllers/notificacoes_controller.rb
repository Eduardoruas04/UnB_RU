# Exibe as notificações FastPass do estudante autenticado.
class NotificacoesController < ApplicationController
  before_action :exigir_estudante

  # [Descrição] Seleciona notificações FastPass enviadas ao estudante, da mais recente à mais antiga.
  # [Argumentos] Nenhum.
  # [Retorno] Uma relação ActiveRecord de notificações, possivelmente vazia.
  # [Efeitos colaterais] Define +@notificacoes+ para a view, que o Rails renderiza implicitamente.
  def index
    @notificacoes = current_user.notificacoes.where(tipo: "fastpass", status_envio: "enviada").order(enviado_em: :desc, id: :desc)
  end

  private

  # [Descrição] Restringe a consulta a estudantes autenticados.
  # [Argumentos] Nenhum.
  # [Retorno] Retorna +true+ ao responder com 403 e +nil+ ao redirecionar ou liberar a consulta.
  # [Efeitos colaterais] Redireciona visitantes à página inicial com alerta e responde com 403 para usuários autenticados de outros papéis.
  def exigir_estudante
    unless logged_in?
      redirect_to root_path, alert: "Entre como estudante para consultar suas notificações."
      return
    end

    head :forbidden unless current_user.papel == "estudante"
  end
end
