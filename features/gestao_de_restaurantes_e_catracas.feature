# language: pt
# Issue #8 - MVP
# REGRAS ASSUMIDAS (ajustar com o grupo): nome de restaurante único e
# identificador de catraca único; toda catraca pertence a um restaurante;
# só administrador acessa a gestão.

Funcionalidade: Gestão de restaurantes e catracas
  Como administrador
  Quero cadastrar, editar e remover diferentes restaurantes e suas respectivas catracas físicas no sistema
  Para que os funcionários possam selecioná-las na aplicação de controle

  Contexto:
    Dado que eu estou autenticado como administrador
    E eu estou na página de gestão de restaurantes e catracas

  # ---------- Restaurantes ----------

  Cenário: Cadastrar restaurante com dados válidos (feliz)
    Quando eu preencho o nome do restaurante com "RU Darcy Ribeiro"
    E eu clico em "Salvar restaurante"
    Então eu devo ver a mensagem "Restaurante cadastrado com sucesso"
    E "RU Darcy Ribeiro" deve aparecer na lista de restaurantes

  Cenário: Cadastrar restaurante sem nome (triste)
    Quando eu clico em "Salvar restaurante"
    Então eu devo ver a mensagem "Nome não pode ficar em branco"

  Cenário: Cadastrar restaurante com nome duplicado (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu preencho o nome do restaurante com "RU Darcy Ribeiro"
    E eu clico em "Salvar restaurante"
    Então eu devo ver a mensagem "Já existe um restaurante com este nome"

  Cenário: Editar o nome de um restaurante (feliz)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu edito o restaurante "RU Darcy Ribeiro" e altero o nome para "RU Central"
    Então eu devo ver a mensagem "Restaurante atualizado com sucesso"
    E "RU Central" deve aparecer na lista de restaurantes

  Cenário: Editar restaurante deixando o nome em branco (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu edito o restaurante "RU Darcy Ribeiro" e apago o nome
    Então eu devo ver a mensagem "Nome não pode ficar em branco"

  Cenário: Remover um restaurante (feliz)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu removo o restaurante "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Restaurante removido com sucesso"
    E "RU Darcy Ribeiro" não deve aparecer na lista de restaurantes

  # ---------- Catracas ----------

  Cenário: Cadastrar catraca vinculada a um restaurante (feliz)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu preencho o identificador da catraca com "CAT-01"
    E eu seleciono o restaurante "RU Darcy Ribeiro"
    E eu clico em "Salvar catraca"
    Então eu devo ver a mensagem "Catraca cadastrada com sucesso"

  Cenário: Cadastrar catraca sem restaurante (triste)
    Quando eu preencho o identificador da catraca com "CAT-01"
    E eu clico em "Salvar catraca"
    Então eu devo ver a mensagem "Selecione um restaurante"

  Cenário: Cadastrar catraca com identificador duplicado (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    E já existe a catraca "CAT-01"
    Quando eu preencho o identificador da catraca com "CAT-01"
    E eu seleciono o restaurante "RU Darcy Ribeiro"
    E eu clico em "Salvar catraca"
    Então eu devo ver a mensagem "Já existe uma catraca com este identificador"

  Cenário: Editar o identificador de uma catraca (feliz)
    Dado que já existe a catraca "CAT-01" no restaurante "RU Darcy Ribeiro"
    Quando eu edito a catraca "CAT-01" e altero o identificador para "CAT-02"
    Então eu devo ver a mensagem "Catraca atualizada com sucesso"

  Cenário: Remover uma catraca (feliz)
    Dado que já existe a catraca "CAT-01" no restaurante "RU Darcy Ribeiro"
    Quando eu removo a catraca "CAT-01"
    Então eu devo ver a mensagem "Catraca removida com sucesso"

  # ---------- Uso pelos funcionários ----------

  Cenário: Catraca cadastrada aparece para seleção na aplicação de controle (feliz)
    Dado que já existe a catraca "CAT-01" no restaurante "RU Darcy Ribeiro"
    Quando um funcionário autenticado abre a seleção de catraca na aplicação de controle
    Então ele deve ver "CAT-01" na lista de catracas do restaurante "RU Darcy Ribeiro"

  Cenário: Funcionário sem perfil de administrador tenta acessar a gestão (triste)
    Dado que eu estou autenticado como funcionário sem perfil de administrador
    Quando eu tento acessar a página de gestão de restaurantes e catracas
    Então eu devo ver a mensagem "Acesso restrito a administradores"
