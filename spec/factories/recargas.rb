FactoryBot.define do
  factory :recarga do
    usuario { nil }
    carteira { nil }
    quantidade_refeicoes { 1 }
    valor_centavos { 1 }
    status { "MyString" }
    metodo_pagamento { "MyString" }
    txid_pix { "MyString" }
  end
end
