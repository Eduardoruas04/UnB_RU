# language: pt
# Issue #1 - MVP
# REGRAS ASSUMIDAS (ajustar com o grupo): matrícula com 9 dígitos numéricos,
# única no sistema; senha com no mínimo 8 caracteres; nome obrigatório.

Funcionalidade: Cadastro de usuário
  Como estudante
  Quero me cadastrar no sistema utilizando minha matrícula
  Para que eu possa criar minha conta de acesso ao RU

  Contexto:
    Dado que eu estou na página de cadastro

  Cenário: Cadastro realizado com dados válidos (feliz)
    Quando eu preencho o nome com "Maria Silva"
    E eu preencho a matrícula com "190012345"
    E eu preencho a senha com "senha1234"
    E eu clico em "Cadastrar"
    Então eu devo ver a mensagem "Cadastro realizado com sucesso"
    E uma conta deve existir para a matrícula "190012345"

  Esquema do Cenário: Cadastro com matrícula inválida (triste)
    Quando eu preencho o nome com "Maria Silva"
    E eu preencho a matrícula com "<matricula>"
    E eu preencho a senha com "senha1234"
    E eu clico em "Cadastrar"
    Então eu devo ver a mensagem "<mensagem>"
    E nenhuma conta deve ser criada

    Exemplos:
      | matricula    | mensagem                              |
      |              | Matrícula não pode ficar em branco    |
      | 12345        | Matrícula deve ter 9 dígitos          |
      | 1900123456   | Matrícula deve ter 9 dígitos          |
      | abc123def    | Matrícula deve conter apenas números  |

  Cenário: Cadastro com matrícula já cadastrada (triste)
    Dado que já existe um usuário com a matrícula "190012345"
    Quando eu preencho o nome com "João Souza"
    E eu preencho a matrícula com "190012345"
    E eu preencho a senha com "senha1234"
    E eu clico em "Cadastrar"
    Então eu devo ver a mensagem "Matrícula já cadastrada"

  Cenário: Cadastro com senha curta (triste)
    Quando eu preencho o nome com "Maria Silva"
    E eu preencho a matrícula com "190012345"
    E eu preencho a senha com "123"
    E eu clico em "Cadastrar"
    Então eu devo ver a mensagem "Senha deve ter no mínimo 8 caracteres"
    E nenhuma conta deve ser criada
