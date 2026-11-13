# ==============================================================================
# Testes Unitários de Model (RSpec): Recarga (spec/models/recarga_spec.rb)
# ==============================================================================
# Valida as regras de integridade do modelo Recarga no nível de banco e ActiveModel:
# - Associações com Usuario e Carteira
# - Presença e validação numérica de valor_centavos (deve ser estritamente positivo)
# ==============================================================================

require "rails_helper"

RSpec.describe Recarga, type: :model do
  # Cria ou recupera o estudante de teste com dados consistentes
  let(:usuario) do
    Usuario.find_or_create_by!(matricula: "221045999") do |u|
      u.nome = "Estudante Teste"
      u.email = "teste@unb.br"
      u.password = "password123"
      u.papel = "estudante"
      u.ativo = true
    end
  end

  # Garante que o estudante possua carteira vinculada
  let(:carteira) { usuario.carteira || usuario.create_carteira(saldo_centavos: 0) }

  # Teste de fluxo feliz: registro completo com todos os atributos obrigatórios
  it "é válido com dados completos" do
    recarga = usuario.recargas.build(
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 2250,
      status: "pendente",
      metodo_pagamento: "PIX Instantâneo"
    )
    expect(recarga).to be_valid
  end

  # Teste de validação de negócio: o valor da recarga deve ser maior que zero
  it "é inválido sem valor_centavos positivo" do
    recarga = usuario.recargas.build(
      carteira: carteira,
      quantidade_refeicoes: 5,
      valor_centavos: 0,
      status: "pendente",
      metodo_pagamento: "PIX Instantâneo"
    )
    expect(recarga).not_to be_valid
  end
end
