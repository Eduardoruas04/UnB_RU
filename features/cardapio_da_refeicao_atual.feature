# language: pt
# Issue #10 - extra
# Exemplos de segunda-feira extraídos de cardapio.json: complementos no café
# da manhã e pratos principais no almoço e no jantar.
# A refeição em atendimento é uma condição; a política de horários está fora deste escopo.

Funcionalidade: Cardápio da refeição atual
  Como estudante
  Quero ver o cardápio da refeição que está sendo servida agora, incluindo as opções padrão, ovolactovegetariana e vegetariana estrita
  Para que eu possa conhecer as opções disponíveis na refeição atual

  Esquema do Cenário: Consultar as três opções da refeição em atendimento (feliz)
    Dado que é "<dia>" e a refeição "<refeicao>" está em atendimento
    E o cardápio dessa refeição está cadastrado e acessível
    Quando o estudante consulta o cardápio da refeição atual
    Então deve ser exibido o cardápio de "<dia>" para "<refeicao>"
    E a opção padrão deve apresentar "<padrao>" como <tipo>
    E a opção ovolactovegetariana deve apresentar "<ovolactovegetariano>" como <tipo>
    E a opção vegetariana estrita deve apresentar "<vegetariano_estrito>" como <tipo>

    Exemplos:
      | dia           | refeicao      | tipo            | padrao                       | ovolactovegetariano                    | vegetariano_estrito                         |
      | segunda-feira | café da manhã | complemento     | Carne desfiada               | Queijo muçarela                        | Homus de grão de bico                       |
      | segunda-feira | almoço        | prato principal | Frango assado com manjericão | Quiche de legumes e lentilha gratinada | Refogado de lentilha, couve-flor e brócolis |
      | segunda-feira | jantar        | prato principal | Lagarto ao molho escuro      | Ovos mexidos com castanhas             | Tomate recheado com soja                    |

  Cenário: Não exibir outra refeição como se fosse a atual
    Dado que é "segunda-feira" e a refeição "almoço" está em atendimento
    E os cardápios de "café da manhã", "almoço" e "jantar" desse dia estão cadastrados e acessíveis
    Quando o estudante consulta o cardápio da refeição atual
    Então deve ser exibido o cardápio de "segunda-feira" para "almoço"
    E os cardápios de "café da manhã" e "jantar" não devem ser exibidos como cardápio da refeição atual

  # Proposta mínima de aceitação: informar indisponibilidade quando não for possível consultar o cardápio atual.
  Esquema do Cenário: Cardápio da refeição atual indisponível (triste)
    Dado que é "segunda-feira" e a refeição "almoço" está em atendimento
    E o cardápio dessa refeição está <estado>
    Quando o estudante consulta o cardápio da refeição atual
    Então deve ser informada a indisponibilidade do cardápio da refeição atual
    E nenhum cardápio deve ser exibido como cardápio da refeição atual

    Exemplos:
      | estado         |
      | não cadastrado |
      | inacessível    |

  # Proposta mínima de aceitação: informar quando não houver refeição em atendimento.
  Cenário: Nenhuma refeição em atendimento (triste)
    Dado que nenhuma refeição está em atendimento
    Quando o estudante consulta o cardápio da refeição atual
    Então deve ser informado que não há refeição em atendimento
    E nenhum cardápio deve ser exibido como cardápio da refeição atual
