class CatracasController < ApplicationController
  include ControleDeAcesso
  before_action :exigir_administrador
  before_action :carregar_catraca, only: %i[edit update destroy]

  def create
    @catraca = Catraca.new(catraca_params)
    if @catraca.save
      redirect_to restaurantes_path, notice: "Catraca cadastrada com sucesso"
    else
      @restaurantes = Restaurante.includes(:catracas).order(:nome)
      @restaurante = Restaurante.new
      render "restaurantes/index", status: :unprocessable_entity
    end
  end

  def edit
    @restaurantes = Restaurante.order(:nome)
  end

  def update
    if @catraca.update(catraca_params)
      redirect_to restaurantes_path, notice: "Catraca atualizada com sucesso"
    else
      @restaurantes = Restaurante.order(:nome)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @catraca.destroy
    redirect_to restaurantes_path, notice: "Catraca removida com sucesso"
  end

  private

  def carregar_catraca
    @catraca = Catraca.find(params[:id])
  end

  def catraca_params
    params.require(:catraca).permit(:codigo_identificador, :restaurante_id, :status)
  end
end
