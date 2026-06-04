# rolld20-api

API Rails para uma plataforma de RPG de mesa assistida por IA. O **Claude** atua como Mestre (GM), narrando a história, resolvendo mecânicas de jogo e registrando memórias da campanha. O lore do mundo é indexado com embeddings vetoriais para que o GM sempre responda dentro do contexto correto.

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Framework | Ruby on Rails 7.2 (API-only) |
| Linguagem | Ruby 3.3.0 |
| Banco | PostgreSQL + extensão `pgvector` |
| Auth | Devise + JWT (`devise-jwt`) |
| IA — Narrativa | Claude (`claude-sonnet-4-6`) via Anthropic API |
| IA — Embeddings | OpenAI `text-embedding-ada-002` (1536 dims) |
| Busca semântica | `neighbor` gem (pgvector cosine similarity) |
| HTTP client | Faraday |

---

## Requisitos

- Ruby 3.3.0
- PostgreSQL 15+ com extensão `vector` (`pgvector`)
- Chaves de API: Anthropic e OpenAI

---

## Instalação

```bash
git clone git@github.com:GustavoRaposo/rolld20-api.git
cd rolld20-api
bundle install
```

Crie o arquivo `.env` na raiz:

```env
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...

DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=
```

Configure o banco e rode as migrations:

```bash
rails db:create db:migrate
```

Inicie o servidor:

```bash
rails server
```

---

## Docker

```bash
docker build -t rolld20-api .
docker run -d -p 3000:3000 \
  -e RAILS_MASTER_KEY=<master.key> \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -e OPENAI_API_KEY=sk-... \
  -e DB_HOST=host.docker.internal \
  -e DB_USERNAME=postgres \
  -e DB_PASSWORD=secret \
  rolld20-api
```

---

## Autenticação

Todas as rotas (exceto `/up`) requerem autenticação JWT via header:

```
Authorization: Bearer <token>
```

O token é retornado no header `Authorization` da resposta de login.

### Endpoints de auth

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/api/v1/auth/register` | Cadastro |
| `POST` | `/api/v1/auth/login` | Login — retorna JWT no header |
| `DELETE` | `/api/v1/auth/logout` | Logout (revoga o token) |
| `GET` | `/api/v1/auth/me` | Dados do usuário autenticado |

**Cadastro:**
```json
POST /api/v1/auth/register
{ "user": { "email": "player@example.com", "password": "senha123" } }
```

---

## Fluxo de Jogo

```
1. GM cria campanha
2. GM configura lore do mundo (opcional, mas melhora a narrativa)
3. Jogadores criam personagens na campanha
4. GM inicia a campanha
5. Jogadores submetem ações → Claude narra + processa eventos
6. XP é concedido → level up automático quando threshold atingido
7. GM gera recap de sessão quando necessário
```

---

## Rotas da API

### Campanhas

| Método | Rota | Quem pode | Descrição |
|--------|------|-----------|-----------|
| `GET` | `/api/v1/campaigns` | Todos | Lista campanhas próprias + as que participa |
| `POST` | `/api/v1/campaigns` | Todos | Cria campanha |
| `GET` | `/api/v1/campaigns/:id` | Owner ou participante | Detalhes + personagens |
| `POST` | `/api/v1/campaigns/:id/start` | Owner | Muda status `setup → active` |
| `POST` | `/api/v1/campaigns/:id/archive` | Owner | Arquiva a campanha |
| `GET` | `/api/v1/campaigns/:id/recap` | Owner ou participante | Resumo narrativo da sessão (Claude) |

**Criar campanha:**
```json
POST /api/v1/campaigns
{ "campaign": { "name": "A Queda de Valdris" } }
```

**Recap com filtro de turno:**
```
GET /api/v1/campaigns/:id/recap?since_turn=10
```

---

### Personagens

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/api/v1/campaigns/:campaign_id/characters` | Cria personagem (apenas em campanhas `setup`) |
| `GET` | `/api/v1/characters/:id` | Detalhes do personagem |
| `GET` | `/api/v1/characters/:id/level_up` | Status de level up |
| `POST` | `/api/v1/characters/:id/level_up` | Executa o level up |
| `POST` | `/api/v1/characters/:id/roll_attributes` | Rola atributos (4d6 drop lowest) |

**Classes disponíveis:** `warrior`, `mage`, `rogue`

**Criar personagem:**
```json
POST /api/v1/campaigns/:campaign_id/characters
{ "character": { "name": "Aelindra", "character_class": "mage" } }
```

**Roll attributes (resposta):**
```json
{
  "attributes": {
    "strength": 14, "dexterity": 11, "constitution": 13,
    "intelligence": 16, "wisdom": 12, "charisma": 9
  }
}
```

**Sistema de XP** — fórmula: `50 × n × (n-1)` para subir ao nível `n`:

| Nível | XP necessário |
|-------|--------------|
| 2 | 100 |
| 3 | 300 |
| 4 | 600 |
| 5 | 1000 |
| 10 (máx) | 4500 |

---

### Turnos

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/v1/campaigns/:campaign_id/turns` | Lista turnos (paginado, 50/página) |
| `POST` | `/api/v1/campaigns/:campaign_id/turns` | Submete ação → Claude narra |

**Submeter ação:**
```json
POST /api/v1/campaigns/:campaign_id/turns
{ "turn": { "player_action": "Examino as ruínas em busca de uma entrada secreta." } }
```

**Resposta:**
```json
{
  "id": 42,
  "turn_number": 7,
  "player_action": "Examino as ruínas em busca de uma entrada secreta.",
  "gm_narrative": "Seus dedos percorrem as pedras antigas enquanto...",
  "mechanic_result": {
    "roll": 17, "check": "perception", "difficulty": 14, "success": true, "modifier": 2
  },
  "game_events": [
    { "type": "xp_gain", "amount": 30 },
    { "type": "location_discovered", "name": "Câmara Subterrânea de Valdris", "description": "Uma câmara selada por séculos..." }
  ],
  "character_id": 1,
  "created_at": "2026-06-04T22:00:00Z"
}
```

**Tipos de `game_events` gerados pelo GM:**

| Tipo | Efeito automático |
|------|------------------|
| `xp_gain` | Adiciona XP; ativa `level_up_pending` se threshold atingido |
| `npc_met` | Cria `CampaignMemory` tipo `npc` (importância 2) |
| `quest_started` | Cria `CampaignMemory` tipo `quest` (importância 3) |
| `quest_completed` | Cria `CampaignMemory` tipo `quest` (importância 3) |
| `location_discovered` | Cria `CampaignMemory` tipo `location` (importância 2) |
| `item_found` | Cria `CampaignMemory` tipo `event` (importância 1) |

**Paginação:** `GET /api/v1/campaigns/:id/turns?page=2`

---

### Mundo / Lore

| Método | Rota | Quem pode | Descrição |
|--------|------|-----------|-----------|
| `GET` | `/api/v1/campaigns/:campaign_id/world` | Owner ou participante | Status do mundo |
| `POST` | `/api/v1/campaigns/:campaign_id/world` | Owner | Ingere lore (chunking + embeddings) |
| `GET` | `/api/v1/campaigns/:campaign_id/world/npcs` | Owner ou participante | Lista NPCs |
| `POST` | `/api/v1/campaigns/:campaign_id/world/npcs` | Owner | Cria NPC manualmente |

**Ingerir lore:**
```json
POST /api/v1/campaigns/:campaign_id/world
{
  "world": {
    "lore": "O Reino de Valdris foi fundado há 800 anos pelo herói Aldric...\n\nAs ruínas ao norte guardam segredos da antiga guerra dos deuses..."
  }
}
```

```json
{
  "campaign_id": 1,
  "world_configured": true,
  "lore_chunks": 12,
  "chunks_added": 12,
  "chunks_total": 12
}
```

O texto é dividido em chunks de até 1.200 caracteres. Cada chunk recebe um embedding via OpenAI e é armazenado com pgvector. A cada turno, os 3 chunks mais relevantes para a ação do jogador são injetados no contexto do GM automaticamente via busca por similaridade coseno.

O endpoint é idempotente: chunks já existentes (mesmo SHA256) são ignorados.

---

### Memórias da Campanha

| Método | Rota | Quem pode | Descrição |
|--------|------|-----------|-----------|
| `GET` | `/api/v1/campaigns/:campaign_id/memories` | Owner ou participante | Lista memórias (paginado) |
| `PATCH` | `/api/v1/campaigns/:campaign_id/memories/:id` | Owner | Edita memória |
| `DELETE` | `/api/v1/campaigns/:campaign_id/memories/:id` | Owner | Remove memória |

**Tipos de memória:** `event`, `npc`, `location`, `quest`, `consequence`

**Importância:** `1` (baixa) · `2` (média) · `3` (permanente — sempre presente no contexto do GM)

**Filtrar por tipo:**
```
GET /api/v1/campaigns/:campaign_id/memories?type=npc&page=1
```

**Editar importância:**
```json
PATCH /api/v1/campaigns/:campaign_id/memories/:id
{ "memory": { "importance": 3, "summary": "Zara é uma aliada crucial — conhece o paradeiro do artefato." } }
```

---

### Admin

Requer role `admin`. Retorna `403` para outros usuários.

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/api/v1/admin/users` | Lista todos os usuários |
| `PATCH` | `/api/v1/admin/users/:id` | Altera role do usuário |
| `GET` | `/api/v1/admin/campaigns` | Lista todas as campanhas |
| `DELETE` | `/api/v1/admin/campaigns/:id` | Remove campanha (cascade) |

**Promover usuário:**
```json
PATCH /api/v1/admin/users/:id
{ "user": { "role": "admin" } }
```

> Um admin não pode alterar o próprio role.

---

## Arquitetura dos Serviços

```
app/services/
├── claude_client.rb         # Wrapper Faraday → Anthropic API
├── embedding_client.rb      # Wrapper Faraday → OpenAI Embeddings
├── gm_narrative_service.rb  # Monta contexto + chama Claude + parseia JSON
├── world_lore_ingestor.rb   # Chunking + embeddings + upsert WorldLoreEmbedding
├── turn_event_processor.rb  # Processa game_events (XP, CampaignMemory)
└── session_recap_service.rb # Resumo narrativo de sessão via Claude
```

### Contexto do GM por turno

A cada `POST /turns`, o `GmNarrativeService` monta o seguinte contexto antes de chamar o Claude:

1. **Dados do personagem** — nome, classe, nível, XP
2. **Últimos 10 turnos** — ações do jogador e narrativas anteriores
3. **8 memórias mais importantes** — ordenadas por importância (permanentes primeiro)
4. **3 chunks de lore mais relevantes** — busca por similaridade coseno com a ação do jogador (apenas se `world_configured = true`)
5. **Ação do jogador**

---

## Autorização

| Scope | Inclui | Usado em |
|-------|--------|----------|
| `Campaign.owned_by(user)` | Campanhas onde é owner | `start`, `archive`, `world#create`, `npcs#create` |
| `Campaign.accessible_by(user)` | owned + campanhas com personagem | `show`, `turns`, `memories`, `recap` |
| Admin bypass | Role `admin` acessa qualquer campanha | Todos os endpoints |

Jogadores entram em campanhas criando um personagem (`POST /campaigns/:id/characters`). Apenas campanhas com status `setup` aceitam novos personagens.

---

## Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|----------|------------|-----------|
| `ANTHROPIC_API_KEY` | Sim | Chave da API Anthropic (Claude) |
| `OPENAI_API_KEY` | Condicional* | Chave da API OpenAI (embeddings) |
| `DB_HOST` | Não (default: `localhost`) | Host do PostgreSQL |
| `DB_PORT` | Não (default: `5432`) | Porta do PostgreSQL |
| `DB_USERNAME` | Não (default: `$USER`) | Usuário do banco |
| `DB_PASSWORD` | Não | Senha do banco |
| `RAILS_MASTER_KEY` | Sim (produção) | Chave do `credentials.yml.enc` |
| `RAILS_MAX_THREADS` | Não (default: `5`) | Pool de conexões do banco |

> \* `OPENAI_API_KEY` só é necessária quando `world_configured = true`. Sem ela, o sistema funciona normalmente — o GM não terá acesso ao lore via busca semântica, mas a narrativa continua funcionando.
