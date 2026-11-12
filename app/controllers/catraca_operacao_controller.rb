# Issue #6 - Validação de entrada na catraca
class CatracaOperacaoController < ApplicationController
  def show
    @catraca = Catraca.find_by(status: "ativa")
    @turno = Turno.em_atendimento
    @acesso = Acesso.find_by(id: params[:acesso_id])
  end

  def ler
    catraca = Catraca.find_by(status: "ativa")
    turno = Turno.em_atendimento
    aluno = Usuario.find_by(matricula: params[:matricula].to_s.strip, papel: "estudante")

    if catraca.nil? || turno.nil?
      redirect_to catraca_operacao_path, alert: "Nenhuma refeição em atendimento"
    elsif aluno.nil?
      redirect_to catraca_operacao_path, alert: "Aluno não cadastrado"
    elsif aluno.carteira.nil? || aluno.carteira.saldo_centavos < turno.valor_refeicao_centavos
      Acesso.create!(usuario: aluno, catraca: catraca, turno: turno, autorizado: false,
                     valor_pago_centavos: 0, motivo_recusa: "Saldo insuficiente", data_hora: Time.current)
      redirect_to catraca_operacao_path, alert: "Saldo insuficiente"
    else
      acesso = Acesso.create!(usuario: aluno, catraca: catraca, turno: turno, autorizado: true,
                              valor_pago_centavos: 0, data_hora: Time.current)
      redirect_to catraca_operacao_path(acesso_id: acesso.id), notice: "Comando de liberação enviado para a catraca"
    end
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
end
