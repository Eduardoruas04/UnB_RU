require "rails_helper"

RSpec.describe "recargas/new.html.erb", type: :view do
  before do
    assign(:usuario, Usuario.new(nome: "Mariana Silva", matricula: "221045991"))
    assign(:carteira, Carteira.new(saldo_centavos: 900))
    assign(:saldo_refeicoes, 2)
    assign(:quantidade, 5)
    assign(:total_formatado, "22,50")
    assign(:novo_saldo_refs, 7)
  end

  it "envia a quantidade inicial e o método padrão no formulário de recarga" do
    render

    assert_select "form#form-recarga[action=?][method=post]", recargas_path do
      assert_select "input[name=pacote_opcao][checked]", count: 1
      assert_select "input[name=pacote_opcao][value='5'][checked]"
      assert_select "input[name=quantidade_refeicoes][value='5']"
      assert_select "input[name=metodo_pagamento][value=?]", "PIX Instantâneo"
    end
  end

  it "exibe o saldo atual, o total a pagar e o saldo projetado" do
    render

    assert_select "#saldo-topo", text: /R\$ 9,00\s*\(2 refs\)/
    assert_select "#resumo-total", text: "R$ 22,50"
    assert_select "#resumo-novo-saldo", text: "7 refeições"
  end
end
