# Issue #15 — Notificação de Sorteio FastPass

Notificação interna disponível em `/notificacoes`, acessível pelo link da Central de Testes após login de estudante. Cada estudante consulta apenas suas próprias notificações. Não há envio de e-mail, SMS ou push.

## Contrato com o resultado do sorteio

- `SorteioFastpass.status`: `realizado` quando os resultados estiverem completos.
- `InscricaoFastpass.status`: `sorteado` ou `nao_sorteado`; resultados pendentes não geram mensagens.
- `data_sorteio`: dia do turno ao qual o resultado se refere.
- O horário do FastPass é o início do turno, pois não existe campo específico na modelagem atual. Essa suposição deve ser validada com o grupo.
- O serviço consome resultados existentes; realizar o sorteio e cadastrar inscrições estão fora da Issue #15.

## Execução

Após atualizar a branch, execute `bundle install` e `bin/rails db:migrate`.

Em produção, `config/recurring.yml` agenda `NotificarFastpassJob` a cada minuto. O banco da fila deve estar preparado (`RAILS_ENV=production bin/rails db:prepare`) e o processo `bin/jobs` deve permanecer ativo junto ao servidor web.

Em desenvolvimento, execute `bin/rails fastpass:notificar` no minuto programado, ou configure um agendador local para executar essa tarefa a cada minuto. O servidor Rails sozinho não executa a tarefa periódica.

O horário é calculado em `America/Sao_Paulo`, uma hora antes do início do turno. O processamento aceita os segundos daquele minuto, sem enviar antes ou a partir do minuto seguinte. Se o worker estiver indisponível durante todo esse minuto, a notificação não será recuperada automaticamente, conforme a regra de não enviar atrasadas. A entrega significa persistir a mensagem na caixa interna do estudante; ela aparece ao acessar/recarregar a página.

A transação por sorteio e o índice único parcial em `notificacoes(usuario_id, sorteio_fastpass_id)` para `tipo = 'fastpass'` impedem duplicidades. A migração exige que registros FastPass anteriores não contenham duplicatas; não apaga registros existentes.

## Validação

```bash
bundle exec cucumber features/notificacao_de_sorteio.feature 'features/notificacao_de_sorteio(bonus).feature'
bundle exec rspec spec/services/notificar_resultado_fastpass_spec.rb spec/requests/notificacoes_spec.rb spec/jobs/notificar_fastpass_job_spec.rb
```

Cobre contemplados, não contemplados, antecedência, atraso, ausência de inscrição/resultado, repetição, restrição por perfil, isolamento por estudante e notificação na véspera de turno após meia-noite.

Implementação e testes elaborados com auxílio de Codex/OpenAI. Regras assumidas e código devem passar por revisão cruzada da equipe antes do merge.
