require "rspec/expectations"

module Auxiliares
  def criar_usuario(nome:, matricula:, papel:)
    Usuario.find_or_create_by!(matricula: matricula) do |u|
      u.nome = nome
      u.email = "#{matricula.downcase}@teste.unb.br"
      u.password = "senha123"
      u.papel = papel
      u.ativo = true
    end
  end

  # Usa o login rápido da Home até a autenticação oficial (#4) existir
  def entrar_como(usuario)
    visit root_path
    click_button usuario.nome
  end

  # O rack_test não atualiza a página sozinho: depois de criar dados no banco,
  # abre a página de novo para o HTML refletir o que existe.
  def recarregar_gestao
    visit restaurantes_path
  end

  def secao_do_restaurante(nome)
    "#restaurante_#{Restaurante.find_by!(nome: nome).id}"
  end

  def editar_restaurante(atual, novo)
    within(secao_do_restaurante(atual)) { first(:link, "Editar").click }
    fill_in "Nome do restaurante", with: novo
    click_button "Atualizar restaurante"
  end

  # ---------- Histórico local (#7) ----------
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

World(RSpec::Matchers)
World(Auxiliares)
