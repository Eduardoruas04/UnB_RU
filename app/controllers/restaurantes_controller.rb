class RestaurantesController < ApplicationController
  include ControleDeAcesso
  before_action :exigir_administrador
  before_action :carregar_restaurante, only: %i[edit update destroy]

  def index
    carregar_gestao
    @restaurante = Restaurante.new
    @catraca = Catraca.new
  end

  def create
    @restaurante = Restaurante.new(restaurante_params)
    if @restaurante.save
      redirect_to restaurantes_path, notice: "Restaurante cadastrado com sucesso"
    else
      carregar_gestao
      @catraca = Catraca.new
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @restaurante.update(restaurante_params)
      redirect_to restaurantes_path, notice: "Restaurante atualizado com sucesso"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @restaurante.destroy
      redirect_to restaurantes_path, notice: "Restaurante removido com sucesso"
    else
      redirect_to restaurantes_path, alert: @restaurante.errors.full_messages.to_sentence
    end
  end

  private

  def carregar_restaurante
    @restaurante = Restaurante.find(params[:id])
  end

  def carregar_gestao
    @restaurantes = Restaurante.includes(:catracas).order(:nome)
  end

  def restaurante_params
    params.require(:restaurante).permit(:nome, :campus)
  end
end
