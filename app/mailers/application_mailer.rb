# Classe base para envio de e-mails transacionais da aplicação UnB RU.
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
