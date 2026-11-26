# Controller responsável pela gestão de restaurantes (listagem, criação,
# edição, atualização e remoção) para administradores autenticados.
class RestaurantesController < ApplicationController
  include ControleDeAcesso
  before_action :exigir_administrador
  before_action :carregar_restaurante, only: %i[edit update destroy]

  # Lista os restaurantes cadastrados e inicializa instâncias vazias de
  # restaurante e catraca para o formulário da tela de gestão.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   A nova instância de +Catraca+ atribuída a +@catraca+ (ação +index+ de
  #   controller).
  # Efeitos colaterais::
  #   Consulta restaurantes e catracas no banco e preenche +@restaurantes+,
  #   +@restaurante+ e +@catraca+.
  def index
    carregar_gestao
    @restaurante = Restaurante.new
    @catraca = Catraca.new
  end

  # Cadastra um novo restaurante com os parâmetros permitidos.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +params[:restaurante]+ via
  #   +restaurante_params+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação +create+ de controller;
  #   redireciona ou renderiza a view).
  # Efeitos colaterais::
  #   Persiste um novo +Restaurante+ no banco se válido e redireciona para
  #   +restaurantes_path+ com +notice+; se inválido, recarrega dados de gestão,
  #   inicializa +@catraca+ e renderiza +:index+ com status
  #   +:unprocessable_entity+.
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

  # Prepara a exibição do formulário de edição de um restaurante existente.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@restaurante+ carregado por
  #   +carregar_restaurante+).
  # Retorno::
  #   +nil+ (ação +edit+ de controller sem corpo próprio).
  # Efeitos colaterais::
  #   Busca o registro por +params[:id]+ no banco e preenche +@restaurante+
  #   via +before_action+.
  def edit; end

  # Atualiza os dados de um restaurante existente.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@restaurante+ e
  #   +restaurante_params+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação +update+ de controller;
  #   redireciona ou renderiza a view).
  # Efeitos colaterais::
  #   Atualiza o registro no banco se válido e redireciona para
  #   +restaurantes_path+ com +notice+; se inválido, renderiza +:edit+ com
  #   status +:unprocessable_entity+.
  def update
    if @restaurante.update(restaurante_params)
      redirect_to restaurantes_path, notice: "Restaurante atualizado com sucesso"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Remove um restaurante do sistema caso não possua restrições de exclusão.
  #
  # Argumentos::
  #   Nenhum argumento explícito (utiliza +@restaurante+ carregado por
  #   +carregar_restaurante+).
  # Retorno::
  #   Nenhum valor específico de domínio (ação +destroy+ de controller;
  #   redireciona para +restaurantes_path+).
  # Efeitos colaterais::
  #   Exclui o registro do banco quando permitido e redireciona com +notice+;
  #   se bloqueado (por exemplo, por catracas vinculadas), redireciona com
  #   +alert+ contendo as mensagens de erro.
  def destroy
    if @restaurante.destroy
      redirect_to restaurantes_path, notice: "Restaurante removido com sucesso"
    else
      redirect_to restaurantes_path, alert: @restaurante.errors.full_messages.to_sentence
    end
  end

  private

  # :doc:
  # Localiza o restaurante correspondente a +params[:id]+ e o atribui a
  # +@restaurante+.
  #
  # Argumentos::
  #   Nenhum argumento explícito (lê +params[:id]+).
  # Retorno::
  #   A instância de +Restaurante+ encontrada (ou levanta
  #   +ActiveRecord::RecordNotFound+ se não existir).
  # Efeitos colaterais::
  #   Consulta o banco de dados e atribui +@restaurante+.
  def carregar_restaurante
    @restaurante = Restaurante.find(params[:id])
  end

  # :doc:
  # Carrega os restaurantes ordenados por nome com suas catracas associadas.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   A relação (+ActiveRecord::Relation+) de +Restaurante+ atribuída a
  #   +@restaurantes+.
  # Efeitos colaterais::
  #   Prepara consulta com +includes(:catracas)+ e +order(:nome)+ e atribui a
  #   +@restaurantes+.
  def carregar_gestao
    @restaurantes = Restaurante.includes(:catracas).order(:nome)
  end

  # :doc:
  # Filtra e retorna os parâmetros permitidos para criação ou atualização de
  # restaurante.
  #
  # Argumentos::
  #   Nenhum argumento explícito (lê +params+).
  # Retorno::
  #   Um +ActionController::Parameters+ contendo apenas +:nome+ e +:campus+.
  # Efeitos colaterais::
  #   Exige a chave +:restaurante+ em +params+ (podendo levantar
  #   +ActionController::ParameterMissing+ se ausente).
  def restaurante_params
    params.require(:restaurante).permit(:nome, :campus)
  end
end