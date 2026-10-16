# language: pt
# Issue #4 - MVP

# funcional e senha; páginas da aplicação de controle exigem sessão autenticada.

Funcionalidade: Autenticação do funcionário
  Como funcionário do restaurante
  Quero fazer login na aplicação de controle
  Para autenticar minha sessão e operar o sistema de forma segura

  Contexto:
    Dado que existe um funcionário ativo com matrícula "FUNC001" e senha "senhaSegura1"
    E existe um funcionário inativo com matrícula "FUNC002" e senha "senhaSegura1"
    E eu estou na página de login da aplicação de controle

  Cenário: Login com credenciais válidas (feliz)
    Quando eu preencho a matrícula com "FUNC001"
    E eu preencho a senha com "senhaSegura1"
    E eu clico em "Entrar"
    Então eu devo ser redirecionado para o painel da aplicação de controle
    E eu devo ver a mensagem "Login realizado com sucesso"

  Cenário: Logout da aplicação de controle com sucesso (feliz)
    Dado que eu estou autenticado no painel com a matrícula "FUNC001"
    Quando eu clico no botão "Sair"
    Então a minha sessão deve ser encerrada
    E eu devo ser redirecionado para a página de login com a mensagem "Sessão encerrada com sucesso"

  Cenário: Login com senha incorreta (triste)
    Quando eu preencho a matrícula com "FUNC001"
    E eu preencho a senha com "senhaErrada"
    E eu clico em "Entrar"
    Então eu devo ver a mensagem "Matrícula ou senha inválidos"
    E eu devo continuar na página de login

  Cenário: Login com matrícula inexistente (triste)
    Quando eu preencho a matrícula com "FUNC999"
    E eu preencho a senha com "senhaSegura1"
    E eu clico em "Entrar"
    Então eu devo ver a mensagem "Matrícula ou senha inválidos"

  Cenário: Login com funcionário inativo (triste)
    Quando eu preencho a matrícula com "FUNC002"
    E eu preencho a senha com "senhaSegura1"
    E eu clico em "Entrar"
    Então eu devo ver a mensagem "Conta de funcionário inativa"
    E eu devo continuar na página de login

  Cenário: Login com campos em branco (triste)
    Quando eu clico em "Entrar"
    Então eu devo ver a mensagem "Matrícula e senha são obrigatórias"

  Cenário: Acesso ao painel sem estar autenticado (triste)
    Dado que eu não estou autenticado
    Quando eu tento acessar o painel da aplicação de controle
    Então eu devo ser redirecionado para a página de login