class HistoricosController < ApplicationController
  include ControleDeAcesso
  before_action :exigir_funcionario

  def show
    session[:catraca_id] = params[:catraca_id] if params[:catraca_id].present?
    @catracas = Catraca.includes(:restaurante).order(:codigo_identificador)

    if session[:catraca_id].blank?
      @mensagem = "Selecione uma catraca para ver o histórico"
      return
    end

    @catraca = Catraca.find_by(id: session[:catraca_id])
    if @catraca.nil?
      session.delete(:catraca_id)
      @mensagem = "Catraca não encontrada"
      return
    end

    @acessos = @catraca.acessos.includes(:usuario).order(data_hora: :desc)
    @mensagem = "Nenhum acesso registrado nesta catraca" if @acessos.empty?
  end
end