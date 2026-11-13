require "rails_helper"

RSpec.describe ItemCardapio, "opções do cardápio" do
  def item(categoria)
    ItemCardapio.new(categoria: categoria, descricao: "Prato")
  end

  it "identifica a opção pelo final da categoria" do
    expect(item("prato_principal_padrao").opcao).to eq("padrao")
    expect(item("prato_principal_ovolactovegetariano").opcao).to eq("ovolactovegetariano")
    expect(item("complemento_vegetariano_estrito").opcao).to eq("vegetariano_estrito")
  end

  it "não considera outras categorias como opção" do
    expect(item("guarnicao").opcao).to be_nil
  end

  it "informa se é prato principal ou complemento" do
    expect(item("prato_principal_padrao").tipo).to eq("Prato principal")
    expect(item("complemento_padrao").tipo).to eq("Complemento")
  end
end
