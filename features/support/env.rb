# ==============================================================================
# Configuração de Ambiente do Cucumber (features/support/env.rb)
# ==============================================================================
# Este arquivo é executado antes da suíte de testes BDD (Cucumber).
# Ele inicializa o Rails no ambiente de teste, carrega as definições do Capybara
# e configura as estratégias de limpeza e rollback do banco de dados.
# ==============================================================================

require 'cucumber/rails'

# Impede que exceções da aplicação sejam tratadas por páginas de erro genéricas,
# permitindo que erros internos estourem diretamente no Cucumber para facilitar o debug.
ActionController::Base.allow_rescue = false

# ------------------------------------------------------------------------------
# Limpeza de Banco de Dados:
# O bloco abaixo do DatabaseCleaner foi comentado porque o projeto utiliza as
# transações nativas do ActiveRecord com SQLite3 (:transaction). Com isso,
# cada cenário roda dentro de uma transação isolada que sofre rollback automático
# ao final da execução, dispensando a dependência externa da gema 'database_cleaner'.
# ------------------------------------------------------------------------------
# begin
#   DatabaseCleaner.strategy = :transaction
# rescue NameError
#   raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
# end

# Estratégia de truncamento quando houver cenários que utilizam JavaScript/navegador real.
Cucumber::Rails::Database.javascript_strategy = :truncation
