# Issue #6 - Validação de entrada na catraca
class CatracaOperacaoController < ApplicationController
  def show
    @catraca = catraca_ativa
    @turno = Turno.em_atendimento
    @acesso = Acesso.find_by(id: params[:acesso_id])
  end

  def ler
    catraca = catraca_ativa
    turno = Turno.em_atendimento
    aluno = estudante_lido
    bloqueio = motivo_de_bloqueio(catraca, turno, aluno)
    return redirect_to(catraca_operacao_path, alert: bloqueio) if bloqueio

    acesso = Acesso.registrar_leitura!(usuario: aluno, catraca: catraca, turno: turno)
    redirecionar_apos_leitura(acesso)
  end

  def confirmar
    acesso = Acesso.find(params[:id])
    if acesso.confirmar_passagem!
      redirect_to catraca_operacao_path(acesso_id: acesso.id), notice: "Passagem confirmada"
    else
      redirect_to catraca_operacao_path, alert: "Este acesso não está aguardando passagem"
    end
  end

  def encerrar
    acesso = Acesso.find(params[:id])
    if acesso.encerrar_sem_passagem!
      redirect_to catraca_operacao_path, notice: "Entrada encerrada sem passagem"
    else
      redirect_to catraca_operacao_path, alert: "Este acesso não está aguardando passagem"
    end
  end

  private

  def catraca_ativa
    Catraca.find_by(status: "ativa")
  end

  def estudante_lido
    Usuario.find_by(matricula: params[:matricula].to_s.strip, papel: "estudante")
  end

  def motivo_de_bloqueio(catraca, turno, aluno)
    return "Nenhuma refeição em atendimento" unless catraca && turno

    "Aluno não cadastrado" unless aluno
  end

  def redirecionar_apos_leitura(acesso)
    if acesso.autorizado?
      redirect_to catraca_operacao_path(acesso_id: acesso.id), notice: "Comando de liberação enviado para a catraca"
    else
      redirect_to catraca_operacao_path, alert: acesso.motivo_recusa
    end
  end
end
