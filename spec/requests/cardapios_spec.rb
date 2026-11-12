require "rails_helper"

RSpec.describe "Cardápio da refeição atual", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro", ativo: true) }
  let!(:almoco) { Turno.create!(nome: "Almoço", horario_inicio: "11:00", horario_fim: "14:00", valor_refeicao_centavos: 450) }
  let!(:jantar) { Turno.create!(nome: "Jantar", horario_inicio: "17:30", horario_fim: "20:00", valor_refeicao_centavos: 450) }

  def em(hora, &bloco)
    travel_to(Time.find_zone("America/Sao_Paulo").parse("2026-11-09 #{hora}"), &bloco)
  end

  def cardapio_de(turno, padrao)
    cardapio = Cardapio.create!(restaurante: restaurante, turno: turno, data_refeicao: Date.new(2026, 11, 9))
    cardapio.itens_cardapio.create!(categoria: "prato_principal_padrao", descricao: padrao)
    cardapio.itens_cardapio.create!(categoria: "prato_principal_ovolactovegetariano", descricao: "Quiche")
    cardapio.itens_cardapio.create!(categoria: "prato_principal_vegetariano_estrito", descricao: "Refogado")
    cardapio
  end

  it "mostra as três opções da refeição atual e não as de outra refeição" do
    cardapio_de(almoco, "Frango assado")
    cardapio_de(jantar, "Lagarto")
    em("12:00") { get cardapio_atual_path }
    expect(response.body).to include("segunda-feira", "Almoço", "Frango assado", "Quiche", "Refogado")
    expect(response.body).not_to include("Lagarto")
  end

  it "informa quando o cardápio não está cadastrado" do
    em("12:00") { get cardapio_atual_path }
    expect(response.body).to include("Cardápio da refeição atual indisponível")
  end

  it "informa quando o restaurante está inativo" do
    cardapio_de(almoco, "Frango assado")
    restaurante.update!(ativo: false)
    em("12:00") { get cardapio_atual_path }
    expect(response.body).to include("Cardápio da refeição atual indisponível")
    expect(response.body).not_to include("Frango assado")
  end

  it "informa quando não há refeição em atendimento" do
    em("15:30") { get cardapio_atual_path }
    expect(response.body).to include("Não há refeição em atendimento no momento")
  end
end
