class AvaliacoesController < ApplicationController
  before_action :exigir_usuario_autenticado!

  def new
    @avaliacao = Avaliacao.new
  end

  def create
    @avaliacao = Avaliacao.new(avaliacao_params)
    acesso_hoje = buscar_acesso_disponivel_hoje

    if acesso_hoje.nil?
      flash.now[:alert] = "Você precisa ter consumido uma refeição hoje para avaliar"
      return render :new, status: :unprocessable_entity
    end

    if avaliacao_params[:nota].blank?
      flash.now[:alert] = "Selecione uma nota para a refeição"
      return render :new, status: :unprocessable_entity
    end

    @avaliacao.usuario = current_user
    @avaliacao.acesso = acesso_hoje

    if @avaliacao.save
      redirect_to new_avaliacao_path, notice: "Obrigado pelo seu feedback!"
    else
      flash.now[:alert] = "Selecione uma nota para a refeição"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def exigir_usuario_autenticado!
    return if logged_in?

    redirect_to login_path, alert: "Faça login para avaliar a refeição"
  end

  def avaliacao_params
    params.require(:avaliacao).permit(:nota, :comentario)
  end

  def buscar_acesso_disponivel_hoje
    current_user.acessos
                .where(autorizado: true, data_hora: Time.current.all_day)
                .where.not(id: Avaliacao.select(:acesso_id))
                .order(data_hora: :desc)
                .first
  end
end
