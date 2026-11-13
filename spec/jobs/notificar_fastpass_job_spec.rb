require "rails_helper"

RSpec.describe NotificarFastpassJob, type: :job do
  it "processa notificações usando o horário real da execução" do
    expect(NotificarResultadoFastpass).to receive(:call).with(no_args)
    described_class.perform_now
  end
end
