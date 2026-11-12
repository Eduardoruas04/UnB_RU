# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_223631) do
  create_table "acessos", force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.integer "catraca_id", null: false
    t.integer "turno_id", null: false
    t.integer "valor_pago_centavos"
    t.boolean "autorizado"
    t.string "motivo_recusa"
    t.datetime "data_hora"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "forma_acesso", default: "QR Code App"
    t.index ["catraca_id"], name: "index_acessos_on_catraca_id"
    t.index ["turno_id"], name: "index_acessos_on_turno_id"
    t.index ["usuario_id"], name: "index_acessos_on_usuario_id"
  end

  create_table "avaliacoes", force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.integer "acesso_id", null: false
    t.integer "nota"
    t.text "comentario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acesso_id"], name: "index_avaliacoes_on_acesso_id"
    t.index ["usuario_id"], name: "index_avaliacoes_on_usuario_id"
  end

  create_table "cardapios", force: :cascade do |t|
    t.integer "restaurante_id", null: false
    t.integer "turno_id", null: false
    t.date "data_refeicao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurante_id"], name: "index_cardapios_on_restaurante_id"
    t.index ["turno_id"], name: "index_cardapios_on_turno_id"
  end

  create_table "carteiras", force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.integer "saldo_centavos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_carteiras_on_usuario_id"
  end

  create_table "catracas", force: :cascade do |t|
    t.integer "restaurante_id", null: false
    t.string "codigo_identificador"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurante_id"], name: "index_catracas_on_restaurante_id"
  end

  create_table "inscricoes_fastpass", force: :cascade do |t|
    t.integer "sorteio_fastpass_id", null: false
    t.integer "usuario_id", null: false
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sorteio_fastpass_id"], name: "index_inscricoes_fastpass_on_sorteio_fastpass_id"
    t.index ["usuario_id"], name: "index_inscricoes_fastpass_on_usuario_id"
  end

  create_table "itens_cardapio", force: :cascade do |t|
    t.integer "cardapio_id", null: false
    t.string "categoria"
    t.string "descricao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cardapio_id"], name: "index_itens_cardapio_on_cardapio_id"
  end

  create_table "notificacoes", force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.integer "sorteio_fastpass_id", null: false
    t.string "titulo"
    t.text "mensagem"
    t.boolean "lida"
    t.string "tipo"
    t.string "status_envio"
    t.datetime "enviado_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sorteio_fastpass_id"], name: "index_notificacoes_on_sorteio_fastpass_id"
    t.index ["usuario_id"], name: "index_notificacoes_on_usuario_id"
  end

  create_table "recargas", force: :cascade do |t|
    t.integer "usuario_id", null: false
    t.integer "carteira_id", null: false
    t.integer "quantidade_refeicoes"
    t.integer "valor_centavos"
    t.string "status"
    t.string "metodo_pagamento"
    t.string "txid_pix"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["carteira_id"], name: "index_recargas_on_carteira_id"
    t.index ["usuario_id"], name: "index_recargas_on_usuario_id"
  end

  create_table "restaurantes", force: :cascade do |t|
    t.string "nome"
    t.string "campus"
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sorteios_fastpass", force: :cascade do |t|
    t.integer "turno_id", null: false
    t.date "data_sorteio"
    t.string "status"
    t.integer "vagas_disponiveis"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["turno_id"], name: "index_sorteios_fastpass_on_turno_id"
  end

  create_table "turnos", force: :cascade do |t|
    t.string "nome"
    t.time "horario_inicio"
    t.time "horario_fim"
    t.integer "valor_refeicao_centavos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "matricula"
    t.string "nome"
    t.string "email"
    t.string "password_digest"
    t.string "papel"
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "acessos", "catracas"
  add_foreign_key "acessos", "turnos"
  add_foreign_key "acessos", "usuarios"
  add_foreign_key "avaliacoes", "acessos"
  add_foreign_key "avaliacoes", "usuarios"
  add_foreign_key "cardapios", "restaurantes"
  add_foreign_key "cardapios", "turnos"
  add_foreign_key "carteiras", "usuarios"
  add_foreign_key "catracas", "restaurantes"
  add_foreign_key "inscricoes_fastpass", "sorteios_fastpass"
  add_foreign_key "inscricoes_fastpass", "usuarios"
  add_foreign_key "itens_cardapio", "cardapios"
  add_foreign_key "notificacoes", "sorteios_fastpass"
  add_foreign_key "notificacoes", "usuarios"
  add_foreign_key "recargas", "carteiras"
  add_foreign_key "recargas", "usuarios"
  add_foreign_key "sorteios_fastpass", "turnos"
end
