# Um prato do cardápio. A +categoria+ codifica o tipo do prato (prato
# principal ou complemento) e a opção a que ele pertence, como em
# "prato_principal_padrao" ou "complemento_vegetariano_estrito".
class ItemCardapio < ApplicationRecord
  belongs_to :cardapio

  validates :categoria, :descricao, presence: true

  # Opções de refeição servidas pelo RU: chave usada na categoria => nome
  # exibido ao aluno.
  OPCOES = {
    "padrao" => "Opção Padrão",
    "ovolactovegetariano" => "Opção Ovolactovegetariana",
    "vegetariano_estrito" => "Opção Vegetariana Estrita"
  }.freeze

  # Identifica a opção de refeição a que o prato pertence.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   A chave de OPCOES com que a categoria termina (por exemplo,
  #   "padrao"), ou +nil+ se a categoria não corresponde a nenhuma opção.
  # Efeitos colaterais::
  #   Nenhum.
  def opcao
    OPCOES.keys.find { |chave| categoria.to_s.end_with?("_#{chave}") }
  end

  # Diz se o prato é um complemento ou um prato principal.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   "Complemento" se a categoria começa com "complemento"; senão,
  #   "Prato principal".
  # Efeitos colaterais::
  #   Nenhum.
  def tipo
    categoria.to_s.start_with?("complemento") ? "Complemento" : "Prato principal"
  end
end
