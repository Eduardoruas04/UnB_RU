# language: pt
# Issue #6 - MVP
# O preço de R$ 5,00 é apenas um dado de exemplo destes cenários.

Funcionalidade: Validação de entrada
  Como aplicação de controle
  Quero ler a identificação do aluno, verificar se há saldo, enviar o comando de liberação para a catraca e efetuar o débito da refeição no momento da passagem
  Para que apenas alunos com saldo suficiente acessem o restaurante

  Contexto:
    Dado que o preço da refeição é de R$ 5,00
    E existe uma catraca ativa no restaurante

  Cenário: Autorizar entrada com saldo maior que o preço antes da passagem (feliz)
    Dado que o aluno "190012345" está cadastrado e tem saldo de R$ 10,00
    E a catraca ainda não confirmou a passagem do aluno
    Quando a identificação do aluno "190012345" é lida na catraca
    Então o comando de liberação deve ser enviado para a catraca
    E nenhum débito deve ser efetuado antes da confirmação da passagem
    E o saldo do aluno deve continuar sendo de R$ 10,00

  Cenário: Autorizar entrada com saldo exatamente igual ao preço antes da passagem (feliz)
    Dado que o aluno "190012345" está cadastrado e tem saldo de R$ 5,00
    E a catraca ainda não confirmou a passagem do aluno
    Quando a identificação do aluno "190012345" é lida na catraca
    Então o comando de liberação deve ser enviado para a catraca
    E nenhum débito deve ser efetuado antes da confirmação da passagem
    E o saldo do aluno deve continuar sendo de R$ 5,00

  Esquema do Cenário: Debitar a refeição após a confirmação da passagem (feliz)
    Dado que o aluno "190012345" está cadastrado e tem saldo de R$ <saldo_inicial>
    E a leitura de sua identificação já resultou no envio do comando de liberação para a catraca
    E nenhum débito foi efetuado nesta tentativa de entrada
    Quando a catraca confirma a passagem do aluno "190012345"
    Então o preço da refeição deve ser debitado do saldo do aluno
    E o saldo do aluno deve ser de R$ <saldo_final>

    Exemplos:
      | saldo_inicial | saldo_final |
      | 10,00         | 5,00        |
      | 5,00          | 0,00        |

  Cenário: Entrada negada por saldo insuficiente (triste)
    Dado que o aluno "190012345" está cadastrado e tem saldo de R$ 4,99
    Quando a identificação do aluno "190012345" é lida na catraca
    Então nenhum comando de liberação deve ser enviado
    E deve ser exibida a mensagem "Saldo insuficiente"
    E o saldo do aluno deve continuar sendo de R$ 4,99

  Cenário: Identificação não reconhecida (triste)
    Dado que não existe aluno cadastrado com a identificação "000000000"
    Quando a identificação "000000000" é lida na catraca
    Então nenhum comando de liberação deve ser enviado
    E deve ser exibida a mensagem "Aluno não cadastrado"

  Cenário: Liberação enviada mas o aluno não passa pela catraca (triste)
    Dado que o aluno "190012345" está cadastrado e tem saldo de R$ 10,00
    E a leitura de sua identificação já resultou no envio do comando de liberação para a catraca
    E nenhum débito foi efetuado nesta tentativa de entrada
    Quando a tentativa de entrada é encerrada sem confirmação de passagem pela catraca
    Então nenhum débito deve ser efetuado
    E o saldo do aluno deve continuar sendo de R$ 10,00
