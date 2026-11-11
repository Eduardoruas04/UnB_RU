class NotificacoesController < ApplicationController
  before_action :exigir_estudante

  def index
    @notificacoes = current_user.notificacoes.where(tipo: "fastpass", status_envio: "enviada").order(enviado_em: :desc, id: :desc)
  end

  private

  def exigir_estudante
    unless logged_in?
      redirect_to root_path, alert: "Entre como estudante para consultar suas notificações."
      return
    end

    head :forbidden unless current_user.papel == "estudante"
  end
end
