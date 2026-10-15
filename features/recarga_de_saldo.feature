# language: pt
# Issue #2 - MVP
# REGRAS ASSUMIDAS (ajustar com o grupo): valor numérico entre R$ 5,00 e
# R$ 200,00; o valor pago é somado ao saldo atual só após o pagamento ser aprovado.

Funcionalidade: Recarga de saldo
  Como estudante
  Quero adicionar créditos à minha conta via PIX ou cartão de crédito
  Para que eu tenha saldo suficiente para acessar os restaurantes

  Contexto:
    Dado que eu estou autenticado como estudante com matrícula "190012345"
    E meu saldo atual é de R$ 10,00
    E eu estou na página de recarga

  Cenário: Recarga via PIX com valor válido (feliz)
    Quando eu informo o valor de recarga "20,00"
    E eu seleciono a forma de pagamento "PIX"
    E eu confirmo a recarga
    E o pagamento PIX é confirmado
    Então eu devo ver a mensagem "Recarga realizada com sucesso"
    E meu saldo deve ser de R$ 30,00

  Cenário: Recarga via cartão de crédito com dados válidos (feliz)
    Quando eu informo o valor de recarga "20,00"
    E eu seleciono a forma de pagamento "Cartão de crédito"
    E eu informo os dados de um cartão válido
    E eu confirmo a recarga
    Então eu devo ver a mensagem "Recarga realizada com sucesso"
    E meu saldo deve ser de R$ 30,00

  Esquema do Cenário: Recarga com valor inválido (triste)
    Quando eu informo o valor de recarga "<valor>"
    E eu seleciono a forma de pagamento "PIX"
    E eu confirmo a recarga
    Então eu devo ver a mensagem "<mensagem>"
    E meu saldo deve continuar sendo de R$ 10,00

    Exemplos:
      | valor   | mensagem                            |
      | 0       | Valor mínimo de recarga é R$ 5,00   |
      | -10,00  | Valor mínimo de recarga é R$ 5,00   |
      | 4,99    | Valor mínimo de recarga é R$ 5,00   |
      | 200,01  | Valor máximo de recarga é R$ 200,00 |
      | abc     | Informe um valor numérico válido    |
      |         | Informe um valor numérico válido    |

  Cenário: Recarga sem escolher forma de pagamento (triste)
    Quando eu informo o valor de recarga "20,00"
    E eu confirmo a recarga
    Então eu devo ver a mensagem "Selecione uma forma de pagamento"
    E meu saldo deve continuar sendo de R$ 10,00

  Cenário: Cartão de crédito recusado (triste)
    Quando eu informo o valor de recarga "20,00"
    E eu seleciono a forma de pagamento "Cartão de crédito"
    E eu informo os dados de um cartão que será recusado
    E eu confirmo a recarga
    Então eu devo ver a mensagem "Pagamento recusado"
    E meu saldo deve continuar sendo de R$ 10,00

  Cenário: PIX não pago dentro do prazo (triste)
    Quando eu informo o valor de recarga "20,00"
    E eu seleciono a forma de pagamento "PIX"
    E eu confirmo a recarga
    E o prazo do PIX expira sem pagamento
    Então eu devo ver a mensagem "Pagamento não confirmado"
    E meu saldo deve continuar sendo de R$ 10,00
