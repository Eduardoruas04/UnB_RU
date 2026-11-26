# frozen_string_literal: true

# Controller responsável pela Issue #2 (MVP): Recarga de Saldo de Refeições.
# Implementa as regras contábeis do RU UnB (tarifa fixa de R$ 4,50 em centavos,
# pacotes pré-definidos e quantidade customizada de 1 a 100 refeições) e o fluxo
# de pagamento via PIX Instantâneo ou Cartão de Crédito conforme o Figma US03.
class RecargasController < ApplicationController
  before_action :autenticar_usuario!
  before_action :carregar_conta, only: [ :new, :create, :show ]
  before_action :set_recarga, only: [ :show, :confirmar ]

  # Tarifa oficial da refeição fixada em centavos (R$ 4,50) para evitar imprecisão de ponto flutuante.
  TARIFA_UNITARIA_CENTAVOS = 450

  # Quantidade padrão de refeições pré-selecionada na tela inicial de recarga.
  QUANTIDADE_PADRAO = 5

  # Quantidade mínima permitida por operação de recarga.
  QUANTIDADE_MINIMA = 1

  # Quantidade máxima permitida por operação de recarga.
  QUANTIDADE_MAXIMA = 100

  # Mapa de status de erro simulados de cartão de crédito para suas mensagens de alerta.
  ERROS_CARTAO = {
    "vencido" => "Cartão vencido",
    "recusado" => "Pagamento recusado"
  }.freeze

  # Renderiza a tela de compra de créditos (GET /recargas/new) com saldo atual
  # e resumo calculado para a quantidade inicial selecionada.
  #
  # Argumentos:
  # * Nenhum (lê indiretamente +params[:quantidade_refeicoes]+ e +params[:pacote]+).
  #
  # Retorno:
  # * [Recarga] Nova instância não persistida de +Recarga+ atribuída a +@recarga+.
  #
  # Efeitos colaterais:
  # * Define as variáveis de instância consumidas pela view +recargas/new.html.erb+.
  # * Renderiza a view HTML +recargas/new+.
  def new
    preparar_dados_view(quantidade_inicial)
  end

  # Processa a solicitação de recarga (POST /recargas), validando forma de
  # pagamento, formato numérico e limites antes de despachar para PIX ou Cartão.
  #
  # Argumentos:
  # * Nenhum (lê +params[:metodo_pagamento]+, +params[:quantidade_refeicoes]+ e +params[:cartao_status]+).
  #
  # Retorno:
  # * [String, nil] Resultado da renderização de erro (status 422) ou do redirecionamento do pagamento.
  #
  # Efeitos colaterais:
  # * Em caso de dados inválidos, define +flash.now[:alert]+ e renderiza +:new+ com status 422.
  # * Em caso de dados válidos, cria registro em +recargas+, podendo creditar +carteiras+ e redirecionar.
  def create
    metodo = params[:metodo_pagamento]
    quantidade_raw = params[:quantidade_refeicoes]
    erro = erro_validacao_recarga(metodo, quantidade_raw)
    return renderizar_erro_recarga(erro) if erro

    despachar_pagamento(metodo, quantidade_raw.to_i)
  end

  # Exibe os detalhes do PIX gerado (GET /recargas/:id), incluindo QR Code
  # simulado, valor e chave Copia-e-Cola da recarga pendente.
  #
  # Argumentos:
  # * Nenhum (+@usuario+, +@carteira+ e +@recarga+ são carregados pelos +before_action+).
  #
  # Retorno:
  # * [nil] Não retorna valor explícito.
  #
  # Efeitos colaterais:
  # * Renderiza a view HTML +recargas/show+.
  def show
  end

  # Simula a liquidação bancária de uma recarga PIX pendente (POST /recargas/:id/confirmar),
  # aprovando e creditando o saldo ou cancelando em caso de prazo expirado.
  #
  # Argumentos:
  # * Nenhum (verifica +params[:expirado]+).
  #
  # Retorno:
  # * [String] URL de redirecionamento para +new_recarga_path+.
  #
  # Efeitos colaterais:
  # * Atualiza o status da recarga na tabela +recargas+ (e incrementa +carteiras+ quando aprovada).
  # * Define +flash[:notice]+ ou +flash[:alert]+ e redireciona para +new_recarga_path+.
  def confirmar
    params[:expirado] == "true" ? cancelar_recarga_pix : aprovar_recarga_pix
  end

  private

  # Carrega o estudante autenticado e garante a existência de sua carteira vinculada.
  #
  # Argumentos:
  # * Nenhum (utiliza +current_user+).
  #
  # Retorno:
  # * [Carteira, nil] Carteira existente ou recém-criada do usuário autenticado.
  #
  # Efeitos colaterais:
  # * Define +@usuario+ e +@carteira+.
  # * Cria um registro na tabela +carteiras+ com saldo zero caso o usuário ainda não possua carteira.
  def carregar_conta
    @usuario = current_user
    @carteira = @usuario.carteira || @usuario.create_carteira(saldo_centavos: 0)
  end

  # Localiza a recarga solicitada restrita ao estudante atualmente autenticado.
  #
  # Argumentos:
  # * Nenhum (lê +params[:id]+).
  #
  # Retorno:
  # * [Recarga] Instância encontrada pertencente a +current_user+.
  #
  # Efeitos colaterais:
  # * Define +@recarga+ (ou levanta +ActiveRecord::RecordNotFound+ se o registro não pertencer ao usuário).
  def set_recarga
    @recarga = current_user.recargas.find(params[:id])
  end

  # Determina a quantidade inicial de refeições a exibir no formulário de recarga.
  #
  # Argumentos:
  # * Nenhum (lê +params[:quantidade_refeicoes]+ e +params[:pacote]+).
  #
  # Retorno:
  # * [Integer] Quantidade informada quando positiva, ou +QUANTIDADE_PADRAO+ (5) como fallback.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def quantidade_inicial
    qtd = (params[:quantidade_refeicoes] || params[:pacote] || QUANTIDADE_PADRAO).to_i
    qtd.positive? ? qtd : QUANTIDADE_PADRAO
  end

  # Converte o saldo atual da carteira (em centavos) para a quantidade inteira de refeições.
  #
  # Argumentos:
  # * Nenhum (lê +@carteira+).
  #
  # Retorno:
  # * [Integer] Número inteiro de refeições disponíveis na carteira.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def saldo_em_refeicoes
    @carteira.saldo_centavos / TARIFA_UNITARIA_CENTAVOS
  end

  # Formata um valor monetário em centavos para string no padrão brasileiro (vírgula decimal).
  #
  # Argumentos:
  # * +centavos+ [Integer] - Valor monetário em centavos.
  #
  # Retorno:
  # * [String] Valor formatado com duas casas decimais e vírgula (ex: +"22,50"+).
  #
  # Efeitos colaterais:
  # * Nenhum.
  def formatar_reais(centavos)
    sprintf("%.2f", centavos / 100.0).tr(".", ",")
  end

  # Executa as validações de negócio dos dados submetidos na criação de recarga.
  #
  # Argumentos:
  # * +metodo+ [String, nil] - Forma de pagamento escolhida pelo estudante.
  # * +quantidade_raw+ [String, Integer, nil] - Valor bruto informado no campo de quantidade.
  #
  # Retorno:
  # * [String, nil] Mensagem de erro correspondente à primeira violação, ou +nil+ se os dados forem válidos.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def erro_validacao_recarga(metodo, quantidade_raw)
    return "Selecione uma forma de pagamento" if metodo.blank?
    return "Informe uma quantidade numérica válida" unless quantidade_valida?(quantidade_raw)

    erro_limites_quantidade(quantidade_raw.to_i)
  end

  # Verifica se a quantidade inteira respeita os limites mínimo (1) e máximo (100) de refeições.
  #
  # Argumentos:
  # * +quantidade+ [Integer] - Quantidade de refeições já convertida para inteiro.
  #
  # Retorno:
  # * [String, nil] Mensagem de erro de limite violado, ou +nil+ quando está dentro do intervalo permitido.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def erro_limites_quantidade(quantidade)
    return "A quantidade mínima é de 1 refeição" if quantidade < QUANTIDADE_MINIMA
    return "A quantidade máxima é de 100 refeições" if quantidade > QUANTIDADE_MAXIMA

    nil
  end

  # Reexibe o formulário de recarga com mensagem de alerta e código HTTP 422.
  #
  # Argumentos:
  # * +mensagem+ [String] - Mensagem de erro a ser exibida ao estudante.
  #
  # Retorno:
  # * [String] Corpo HTML renderizado da view +:new+.
  #
  # Efeitos colaterais:
  # * Define +flash.now[:alert]+, recompõe as variáveis da view e renderiza +:new+ com status +:unprocessable_entity+.
  def renderizar_erro_recarga(mensagem)
    flash.now[:alert] = mensagem
    preparar_dados_view
    render :new, status: :unprocessable_entity
  end

  # Calcula o valor total em centavos e encaminha a recarga para o fluxo de Cartão ou PIX.
  #
  # Argumentos:
  # * +metodo+ [String] - Forma de pagamento selecionada (+"Cartão de Crédito"+ ou +"PIX Instantâneo"+).
  # * +quantidade+ [Integer] - Quantidade validada de refeições.
  #
  # Retorno:
  # * [String] Resposta HTTP (renderização de erro ou redirecionamento) produzida pelo fluxo selecionado.
  #
  # Efeitos colaterais:
  # * Delega persistência em banco, atualização de saldo e resposta HTTP para +processar_cartao+ ou +processar_pix+.
  def despachar_pagamento(metodo, quantidade)
    valor_centavos = quantidade * TARIFA_UNITARIA_CENTAVOS
    if metodo == "Cartão de Crédito"
      processar_cartao(quantidade, valor_centavos)
    else
      processar_pix(quantidade, valor_centavos)
    end
  end

  # Verifica via expressão regular se a entrada representa um número inteiro válido.
  #
  # Argumentos:
  # * +raw+ [String, Integer, nil] - Valor bruto recebido do formulário.
  #
  # Retorno:
  # * [Boolean] +true+ se for um inteiro (positivo ou negativo); +false+ se em branco ou não numérico.
  #
  # Efeitos colaterais:
  # * Nenhum.
  def quantidade_valida?(raw)
    return false if raw.blank?

    raw.to_s.strip.match?(/\A-?\d+\z/)
  end

  # Inicializa todas as variáveis de instância necessárias para renderizar a tela +recargas/new+.
  #
  # Argumentos:
  # * +quantidade+ [Integer] - Quantidade de refeições usada no resumo (padrão: +QUANTIDADE_PADRAO+).
  #
  # Retorno:
  # * [Recarga] Nova instância de +Recarga+ atribuída a +@recarga+.
  #
  # Efeitos colaterais:
  # * Define +@saldo_refeicoes+, +@quantidade+, +@total_formatado+, +@novo_saldo_refs+ e +@recarga+.
  def preparar_dados_view(quantidade = QUANTIDADE_PADRAO)
    @saldo_refeicoes = saldo_em_refeicoes
    @quantidade = quantidade
    @total_formatado = formatar_reais(quantidade * TARIFA_UNITARIA_CENTAVOS)
    @novo_saldo_refs = @saldo_refeicoes + quantidade
    @recarga = Recarga.new
  end

  # Processa uma tentativa de pagamento por cartão de crédito, tratando cartões
  # vencidos ou recusados antes de efetivar a transação.
  #
  # Argumentos:
  # * +quantidade+ [Integer] - Quantidade de refeições adquiridas.
  # * +valor_centavos+ [Integer] - Valor total da compra em centavos.
  #
  # Retorno:
  # * [String] HTML de erro (status 422) em caso de recusa/vencimento, ou URL de redirecionamento em caso de sucesso.
  #
  # Efeitos colaterais:
  # * Em erro, define +flash.now[:alert]+ e renderiza +:new+ com status 422 sem alterar o banco.
  # * Em sucesso, persiste a recarga paga, incrementa a carteira, define +flash[:notice]+ e redireciona para +new_recarga_path+.
  def processar_cartao(quantidade, valor_centavos)
    erro = ERROS_CARTAO[params[:cartao_status]]
    return renderizar_erro_recarga(erro) if erro

    efetivar_recarga_cartao(quantidade, valor_centavos)
    flash[:notice] = "Recarga realizada com sucesso"
    redirect_to new_recarga_path
  end

  # Persiste a recarga paga por cartão e credita o saldo da carteira em transação ACID.
  #
  # Argumentos:
  # * +quantidade+ [Integer] - Quantidade de refeições adquiridas.
  # * +valor_centavos+ [Integer] - Montante financeiro em centavos a creditar.
  #
  # Retorno:
  # * [Carteira] Instância da carteira após incremento atômico de +saldo_centavos+.
  #
  # Efeitos colaterais:
  # * Cria um registro com status +"paga"+ na tabela +recargas+ e define +@recarga+.
  # * Incrementa +saldo_centavos+ na tabela +carteiras+ dentro de +ActiveRecord::Base.transaction+.
  def efetivar_recarga_cartao(quantidade, valor_centavos)
    ActiveRecord::Base.transaction do
      @recarga = @usuario.recargas.create!(
        carteira: @carteira,
        quantidade_refeicoes: quantidade,
        valor_centavos: valor_centavos,
        status: "paga",
        metodo_pagamento: "Cartão de Crédito"
      )
      @carteira.increment!(:saldo_centavos, valor_centavos)
    end
  end

  # Cria uma recarga pendente via PIX Instantâneo com TXID exclusivo e redireciona para a tela do QR Code.
  #
  # Argumentos:
  # * +quantidade+ [Integer] - Quantidade de refeições solicitadas.
  # * +valor_centavos+ [Integer] - Valor total da cobrança PIX em centavos.
  #
  # Retorno:
  # * [String] URL de redirecionamento para +recarga_path(@recarga)+.
  #
  # Efeitos colaterais:
  # * Cria um registro com status +"pendente"+ e +txid_pix+ na tabela +recargas+ e define +@recarga+.
  # * Redireciona a requisição HTTP para +recarga_path(@recarga)+ sem alterar o saldo da carteira.
  def processar_pix(quantidade, valor_centavos)
    txid = "PIX-#{SecureRandom.hex(8).upcase}"
    @recarga = @usuario.recargas.create!(
      carteira: @carteira,
      quantidade_refeicoes: quantidade,
      valor_centavos: valor_centavos,
      status: "pendente",
      metodo_pagamento: "PIX Instantâneo",
      txid_pix: txid
    )
    redirect_to recarga_path(@recarga)
  end

  # Cancela uma recarga PIX cujo prazo expirou sem confirmação bancária.
  #
  # Argumentos:
  # * Nenhum (opera sobre +@recarga+).
  #
  # Retorno:
  # * [String] URL de redirecionamento para +new_recarga_path+.
  #
  # Efeitos colaterais:
  # * Atualiza o registro em +recargas+ para status +"cancelada"+ sem creditar a carteira.
  # * Define +flash[:alert]+ e redireciona para +new_recarga_path+.
  def cancelar_recarga_pix
    @recarga.update(status: "cancelada")
    flash[:alert] = "Pagamento não confirmado"
    redirect_to new_recarga_path
  end

  # Liquida uma recarga PIX confirmada, marcando-a como paga e creditando a carteira atomicamente.
  #
  # Argumentos:
  # * Nenhum (opera sobre +@recarga+).
  #
  # Retorno:
  # * [String] URL de redirecionamento para +new_recarga_path+.
  #
  # Efeitos colaterais:
  # * Atualiza +@recarga+ para status +"paga"+ e incrementa +saldo_centavos+ da carteira em transação ACID.
  # * Define +flash[:notice]+ e redireciona para +new_recarga_path+.
  def aprovar_recarga_pix
    ActiveRecord::Base.transaction do
      @recarga.update!(status: "paga")
      @recarga.carteira.increment!(:saldo_centavos, @recarga.valor_centavos)
    end
    flash[:notice] = "Recarga realizada com sucesso"
    redirect_to new_recarga_path
  end
end
