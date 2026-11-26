require "rails_helper"

RSpec.describe "recargas/show.html.erb", type: :view do
  it "exibe o valor e o código da cobrança PIX e permite confirmar o pagamento" do
    recarga = Recarga.new(id: 42, quantidade_refeicoes: 2, valor_centavos: 900,
                          status: "pendente", metodo_pagamento: "PIX Instantâneo", txid_pix: "PIX-TESTE")
    assign(:recarga, recarga)

    render

    assert_select "span", text: "Valor a pagar (2 refeições):"
    assert_select "#codigo-pix[readonly][value=?]", "PIX-TESTE@unb.br"
    expect(rendered).to include("R$ 9,00")
    assert_select "form[action=?][method=post] #btn-confirmar-pix", confirmar_recarga_path(recarga)
  end
end
