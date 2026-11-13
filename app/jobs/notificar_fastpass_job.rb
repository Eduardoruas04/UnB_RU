class NotificarFastpassJob < ApplicationJob
  queue_as :default

  def perform
    NotificarResultadoFastpass.call
  end
end
