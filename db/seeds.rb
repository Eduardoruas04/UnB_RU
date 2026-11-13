# db/seeds.rb - Carga Mestre Idempotente (Padrão UnB RU / RottenPotatoes)

puts "== Populando banco de dados com dados mestres de teste =="

# 1. Usuários
aluno_com_saldo = Usuario.find_or_create_by!(matricula: "221045999") do |u|
  u.nome = "Estudante com Saldo"
  u.email = "estudante@aluno.unb.br"
  u.password = "senha123"
  u.papel = "estudante"
  u.ativo = true
end

Carteira.find_or_create_by!(usuario: aluno_com_saldo) do |c|
  c.saldo_centavos = 1800 # R$ 18,00 (4 refeicoes)
end

aluno_sem_saldo = Usuario.find_or_create_by!(matricula: "221000000") do |u|
  u.nome = "Estudante sem Saldo"
  u.email = "sem_saldo@aluno.unb.br"
  u.password = "senha123"
  u.papel = "estudante"
  u.ativo = true
end

Carteira.find_or_create_by!(usuario: aluno_sem_saldo) do |c|
  c.saldo_centavos = 0
end

Carteira.find_or_create_by!(usuario: aluno_sem_saldo) do |c|
  c.saldo_centavos = 0
end

funcionario = Usuario.find_or_create_by!(matricula: "FUNC01") do |u|
  u.nome = "Operador de Catraca"
  u.email = "operador@unb.br"
  u.password = "senha123"
  u.papel = "funcionario"
  u.ativo = true
end

admin = Usuario.find_or_create_by!(matricula: "ADMIN01") do |u|
  u.nome = "Administrador RU"
  u.email = "admin@unb.br"
  u.password = "senha123"
  u.papel = "administrador"
  u.ativo = true
end

# 2. Restaurantes e Catracas
restaurante = Restaurante.find_or_create_by!(nome: "Restaurante Universitário - Darcy Ribeiro") do |r|
  r.campus = "Darcy Ribeiro"
  r.ativo = true
end

catraca1 = Catraca.find_or_create_by!(codigo_identificador: "CAT-01") do |c|
  c.restaurante = restaurante
  c.status = "ativa"
end

catraca2 = Catraca.find_or_create_by!(codigo_identificador: "CAT-02") do |c|
  c.restaurante = restaurante
  c.status = "manutencao"
end

# 3. Turnos
turno_almoco = Turno.find_or_create_by!(nome: "Almoço") do |t|
  t.horario_inicio = "11:00"
  t.horario_fim = "14:00"
  t.valor_refeicao_centavos = 450
end

turno_jantar = Turno.find_or_create_by!(nome: "Jantar") do |t|
  t.horario_inicio = "17:30"
  t.horario_fim = "20:00"
  t.valor_refeicao_centavos = 450
end

Turno.find_or_create_by!(nome: "Café da Manhã") do |t|
  t.horario_inicio = "07:00"
  t.horario_fim = "09:00"
  t.valor_refeicao_centavos = 450
end

# 4. Cardápio de Hoje
cardapio = Cardapio.find_or_create_by!(restaurante: restaurante, turno: turno_almoco, data_refeicao: Date.current)

itens = [
  { categoria: "prato_principal_padrao", descricao: "Strogonoff de Frango" },
  { categoria: "prato_principal_ovolactovegetariano", descricao: "Quiche de Espinafre e Ricota" },
  { categoria: "prato_principal_vegetariano_estrito", descricao: "Ensopado de Grão-de-Bico com Legumes" },
  { categoria: "guarnicao", descricao: "Arroz Branco e Feijão Carioca" },
  { categoria: "salada", descricao: "Salada Mista de Folhas e Tomate" },
  { categoria: "sobremesa", descricao: "Maçã / Laranja" }
]

itens.each do |item|
  ItemCardapio.find_or_create_by!(cardapio: cardapio, categoria: item[:categoria]) do |i|
    i.descricao = item[:descricao]
  end
end

# 5. Histórico de Lançamentos de Exemplo (Issue #11 / Figma US04)
# Popula acessos e recargas para o 'Estudante com Saldo' poder testar o extrato e exportação em PDF
carteira_aluno = aluno_com_saldo.carteira

if aluno_com_saldo.recargas.empty?
  aluno_com_saldo.recargas.create!(
    carteira: carteira_aluno,
    quantidade_refeicoes: 10,
    valor_centavos: 4500,
    status: "paga",
    metodo_pagamento: "PIX Instantâneo",
    created_at: 14.days.ago
  )
  aluno_com_saldo.recargas.create!(
    carteira: carteira_aluno,
    quantidade_refeicoes: 5,
    valor_centavos: 2250,
    status: "paga",
    metodo_pagamento: "Cartão de Crédito",
    created_at: 4.days.ago
  )
end

if aluno_com_saldo.acessos.empty?
  # Almoços recentes com QR Code App
  8.times do |i|
    aluno_com_saldo.acessos.create!(
      catraca: catraca1,
      turno: turno_almoco,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: "QR Code App",
      data_hora: (i + 1).days.ago.change(hour: 12, min: 20)
    )
  end

  # Jantares recentes com Carteirinha e QR Code
  5.times do |i|
    aluno_com_saldo.acessos.create!(
      catraca: catraca1,
      turno: turno_jantar,
      valor_pago_centavos: 450,
      autorizado: true,
      forma_acesso: i.even? ? "QR Code App" : "Carteirinha Física",
      data_hora: (i + 2).days.ago.change(hour: 18, min: 40)
    )
  end
end

puts "== Carga mestre finalizada com sucesso! =="
