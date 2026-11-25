# Registra notificações dos resultados FastPass no minuto programado.
class NotificarResultadoFastpass
  # [Descrição] Processa os sorteios realizados que podem ter envio programado no minuto informado.
  # [Argumentos] +agora+ é o instante de referência, convertido para o fuso de Brasília. O padrão é Time.current.
  # [Retorno] Retorna +nil+ ao concluir a iteração.
  # [Efeitos colaterais] Consulta sorteios e pode persistir notificações para estudantes elegíveis.
  def self.call(agora: Time.current)
    agora = agora.in_time_zone("America/Sao_Paulo")
    hoje = agora.to_date
    datas = hoje..(hoje + 1)
    SorteioFastpass.where(status: "realizado", data_sorteio: datas).find_each do |sorteio|
      processar_sorteio(sorteio, agora)
    end
  end

  class << self
    private

    # [Descrição] Processa um sorteio no minuto programado e verifica seu status sob trava.
    # [Argumentos] +sorteio+ é o SorteioFastpass em avaliação. +agora+ é o instante de referência.
    # [Retorno] Retorna +nil+ ao concluir ou quando o sorteio fica fora da janela ou deixou de estar realizado.
    # [Efeitos colaterais] Pode adquirir uma trava transacional no sorteio e gravar notificações.
    def processar_sorteio(sorteio, agora)
      programado = sorteio.horario_notificacao
      return unless agora >= programado && agora < programado + 1.minute

      sorteio.with_lock do
        notificar_inscritos(sorteio, agora) if sorteio.status == "realizado"
      end
    end

    # [Descrição] Percorre inscrições de estudantes com resultado definido.
    # [Argumentos] +sorteio+ fornece as inscrições. +agora+ é o instante registrado nas novas notificações.
    # [Retorno] Retorna +nil+ ao concluir a iteração.
    # [Efeitos colaterais] Pode persistir notificações para estudantes sorteados e não sorteados.
    def notificar_inscritos(sorteio, agora)
      sorteio.inscricoes_fastpass.includes(:usuario).find_each do |inscricao|
        next unless inscricao.usuario.papel == "estudante"
        next unless [ "sorteado", "nao_sorteado" ].include?(inscricao.status)

        registrar_notificacao(sorteio, inscricao, agora)
      end
    end

    # [Descrição] Localiza ou cria o aviso FastPass para o estudante do sorteio.
    # [Argumentos] +sorteio+ identifica o sorteio. +inscricao+ identifica o estudante e seu resultado. +agora+ é o instante de envio.
    # [Retorno] Retorna a Notificacao existente ou recém-criada. Lança ActiveRecord::RecordInvalid se a nova notificação falhar na validação.
    # [Efeitos colaterais] Insere a notificação quando ela ainda não existe.
    def registrar_notificacao(sorteio, inscricao, agora)
      sorteio.notificacoes.find_or_create_by!(usuario: inscricao.usuario, tipo: "fastpass") do |notificacao|
        notificacao.assign_attributes(
          titulo: "Resultado do FastPass", mensagem: mensagem_resultado(sorteio, inscricao),
          status_envio: "enviada", enviado_em: agora, lida: false
        )
      end
    end

    # [Descrição] Monta a mensagem adequada ao resultado do estudante.
    # [Argumentos] +sorteio+ fornece o horário do FastPass. +inscricao+ fornece o status do resultado.
    # [Retorno] Uma String com o horário para sorteados ou com o aviso de resultado negativo.
    # [Efeitos colaterais] Nenhum.
    def mensagem_resultado(sorteio, inscricao)
      if inscricao.status == "sorteado"
        "Você foi sorteado para o FastPass. Horário do FastPass: #{sorteio.horario_fastpass.strftime('%d/%m/%Y às %H:%M')}."
      else
        "Você não foi sorteado para o FastPass."
      end
    end
  end
end
