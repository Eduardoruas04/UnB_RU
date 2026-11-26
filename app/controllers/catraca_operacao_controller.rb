# Terminal de operação da catraca (Issue #6 - Validação de entrada).
#
# O funcionário lê a matrícula do aluno, o sistema decide se libera a
# entrada e, depois, a passagem é confirmada (com débito) ou encerrada
# (sem débito).
class CatracaOperacaoController < ApplicationController
  # Exibe o terminal da catraca ativa, com o turno em atendimento e o
  # último acesso lido.
  #
  # Argumentos::
  #   Nenhum. Lê +params[:acesso_id]+ (opcional), o acesso que aguarda
  #   confirmação de passagem.
  # Retorno::
  #   Nenhum valor útil; renderiza a view +show+ com +@catraca+, +@turno+
  #   e +@acesso+ (qualquer um deles pode ser +nil+).
  # Efeitos colaterais::
  #   Nenhum. Só faz consultas ao banco.
  def show
    @catraca = catraca_ativa
    @turno = Turno.em_atendimento
    @acesso = Acesso.find_by(id: params[:acesso_id])
  end

  # Processa a leitura da matrícula de um aluno na catraca.
  #
  # Argumentos::
  #   Nenhum. Lê +params[:matricula]+, a matrícula digitada ou lida.
  # Retorno::
  #   Nenhum valor útil; sempre redireciona para o terminal.
  # Efeitos colaterais::
  #   - Sem catraca ativa ou turno em atendimento: redireciona com o alerta
  #     "Nenhuma refeição em atendimento" e não grava nada.
  #   - Aluno não encontrado: redireciona com o alerta "Aluno não
  #     cadastrado" e não grava nada.
  #   - Saldo insuficiente: grava um Acesso recusado e redireciona com o
  #     alerta "Saldo insuficiente".
  #   - Saldo suficiente: grava um Acesso liberado (sem débito) e
  #     redireciona para o terminal com o acesso aguardando passagem.
  def ler
    catraca = catraca_ativa
    turno = Turno.em_atendimento
    aluno = estudante_lido
    bloqueio = motivo_de_bloqueio(catraca, turno, aluno)
    return redirect_to(catraca_operacao_path, alert: bloqueio) if bloqueio

    acesso = Acesso.registrar_leitura!(usuario: aluno, catraca: catraca, turno: turno)
    redirecionar_apos_leitura(acesso)
  end

  # Confirma que o aluno passou pela catraca e debita a refeição.
  #
  # Argumentos::
  #   Nenhum. Lê +params[:id]+, o id do Acesso.
  # Retorno::
  #   Nenhum valor útil; sempre redireciona para o terminal.
  # Efeitos colaterais::
  #   - Acesso aguardando passagem: debita a carteira, atualiza o Acesso e
  #     redireciona com o aviso "Passagem confirmada".
  #   - Caso contrário: não altera nada e redireciona com o alerta "Este
  #     acesso não está aguardando passagem".
  #   - Levanta ActiveRecord::RecordNotFound se o id não existir.
  def confirmar
    acesso = Acesso.find(params[:id])
    if acesso.confirmar_passagem!
      redirect_to catraca_operacao_path(acesso_id: acesso.id), notice: "Passagem confirmada"
    else
      redirect_to catraca_operacao_path, alert: "Este acesso não está aguardando passagem"
    end
  end

  # Encerra uma entrada liberada em que o aluno não passou pela catraca.
  #
  # Argumentos::
  #   Nenhum. Lê +params[:id]+, o id do Acesso.
  # Retorno::
  #   Nenhum valor útil; sempre redireciona para o terminal.
  # Efeitos colaterais::
  #   - Acesso aguardando passagem: marca o Acesso como não autorizado,
  #     sem debitar, e redireciona com o aviso "Entrada encerrada sem
  #     passagem".
  #   - Caso contrário: não altera nada e redireciona com o alerta "Este
  #     acesso não está aguardando passagem".
  #   - Levanta ActiveRecord::RecordNotFound se o id não existir.
  def encerrar
    acesso = Acesso.find(params[:id])
    if acesso.encerrar_sem_passagem!
      redirect_to catraca_operacao_path, notice: "Entrada encerrada sem passagem"
    else
      redirect_to catraca_operacao_path, alert: "Este acesso não está aguardando passagem"
    end
  end

  private

  # Busca a catraca em operação.
  #
  # Argumentos::
  #   Nenhum.
  # Retorno::
  #   A primeira Catraca com status "ativa", ou +nil+ se não houver.
  # Efeitos colaterais::
  #   Nenhum.
  def catraca_ativa
    Catraca.find_by(status: "ativa")
  end

  # Busca o estudante pela matrícula lida na catraca.
  #
  # Argumentos::
  #   Nenhum. Lê +params[:matricula]+ e ignora espaços nas pontas.
  # Retorno::
  #   O Usuario com papel "estudante" e essa matrícula, ou +nil+.
  # Efeitos colaterais::
  #   Nenhum.
  def estudante_lido
    Usuario.find_by(matricula: params[:matricula].to_s.strip, papel: "estudante")
  end

  # Diz por que a leitura deve ser bloqueada antes de registrar o acesso.
  #
  # Argumentos::
  #   +catraca+ - a Catraca ativa ou +nil+.
  #   +turno+ - o Turno em atendimento ou +nil+.
  #   +aluno+ - o Usuario lido ou +nil+.
  # Retorno::
  #   "Nenhuma refeição em atendimento" se faltar catraca ou turno,
  #   "Aluno não cadastrado" se faltar o aluno, ou +nil+ se a leitura
  #   pode seguir.
  # Efeitos colaterais::
  #   Nenhum.
  def motivo_de_bloqueio(catraca, turno, aluno)
    return "Nenhuma refeição em atendimento" unless catraca && turno

    "Aluno não cadastrado" unless aluno
  end

  # Redireciona para o terminal de acordo com o resultado da leitura.
  #
  # Argumentos::
  #   +acesso+ - o Acesso recém-registrado.
  # Retorno::
  #   Nenhum valor útil.
  # Efeitos colaterais::
  #   - Acesso liberado: redireciona para o terminal com o acesso
  #     selecionado e o aviso "Comando de liberação enviado para a catraca".
  #   - Acesso recusado: redireciona com o motivo da recusa como alerta.
  def redirecionar_apos_leitura(acesso)
    if acesso.autorizado?
      redirect_to catraca_operacao_path(acesso_id: acesso.id), notice: "Comando de liberação enviado para a catraca"
    else
      redirect_to catraca_operacao_path, alert: acesso.motivo_recusa
    end
  end
end
