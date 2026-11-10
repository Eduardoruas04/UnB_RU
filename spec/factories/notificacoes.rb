FactoryBot.define do
  factory :notificacao do
    usuario { nil }
    sorteio_fastpass { nil }
    titulo { "MyString" }
    mensagem { "MyText" }
    lida { false }
    tipo { "MyString" }
    status_envio { "MyString" }
    enviado_em { "2026-11-10 10:58:19" }
  end
end
