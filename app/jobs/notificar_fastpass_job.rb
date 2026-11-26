# Executa o processamento agendado dos resultados FastPass.
class NotificarFastpassJob < ApplicationJob
  queue_as :default

  # [Descrição] Aciona o serviço de notificações com o horário corrente.
  # [Argumentos] Nenhum.
  # [Retorno] Retorna +nil+ ao concluir o processamento.
  # [Efeitos colaterais] Pode persistir notificações FastPass para inscrições elegíveis.
  def perform
    NotificarResultadoFastpass.call
  end
end
