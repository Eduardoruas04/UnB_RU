namespace :fastpass do
  desc "Processa notificações FastPass programadas para o minuto atual (horário de Brasília)"
  task notificar: :environment do
    NotificarResultadoFastpass.call
  end
end
