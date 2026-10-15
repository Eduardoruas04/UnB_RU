
# language: pt
# Issue #15 - BÔNUS
# Notificação de Sorteio - FastPass
#
# REGRAS DA ISSUE:
# O estudante deve ser notificado se ganhou ou não
# o FastPass, uma hora antes do turno.
#
# REGRAS ASSUMIDAS (validar com o grupo):
# - Apenas estudantes inscritos recebem notificações.
# - Cada estudante recebe uma notificação por sorteio.
# - A notificação informa o resultado do sorteio.
# - O estudante sorteado recebe o horário do FastPass.

Funcionalidade: Notificação de sorteio do FastPass
  Como estudante
  Quero ser notificado se ganhei ou não o FastPass
  1 hora antes do turno
  Para que eu possa planejar meu horário de ida ao RU

  Contexto:
    Dado que existe um turno de almoço às "12:00"
    E que o sorteio do FastPass foi realizado
    E que o horário programado da notificação é "11:00"

  # Cenários felizes

  Cenário: Estudante sorteado recebe notificação
    Dado que o estudante "190012345" está inscrito no sorteio
    E que o estudante "190012345" foi sorteado
    Quando o horário atual for "11:00"
    Então o sistema deve enviar uma notificação ao estudante "190012345"
    E a notificação deve informar "Você foi sorteado para o FastPass"
    E a notificação deve informar o horário do FastPass

  Cenário: Estudante não sorteado recebe notificação
    Dado que o estudante "190012345" está inscrito no sorteio
    E que o estudante "190012345" não foi sorteado
    Quando o horário atual for "11:00"
    Então o sistema deve enviar uma notificação ao estudante "190012345"
    E a notificação deve informar "Você não foi sorteado para o FastPass"

  #  Cenários tristes

  Cenário: Notificação antes do horário programado
    Dado que o estudante "190012345" está inscrito no sorteio
    E que o estudante "190012345" foi sorteado
    Quando o horário atual for "10:30"
    Então o sistema não deve enviar a notificação ao estudante "190012345"

  Cenário: Estudante não inscrito no sorteio
    Dado que o estudante "190012345" não está inscrito no sorteio
    Quando o horário atual for "11:00"
    Então o sistema não deve enviar a notificação ao estudante "190012345"

  Cenário: Evitar envio de notificação duplicada
    Dado que o estudante "190012345" está inscrito no sorteio
    E que o estudante "190012345" foi sorteado
    E que o estudante já recebeu a notificação desse sorteio
    Quando o sistema processar novamente as notificações às "11:00"
    Então nenhuma nova notificação deve ser enviada ao estudante "190012345"
