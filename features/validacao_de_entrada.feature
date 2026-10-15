# language: pt
# Issue #6 - MVP
# REGRAS ASSUMIDAS (ajustar com o grupo): preço da refeição de R$ 5,00 (valor
# de exemplo); entrada liberada com saldo maior ou igual ao preço; o débito só
# acontece quando a catraca confirma a passagem.

Funcionalidade: Validação de entrada
  Como aplicação de controle
  Quero ler a identificação do aluno, verificar se há saldo, enviar o comando de liberação para a catraca e efetuar o débito da refeição no momento da passagem
  Para que apenas alunos com saldo suficiente acessem o restaurante

  Contexto:
    Dado que o preço da refeição é de R$ 5,00
    E existe uma catraca ativa no restaurante

  Cenário: Entrada liberada e débito efetuado na passagem (feliz)
    Dado que o aluno "190012345" tem saldo de R$ 10,00
    Quando a identificação do aluno "190012345" é lida na catraca
    Então o comando de liberação deve ser enviado para a catraca
    E quando a catraca confirma a passagem
    Então o saldo do aluno deve ser de R$ 5,00

  Cenário: Entrada com saldo exatamente igual ao preço (feliz)
    Dado que o aluno "190012345" tem saldo de R$ 5,00
    Quando a identificação do aluno "190012345" é lida na catraca
    Então o comando de liberação deve ser enviado para a catraca
    E quando a catraca confirma a passagem
    Então o saldo do aluno deve ser de R$ 0,00

  Cenário: Entrada negada por saldo insuficiente (triste)
    Dado que o aluno "190012345" tem saldo de R$ 4,99
    Quando a identificação do aluno "190012345" é lida na catraca
    Então nenhum comando de liberação deve ser enviado
    E deve ser exibida a mensagem "Saldo insuficiente"
    E o saldo do aluno deve continuar sendo de R$ 4,99

  Cenário: Identificação não reconhecida (triste)
    Quando a identificação "000000000" é lida na catraca
    Então nenhum comando de liberação deve ser enviado
    E deve ser exibida a mensagem "Aluno não cadastrado"

  Cenário: Liberação enviada mas o aluno não passa pela catraca (triste)
    Dado que o aluno "190012345" tem saldo de R$ 10,00
    Quando a identificação do aluno "190012345" é lida na catraca
    E o comando de liberação é enviado para a catraca
    E a catraca não registra passagem dentro do tempo limite
    Então nenhum débito deve ser efetuado
    E o saldo do aluno deve continuar sendo de R$ 10,00
