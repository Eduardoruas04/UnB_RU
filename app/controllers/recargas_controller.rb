# Controller responsavel pela Issue #2 (MVP): Recarga de Saldo de Refeicoes
# Implementa regras contabeis do RU UnB e interface conforme Figma US03.
class RecargasController < ApplicationController
  before_action :autenticar_usuario!
  before_action :set_recarga, only: [ :show, :confirmar ]

  # Tarifa oficial da refeicao fixada em centavos (R$ 4,50) para evitar imprecisao de float
  TARIFA_UNITARIA_CENTAVOS = 450

  # GET /recargas/new
  # Renderiza a tela de compra de creditos (Figma US03)
  def new
    @usuario = current_user
    @carteira = @usuario&.carteira || @usuario&.create_carteira(saldo_centavos: 0)
    @saldo_refeicoes = (@carteira&.saldo_centavos || 0) / TARIFA_UNITARIA_CENTAVOS
    @tarifa_unitária = TARIFA_UNITARIA_CENTAVOS / 100.0

    # Define a quantidade inicial (padrao: 5 refeicoes) ou recebe via parametro
    @quantidade = (params[:quantidade_refeicoes] || params[:pacote] || 5).to_i
    @quantidade = 5 if @quantidade <= 0
    @total_formatado = sprintf("%.2f", (@quantidade * TARIFA_UNITARIA_CENTAVOS) / 100.0).tr(".", ",")
    @novo_saldo_refs = @saldo_refeicoes + @quantidade

    @recarga = Recarga.new
  end

  # POST /recargas
  # Processa a solicitacao de compra de creditos com validacoes de negocio
  def create
    @usuario = current_user
    @carteira = @usuario.carteira
    @tarifa_unitária = TARIFA_UNITARIA_CENTAVOS / 100.0

    metodo = params[:metodo_pagamento]
    quantidade_raw = params[:quantidade_refeicoes]

    # 1. Validacao de presenca do metodo de pagamento
    if metodo.blank?
      flash.now[:alert] = "Selecione uma forma de pagamento"
      preparar_dados_view
      return render :new, status: :unprocessable_entity
    end

    # 2. Validacao de formato numerico (aceita inteiros positivos ou negativos)
    unless quantidade_valida?(quantidade_raw)
      flash.now[:alert] = "Informe uma quantidade numérica válida"
      preparar_dados_view
      return render :new, status: :unprocessable_entity
    end

    quantidade = quantidade_raw.to_i

    # 3. Validacao dos limites de negocio (minimo 1, maximo 100 refeicoes)
    if quantidade < 1
      flash.now[:alert] = "A quantidade mínima é de 1 refeição"
      preparar_dados_view
      return render :new, status: :unprocessable_entity
    elsif quantidade > 100
      flash.now[:alert] = "A quantidade máxima é de 100 refeições"
      preparar_dados_view
      return render :new, status: :unprocessable_entity
    end

    valor_total_centavos = quantidade * TARIFA_UNITARIA_CENTAVOS

    # 4. Direcionamento do fluxo de acordo com a forma de pagamento escolhida
    if metodo == "Cartão de Crédito"
      processar_cartao(quantidade, valor_total_centavos)
    else
      processar_pix(quantidade, valor_total_centavos)
    end
  end

  # GET /recargas/:id
  # Exibe os detalhes do PIX gerado (QR Code e chave Copia-e-Cola)
  def show
    @usuario = current_user
    @carteira = @usuario.carteira
  end

  # POST /recargas/:id/confirmar
  # Acao que simula a liquidacao bancaria do PIX (aprovado ou expirado)
  def confirmar
    if params[:expirado] == "true"
      # Cenário triste: prazo expirou sem pagamento
      @recarga.update(status: "cancelada")
      flash[:alert] = "Pagamento não confirmado"
      redirect_to new_recarga_path
    else
      # Cenário feliz: transacao atomica garantindo integridade ACID
      ActiveRecord::Base.transaction do
        @recarga.update!(status: "paga")
        @recarga.carteira.increment!(:saldo_centavos, @recarga.valor_centavos)
      end
      flash[:notice] = "Recarga realizada com sucesso"
      redirect_to new_recarga_path
    end
  end

  private

  # Garante que apenas estudantes autenticados acessem a funcionalidade
  def autenticar_usuario!
    unless logged_in?
      flash[:alert] = "Você precisa estar autenticado para acessar esta página."
      redirect_to "/login"
    end
  end

  def set_recarga
    @recarga = current_user.recargas.find(params[:id])
  end

  # Regex que verifica se a string informada representa um numero inteiro
  def quantidade_valida?(raw)
    return false if raw.blank?
    raw.to_s.strip.match?(/\A-?\d+\z/)
  end

  # Reconstroi o estado visual para renderizar a view caso ocorram erros de validacao
  def preparar_dados_view
    @saldo_refeicoes = (@carteira&.saldo_centavos || 0) / TARIFA_UNITARIA_CENTAVOS
    @quantidade = 5
    @total_formatado = "22,50"
    @novo_saldo_refs = @saldo_refeicoes + 5
    @recarga = Recarga.new
  end

  # Processa o pagamento via cartao simulando cenarios de aprovacao e recusa
  def processar_cartao(quantidade, valor_centavos)
    cartao_status = params[:cartao_status] || "valido"

    if cartao_status == "vencido"
      flash.now[:alert] = "Cartão vencido"
      preparar_dados_view
      render :new, status: :unprocessable_entity
    elsif cartao_status == "recusado"
      flash.now[:alert] = "Pagamento recusado"
      preparar_dados_view
      render :new, status: :unprocessable_entity
    else
      # Cartao valido: transacao atomica creditando a carteira imediatamente
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
      flash[:notice] = "Recarga realizada com sucesso"
      redirect_to new_recarga_path
    end
  end

  # Cria o registro de recarga pendente com txid exclusivo e direciona para a tela do PIX
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
end
