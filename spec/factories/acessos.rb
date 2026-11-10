FactoryBot.define do
  factory :acesso do
    usuario { nil }
    catraca { nil }
    turno { nil }
    valor_pago_centavos { 1 }
    autorizado { false }
    motivo_recusa { "MyString" }
    data_hora { "2026-11-10 10:58:17" }
  end
end
