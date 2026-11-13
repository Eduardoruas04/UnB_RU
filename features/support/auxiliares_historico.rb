module AuxiliaresHistorico
  def criar_aluno(matricula)
    criar_usuario(nome: "Aluno #{matricula}", matricula: matricula, papel: "estudante")
  end

  def turno_padrao
    Turno.first || Turno.create!(nome: "Almoço", horario_inicio: "11:00",
                                 horario_fim: "14:00", valor_refeicao_centavos: 450)
  end

  def horario(hora, minuto)
    Time.zone.local(2026, 11, 12, hora, minuto)
  end

  def registrar_acesso(codigo, matricula, quando = Time.zone.now)
    Acesso.create!(
      usuario: criar_aluno(matricula),
      catraca: Catraca.find_by!(codigo_identificador: codigo),
      turno: turno_padrao,
      data_hora: quando,
      autorizado: true,
      valor_pago_centavos: 450
    )
  end

  def selecionar_catraca(codigo)
    catraca = Catraca.find_by!(codigo_identificador: codigo)
    visit historico_local_path
    select "#{catraca.codigo_identificador} - #{catraca.restaurante.nome}", from: "Catraca"
    click_button "Selecionar catraca"
  end
end

World(AuxiliaresHistorico)
