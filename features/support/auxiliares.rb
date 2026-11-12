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

  def secao_do_restaurante(nome)
    "#restaurante_#{Restaurante.find_by!(nome: nome).id}"
  end

  def editar_restaurante(atual, novo)
    within(secao_do_restaurante(atual)) { first(:link, "Editar").click }
    fill_in "Nome do restaurante", with: novo
    click_button "Atualizar restaurante"
  end
    # O rack_test não atualiza a página sozinho: depois de criar dados no banco,
    # abre a página de novo para o HTML refletir o que existe.
  def recarregar_gestao
    visit restaurantes_path
  end
end

World(RSpec::Matchers)
World(Auxiliares)