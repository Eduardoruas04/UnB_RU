FactoryBot.define do
  factory :usuario do
    matricula { "MyString" }
    nome { "MyString" }
    email { "MyString" }
    password_digest { "MyString" }
    papel { "MyString" }
    ativo { false }
  end
end
