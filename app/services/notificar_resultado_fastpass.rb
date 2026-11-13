class NotificarResultadoFastpass
  def self.call(agora: Time.current)
    agora = agora.in_time_zone("America/Sao_Paulo")
    SorteioFastpass.where(status: "realizado", data_sorteio: agora.to_date..(agora.to_date + 1)).find_each do |sorteio|
      programado = sorteio.horario_notificacao
      next unless agora >= programado && agora < programado + 1.minute

      sorteio.with_lock do
        next unless sorteio.status == "realizado"

        sorteio.inscricoes_fastpass.includes(:usuario).find_each do |inscricao|
          next unless inscricao.usuario.papel == "estudante"
          next unless [ "sorteado", "nao_sorteado" ].include?(inscricao.status)

          sorteio.notificacoes.find_or_create_by!(usuario: inscricao.usuario, tipo: "fastpass") do |notificacao|
            mensagem = if inscricao.status == "sorteado"
              "Você foi sorteado para o FastPass. Horário do FastPass: #{sorteio.horario_fastpass.strftime('%d/%m/%Y às %H:%M')}."
            else
              "Você não foi sorteado para o FastPass."
            end
            notificacao.assign_attributes(titulo: "Resultado do FastPass", mensagem: mensagem,
              status_envio: "enviada", enviado_em: agora, lida: false)
          end
        end
      end
    end
  end
end
