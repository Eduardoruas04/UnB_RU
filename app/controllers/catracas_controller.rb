# Controller responsável pelo gerenciamento de catracas (criação, edição,
# atualização e remoção) para administradores autenticados.
class CatracasController < ApplicationController
  include ControleDeAcesso
  before_action :exigir_administrador
  before_action :carregar_catraca, only: %i[edit update destroy]

  # Cadastra uma nova catraca vinculada a um restaurante.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +params[:catraca]+ via
  #   +catraca_params+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação +create+ de controller;
  #   redireciona ou renderiza a view).
  # Efeitos colaterais::
  #   Salva uma nova +Catraca+ no banco se válida e redireciona para
  #   +restaurantes_path+ com +notice+; se inválida, carrega +@restaurantes+ e
  #   +@restaurante+ e renderiza +"restaurantes/index"+ com status
  #   +:unprocessable_entity+.
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

  # Prepara os dados necessários para a edição de uma catraca existente.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@catraca+ carregada via
  #   +before_action+).
  # Retorno::
  #   A relação (+ActiveRecord::Relation+) de +Restaurante+ ordenados por nome
  #   atribuída a +@restaurantes+.
  # Efeitos colaterais::
  #   Busca +@catraca+ por +params[:id]+ (via +carregar_catraca+), consulta
  #   restaurantes no banco e preenche +@restaurantes+.
  def edit
    @restaurantes = Restaurante.order(:nome)
  end

  # Atualiza os dados de uma catraca existente.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@catraca+ e +catraca_params+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação +update+ de controller;
  #   redireciona ou renderiza a view).
  # Efeitos colaterais::
  #   Atualiza a +Catraca+ no banco se válida e redireciona para
  #   +restaurantes_path+ com +notice+; se inválida, preenche +@restaurantes+ e
  #   renderiza +:edit+ com status +:unprocessable_entity+.
  def update
    if @catraca.update(catraca_params)
      redirect_to restaurantes_path, notice: "Catraca atualizada com sucesso"
    else
      @restaurantes = Restaurante.order(:nome)
      render :edit, status: :unprocessable_entity
    end
  end

  # Remove uma catraca do sistema.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@catraca+ carregada via
  #   +before_action+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação +destroy+ de controller;
  #   redireciona para +restaurantes_path+).
  # Efeitos colaterais::
  #   Exclui a +Catraca+ do banco e redireciona para +restaurantes_path+ com
  #   +notice+.
  def destroy
    @catraca.destroy
    redirect_to restaurantes_path, notice: "Catraca removida com sucesso"
  end

  private

  # :doc:
  # Localiza a catraca correspondente a +params[:id]+ e a atribui a
  # +@catraca+.
  #
  # Argumentos::
  #   Nenhum argumento explícito (lê +params[:id]+).
  # Retorno::
  #   A instância de +Catraca+ encontrada (ou levanta
  #   +ActiveRecord::RecordNotFound+ se não existir).
  # Efeitos colaterais::
  #   Consulta o banco de dados e atribui +@catraca+.
  def carregar_catraca
    @catraca = Catraca.find(params[:id])
  end

  # :doc:
  # Filtra e retorna os parâmetros permitidos para criação ou atualização de
  # catraca.
  #
  # Argumentos::
  #   Nenhum argumento explícito (lê +params+).
  # Retorno::
  #   Um +ActionController::Parameters+ contendo +:codigo_identificador+,
  #   +:restaurante_id+ e +:status+.
  # Efeitos colaterais::
  #   Exige a chave +:catraca+ em +params+ (podendo levantar
  #   +ActionController::ParameterMissing+ se ausente).
  def catraca_params
    params.require(:catraca).permit(:codigo_identificador, :restaurante_id, :status)
  end
end
