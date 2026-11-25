
require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  describe "configurações padrão" do
    it "define o remetente padrão" do
      expect(described_class.default[:from]).to eq("from@example.com")
    end

    it "utiliza o layout mailer" do
      expect(described_class._layout).to eq("mailer")
    end
  end
end
