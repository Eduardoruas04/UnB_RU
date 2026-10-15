# language: pt
# Issue #2 - MVP | Figma: Recarga de Saldo (US03)
# REGRAS ASSUMIDAS (ajustar com o grupo): tarifa unitária de R$ 4,50 por refeição;
# pacotes de 2, 5, 10 e 20 refeições (R$ 9,00 / 22,50 / 45,00 / 90,00); também é
# possível informar "Outra quantidade" (mínimo 1 e máximo 100 refeições); o saldo
# é exibido em reais e em refeições; o crédito só é somado ao saldo depois que o
# pagamento é aprovado.

Funcionalidade: Recarga de saldo
  Como estudante
  Quero adicionar créditos à minha conta via PIX ou cartão de crédito
  Para que eu tenha saldo suficiente para acessar os restaurantes

  Contexto:
    Dado que eu estou autenticado como estudante com matrícula "221045999"
    E meu saldo atual é de R$ 18,00 (4 refeições)
    E a tarifa unitária da refeição é de R$ 4,50
    E eu estou na página de recarga

  # ---------- Pacotes ----------

  Esquema do Cenário: Recarga via PIX com pacote de refeições (feliz)
    Quando eu escolho o pacote de "<refeicoes>" refeições
    Então o resumo da recarga deve mostrar o total de R$ <total>
    E o resumo da recarga deve mostrar o novo saldo de <novas_refeicoes> refeições
    Quando eu seleciono a forma de pagamento "PIX Instantâneo"
    E eu clico em "Confirmar"
    E o pagamento PIX é confirmado
    Então eu devo ver a mensagem "Recarga realizada com sucesso"
    E meu saldo deve ser de <novas_refeicoes> refeições

    Exemplos:
      | refeicoes | total  | novas_refeicoes |
      | 2         | 9,00   | 6               |
      | 5         | 22,50  | 9               |
      | 10        | 45,00  | 14              |
      | 20        | 90,00  | 24              |

  Cenário: Recarga via cartão de crédito com dados válidos (feliz)
    Quando eu escolho o pacote de "5" refeições
    E eu seleciono a forma de pagamento "Cartão de Crédito"
    E eu informo os dados de um cartão válido
    E eu clico em "Confirmar"
    Então eu devo ver a mensagem "Recarga realizada com sucesso"
    E meu saldo deve ser de 9 refeições

  Cenário: Resumo da recarga é atualizado ao trocar de pacote (feliz)
    Quando eu escolho o pacote de "5" refeições
    E eu escolho o pacote de "10" refeições
    Então o resumo da recarga deve mostrar "10 refeições"
    E o resumo da recarga deve mostrar o total de R$ 45,00

  # ---------- Outra quantidade ----------

  Esquema do Cenário: Recarga com outra quantidade válida (feliz)
    Quando eu informo "<quantidade>" em "Outra quantidade"
    Então o cálculo deve mostrar "<quantidade> × R$ 4,50 = R$ <total>"

    Exemplos:
      | quantidade | total  |
      | 1          | 4,50   |
      | 7          | 31,50  |
      | 100        | 450,00 |

  Esquema do Cenário: Recarga com quantidade inválida (triste)
    Quando eu informo "<quantidade>" em "Outra quantidade"
    E eu seleciono a forma de pagamento "PIX Instantâneo"
    E eu clico em "Confirmar"
    Então eu devo ver a mensagem "<mensagem>"
    E meu saldo deve continuar sendo de 4 refeições

    Exemplos:
      | quantidade | mensagem                                  |
      | 0          | A quantidade mínima é de 1 refeição       |
      | -3         | A quantidade mínima é de 1 refeição       |
      | 101        | A quantidade máxima é de 100 refeições    |
      | abc        | Informe uma quantidade numérica válida    |
      | 2,5        | Informe uma quantidade numérica válida    |
      |            | Informe uma quantidade numérica válida    |

  Cenário: Botão de diminuir não permite quantidade menor que 1 (triste)
    Quando eu informo "1" em "Outra quantidade"
    E eu clico no botão "−" de quantidade
    Então a quantidade deve continuar sendo "1"

  # ---------- Pagamento ----------

  Cenário: Confirmar recarga sem escolher o método de pagamento (triste)
    Dado que nenhum método de pagamento foi selecionado
    Quando eu escolho o pacote de "5" refeições
    E eu clico em "Confirmar"
    Então eu devo ver a mensagem "Selecione uma forma de pagamento"
    E meu saldo deve continuar sendo de 4 refeições

  Cenário: Copiar o código PIX (feliz)
    Quando eu escolho o pacote de "5" refeições
    E eu seleciono a forma de pagamento "PIX Instantâneo"
    E eu clico em "Copiar Código"
    Então o código PIX deve ser copiado para a área de transferência

  Cenário: Cartão de crédito recusado (triste)
    Quando eu escolho o pacote de "5" refeições
    E eu seleciono a forma de pagamento "Cartão de Crédito"
    E eu informo os dados de um cartão que será recusado
    E eu clico em "Confirmar"
    Então eu devo ver a mensagem "Pagamento recusado"
    E meu saldo deve continuar sendo de 4 refeições

  Cenário: Cartão de crédito com validade vencida (triste)
    Quando eu escolho o pacote de "5" refeições
    E eu seleciono a forma de pagamento "Cartão de Crédito"
    E eu informo os dados de um cartão com validade vencida
    E eu clico em "Confirmar"
    Então eu devo ver a mensagem "Cartão vencido"
    E meu saldo deve continuar sendo de 4 refeições

  Cenário: PIX não pago dentro do prazo (triste)
    Quando eu escolho o pacote de "5" refeições
    E eu seleciono a forma de pagamento "PIX Instantâneo"
    E eu clico em "Confirmar"
    E o prazo do PIX expira sem pagamento
    Então eu devo ver a mensagem "Pagamento não confirmado"
    E meu saldo deve continuar sendo de 4 refeições

  # ---------- Acesso ----------

  Cenário: Acesso à recarga sem estar autenticado (triste)
    Dado que eu não estou autenticado
    Quando eu tento acessar a página de recarga
    Então eu devo ser redirecionado para a página de login
