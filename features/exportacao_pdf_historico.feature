# language: pt
# Issue #11 | Figma: Extrato de Refeições (US04) - botão "Exportar PDF"
# REGRAS ASSUMIDAS (ajustar com o grupo): o estudante só exporta o próprio extrato;
# o PDF contém os lançamentos (refeições e recargas) que atendem aos filtros
# aplicados na tela (período, tipo de refeição, restaurante e forma de acesso) e
# o resumo (total gasto, refeições realizadas e total recarregado); sem
# lançamentos no filtro não se gera PDF.

Funcionalidade: Exportação em PDF do histórico do estudante
  Como estudante
  Quero exportar meu extrato e histórico de refeições como PDF
  Para controlar melhor as minhas finanças

  Contexto:
    Dado que eu estou autenticado como estudante com matrícula "221045999"
    E eu possuo 24 lançamentos no extrato
    E eu estou na página "Extrato e Histórico de Refeições"

  # ---------- Exportação sem filtros ----------

  Cenário: Exportar o extrato completo em PDF (feliz)
    Quando eu clico em "Exportar PDF"
    Então um arquivo PDF deve ser baixado
    E o PDF deve conter os 24 lançamentos
    E o PDF deve conter o resumo com total gasto, refeições realizadas e total recarregado

  Cenário: PDF contém data, evento, restaurante, método de acesso e valor (feliz)
    Quando eu clico em "Exportar PDF"
    Então cada lançamento do PDF deve conter data e hora, refeição ou evento, restaurante, método de acesso e valor

  # ---------- Exportação com filtros ----------

  Esquema do Cenário: Exportar o extrato com filtro aplicado (feliz)
    Quando eu seleciono "<valor_filtro>" em "<filtro>"
    E eu clico em "Exportar PDF"
    Então um arquivo PDF deve ser baixado
    E o PDF deve conter apenas os lançamentos de "<valor_filtro>"

    Exemplos:
      | filtro                 | valor_filtro     |
      | Período de Referência  | Últimos 30 dias  |
      | Tipo de Refeição       | Almoço           |
      | Forma de Acesso        | QR Code App      |

  Cenário: Exportar após limpar os filtros (feliz)
    Dado que eu apliquei o filtro "Almoço" em "Tipo de Refeição / Evento"
    Quando eu clico em "Limpar Filtros"
    E eu clico em "Exportar PDF"
    Então o PDF deve conter os 24 lançamentos

  # ---------- Casos tristes ----------

  Cenário: Exportar quando o filtro não retorna lançamentos (triste)
    Dado que eu apliquei um filtro que não retorna nenhum lançamento
    Quando eu clico em "Exportar PDF"
    Então eu devo ver a mensagem "Não há registros para exportar"
    E nenhum arquivo PDF deve ser baixado

  Cenário: Exportar sem nenhum lançamento no extrato (triste)
    Dado que eu não possuo lançamentos no extrato
    Quando eu clico em "Exportar PDF"
    Então eu devo ver a mensagem "Não há registros para exportar"
    E nenhum arquivo PDF deve ser baixado

  Cenário: PDF não inclui lançamentos de outro estudante (triste)
    Dado que o estudante com matrícula "190099999" também possui lançamentos
    Quando eu clico em "Exportar PDF"
    Então o PDF não deve conter lançamentos da matrícula "190099999"

  Cenário: Falha na geração do PDF (triste)
    Dado que o serviço de geração de PDF está indisponível
    Quando eu clico em "Exportar PDF"
    Então eu devo ver a mensagem "Não foi possível gerar o PDF. Tente novamente"
    E nenhum arquivo PDF deve ser baixado

  Cenário: Exportação sem estar autenticado (triste)
    Dado que eu não estou autenticado
    Quando eu tento acessar a exportação do extrato
    Então eu devo ser redirecionado para a página de login
