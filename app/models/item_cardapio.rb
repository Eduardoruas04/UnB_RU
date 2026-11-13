class ItemCardapio < ApplicationRecord
  belongs_to :cardapio

  validates :categoria, :descricao, presence: true

  OPCOES = {
    "padrao" => "Opção Padrão",
    "ovolactovegetariano" => "Opção Ovolactovegetariana",
    "vegetariano_estrito" => "Opção Vegetariana Estrita"
  }.freeze

  def opcao
    OPCOES.keys.find { |chave| categoria.to_s.end_with?("_#{chave}") }
  end

  def tipo
    categoria.to_s.start_with?("complemento") ? "Complemento" : "Prato principal"
  end
end
