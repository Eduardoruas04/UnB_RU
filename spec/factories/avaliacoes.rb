FactoryBot.define do
  factory :avaliacao do
    usuario { nil }
    acesso { nil }
    nota { 1 }
    comentario { "MyText" }
  end
end
