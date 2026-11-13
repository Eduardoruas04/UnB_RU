require "rails_helper"

RSpec.describe NotificarResultadoFastpass do
  let!(:turno) { Turno.create!(nome: "Almoço", horario_inicio: "12:00", horario_fim: "14:00", valor_refeicao_centavos: 450) }
  let!(:sorteio) { SorteioFastpass.create!(turno: turno, data_sorteio: Date.new(2026, 11, 12), status: "realizado", vagas_disponiveis: 1) }
  let!(:usuario) { Usuario.create!(nome: "Maria", matricula: "190012345", email: "maria@unb.br", password: "senha1234", papel: "estudante") }
  let!(:inscricao) { sorteio.inscricoes_fastpass.create!(usuario: usuario, status: "sorteado") }
  let(:agora) { sorteio.horario_notificacao }

  it "entrega o resultado e horário do vencedor no minuto programado em Brasília" do
    described_class.call(agora: agora + 30.seconds)
    notificacao = usuario.notificacoes.sole
    expect(notificacao.mensagem).to include("Você foi sorteado", "12/11/2026 às 12:00")
    expect(notificacao.enviado_em).to eq(agora + 30.seconds)
    expect(notificacao.status_envio).to eq("enviada")
    expect(notificacao.lida).to be(false)
  end

  it "notifica quem não foi sorteado" do
    inscricao.update!(status: "nao_sorteado")
    described_class.call(agora: agora)
    expect(usuario.notificacoes.sole.mensagem).to eq("Você não foi sorteado para o FastPass.")
  end

  it "não duplica notificações quando executado novamente" do
    2.times { described_class.call(agora: agora) }
    expect(usuario.notificacoes.count).to eq(1)
  end

  it "impede duplicidade também no banco" do
    described_class.call(agora: agora)
    copia = usuario.notificacoes.sole.dup
    expect { copia.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  [ -1.second, 1.minute, 1.day ].each do |deslocamento|
    it "não envia fora do minuto programado (#{deslocamento})" do
      expect { described_class.call(agora: agora + deslocamento) }.not_to change(Notificacao, :count)
    end
  end

  it "não envia sem sorteio realizado" do
    sorteio.update!(status: "pendente")
    expect { described_class.call(agora: agora) }.not_to change(Notificacao, :count)
  end

  it "não envia sem resultado individual" do
    inscricao.update!(status: "pendente")
    expect { described_class.call(agora: agora) }.not_to change(Notificacao, :count)
  end

  it "não envia para não inscritos" do
    inscricao.destroy!
    expect { described_class.call(agora: agora) }.not_to change(Notificacao, :count)
  end

  it "não envia para funcionários" do
    usuario.update!(papel: "funcionario")
    expect { described_class.call(agora: agora) }.not_to change(Notificacao, :count)
  end

  it "considera o dia seguinte quando o turno começa após meia-noite" do
    turno.update!(horario_inicio: "00:30", horario_fim: "02:00")
    expect(sorteio.horario_notificacao.to_date).to eq(Date.new(2026, 11, 11))
    described_class.call(agora: sorteio.horario_notificacao)
    expect(usuario.notificacoes.sole.mensagem).to include("12/11/2026 às 00:30")
  end
end
