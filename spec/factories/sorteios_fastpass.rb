FactoryBot.define do
  factory :sorteio_fastpass do
    turno { nil }
    data_sorteio { "2026-11-10" }
    status { "MyString" }
    vagas_disponiveis { 1 }
  end
end
