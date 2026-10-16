# language: pt
# Issue BÔNUS - Avaliação da Refeição

Funcionalidade: Avaliação da refeição do RU
  Como estudante
  Quero avaliar a refeição que consumi no restaurante
  Para enviar meu feedback sobre a qualidade da comida e do serviço

  Contexto:
    Dado que estou autenticado no sistema
    E que consumi uma refeição no RU na data de hoje

  # Cenários felizes
  Cenário: Avaliação enviada com nota e comentário (feliz)
    Quando eu seleciono a nota "5"
    E eu preencho o comentário com "A comida estava excelente"
    E eu clico em "Enviar Avaliação"
    Então o sistema deve registrar a minha avaliação
    E eu devo ver a mensagem "Obrigado pelo seu feedback!"

  Cenário: Avaliação enviada apenas com nota (feliz)
    Quando eu seleciono a nota "4"
    E eu deixo o campo comentário em branco
    E eu clico em "Enviar Avaliação"
    Então o sistema deve registrar a minha avaliação
    E eu devo ver a mensagem "Obrigado pelo seu feedback!"

  # Cenários tristes
  Cenário: Tentar avaliar sem selecionar nota (triste)
    Quando eu deixo o campo nota em branco
    E eu preencho o comentário com "Sem nota"
    E eu clico em "Enviar Avaliação"
    Então o sistema deve impedir o envio
    E eu devo ver a mensagem "Selecione uma nota para a refeição"

  Cenário: Tentar avaliar sem ter consumido refeição hoje (triste)
    Dado que não consumi nenhuma refeição no RU na data de hoje
    Quando eu tento enviar uma avaliação
    Então o sistema deve impedir o envio
    E eu devo ver a mensagem "Você precisa ter consumido uma refeição hoje para avaliar"