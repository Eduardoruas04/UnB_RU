# language: pt
# Issue #8 - MVP
# REGRAS ASSUMIDAS (ajustar com o grupo): nome de restaurante único (sem
# diferenciar maiúsculas de minúsculas) e identificador de catraca único;
# toda catraca pertence a um restaurante; restaurante com catracas vinculadas
# não pode ser removido até as catracas serem removidas; só administrador
# acessa a gestão.

@mvp
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
    E nenhum restaurante deve ser criado

  Cenário: Cadastrar restaurante com nome duplicado (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu preencho o nome do restaurante com "RU Darcy Ribeiro"
    E eu clico em "Salvar restaurante"
    Então eu devo ver a mensagem "Já existe um restaurante com este nome"

  Cenário: Cadastrar restaurante com nome duplicado variando maiúsculas e minúsculas (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu preencho o nome do restaurante com "ru darcy ribeiro"
    E eu clico em "Salvar restaurante"
    Então eu devo ver a mensagem "Já existe um restaurante com este nome"

  Cenário: Editar o nome de um restaurante (feliz)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu edito o restaurante "RU Darcy Ribeiro" e altero o nome para "RU Central"
    Então eu devo ver a mensagem "Restaurante atualizado com sucesso"
    E "RU Central" deve aparecer na lista de restaurantes
    E "RU Darcy Ribeiro" não deve aparecer na lista de restaurantes

  Cenário: Editar restaurante deixando o nome em branco (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu edito o restaurante "RU Darcy Ribeiro" e apago o nome
    Então eu devo ver a mensagem "Nome não pode ficar em branco"
    E "RU Darcy Ribeiro" deve continuar na lista de restaurantes

  Cenário: Editar restaurante para um nome que já existe (triste)
    Dado que já existem os restaurantes "RU Darcy Ribeiro" e "RU Central"
    Quando eu edito o restaurante "RU Central" e altero o nome para "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Já existe um restaurante com este nome"

  Cenário: Remover um restaurante sem catracas (feliz)
    Dado que já existe o restaurante "RU Darcy Ribeiro" sem catracas
    Quando eu removo o restaurante "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Restaurante removido com sucesso"
    E "RU Darcy Ribeiro" não deve aparecer na lista de restaurantes

  Cenário: Remover um restaurante que ainda tem catracas (triste)
    Dado que já existe a catraca "CAT-01" no restaurante "RU Darcy Ribeiro"
    Quando eu removo o restaurante "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Remova as catracas deste restaurante antes de excluí-lo"
    E "RU Darcy Ribeiro" deve continuar na lista de restaurantes

  # ---------- Catracas ----------

  Cenário: Cadastrar catraca vinculada a um restaurante (feliz)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu preencho o identificador da catraca com "CAT-01"
    E eu seleciono o restaurante "RU Darcy Ribeiro"
    E eu clico em "Salvar catraca"
    Então eu devo ver a mensagem "Catraca cadastrada com sucesso"
    E "CAT-01" deve aparecer na lista de catracas de "RU Darcy Ribeiro"

  Cenário: Cadastrar catraca sem identificador (triste)
    Dado que já existe o restaurante "RU Darcy Ribeiro"
    Quando eu seleciono o restaurante "RU Darcy Ribeiro"
    E eu clico em "Salvar catraca"
    Então eu devo ver a mensagem "Identificador não pode ficar em branco"

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
    E "CAT-02" deve aparecer na lista de catracas de "RU Darcy Ribeiro"

  Cenário: Editar catraca para um identificador que já existe (triste)
    Dado que já existem as catracas "CAT-01" e "CAT-02" no restaurante "RU Darcy Ribeiro"
    Quando eu edito a catraca "CAT-02" e altero o identificador para "CAT-01"
    Então eu devo ver a mensagem "Já existe uma catraca com este identificador"

  Cenário: Remover uma catraca (feliz)
    Dado que já existe a catraca "CAT-01" no restaurante "RU Darcy Ribeiro"
    Quando eu removo a catraca "CAT-01"
    Então eu devo ver a mensagem "Catraca removida com sucesso"
    E "CAT-01" não deve aparecer na lista de catracas de "RU Darcy Ribeiro"

  # ---------- Uso pelos funcionários ----------

  Cenário: Catraca cadastrada aparece para seleção na aplicação de controle (feliz)
    Dado que já existe a catraca "CAT-01" no restaurante "RU Darcy Ribeiro"
    Quando um funcionário autenticado abre a seleção de catraca na aplicação de controle
    Então ele deve ver "CAT-01" na lista de catracas do restaurante "RU Darcy Ribeiro"

  Cenário: Catraca removida deixa de aparecer para seleção (feliz)
    Dado que a catraca "CAT-01" do restaurante "RU Darcy Ribeiro" foi removida
    Quando um funcionário autenticado abre a seleção de catraca na aplicação de controle
    Então ele não deve ver "CAT-01" na lista de catracas

  Cenário: Funcionário sem perfil de administrador tenta acessar a gestão (triste)
    Dado que eu estou autenticado como funcionário sem perfil de administrador
    Quando eu tento acessar a página de gestão de restaurantes e catracas
    Então eu devo ver a mensagem "Acesso restrito a administradores"
