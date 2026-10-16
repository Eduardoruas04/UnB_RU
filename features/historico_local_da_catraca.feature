# language: pt
# Issue #7 - Extra
# REGRAS ASSUMIDAS (ajustar com o grupo): cada registro mostra data/hora e
# matrícula do aluno; a lista aparece do acesso mais recente para o mais
# antigo; só entram acessos efetivamente registrados na catraca selecionada.

Funcionalidade: Histórico local da catraca
  Como funcionário
  Quero visualizar na aplicação de controle o histórico de todos os acessos registrados apenas na catraca que estou gerenciando no momento
  Para realizar auditorias ou conferências locais de fluxo

  Contexto:
    Dado que eu estou autenticado como funcionário
    E existem as catracas "CAT-01" e "CAT-02" no restaurante "RU Darcy Ribeiro"

  Cenário: Visualizar o histórico da catraca selecionada (feliz)
    Dado que a catraca "CAT-01" registrou os acessos dos alunos "190012345" e "190054321"
    Quando eu seleciono a catraca "CAT-01" na aplicação de controle
    E eu abro o histórico local
    Então eu devo ver os acessos dos alunos "190012345" e "190054321"
    E cada acesso deve mostrar a data e a hora do registro

  Cenário: Histórico mostra apenas acessos da catraca selecionada (feliz)
    Dado que a catraca "CAT-01" registrou o acesso do aluno "190012345"
    E a catraca "CAT-02" registrou o acesso do aluno "190099999"
    Quando eu seleciono a catraca "CAT-01" na aplicação de controle
    E eu abro o histórico local
    Então eu devo ver o acesso do aluno "190012345"
    E eu não devo ver o acesso do aluno "190099999"

  Cenário: Histórico ordenado do acesso mais recente para o mais antigo (feliz)
    Dado que a catraca "CAT-01" registrou um acesso às 12:00 e outro às 12:30
    Quando eu seleciono a catraca "CAT-01" na aplicação de controle
    E eu abro o histórico local
    Então o acesso das 12:30 deve aparecer antes do acesso das 12:00

  Cenário: Catraca sem nenhum acesso registrado (triste)
    Dado que a catraca "CAT-01" ainda não registrou nenhum acesso
    Quando eu seleciono a catraca "CAT-01" na aplicação de controle
    E eu abro o histórico local
    Então eu devo ver a mensagem "Nenhum acesso registrado nesta catraca"

  Cenário: Abrir o histórico sem selecionar uma catraca (triste)
    Quando eu abro o histórico local sem selecionar uma catraca
    Então eu devo ver a mensagem "Selecione uma catraca para ver o histórico"

  Cenário: Acessar o histórico sem estar autenticado (triste)
    Dado que eu não estou autenticado
    Quando eu tento acessar o histórico local de uma catraca
    Então eu devo ser redirecionado para a página de login
