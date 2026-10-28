# CRM REC Lab · Vendedor REC Lab

Kanban de leads de prospecção da REC Lab, ligado ao Supabase.

- **Acesso:** abra o link do GitHub Pages e entre com a senha da equipe.
- **Etapas:** Novo lead → A contatar → Contatado → Em negociação → Fechado / Perdido (arraste os cards).
- **Nova rodada:** cole o resultado do Google Maps Scraper ou da planilha; leads repetidos são ignorados.
- **Banco:** tabela `public.leads` no Supabase. O acesso é liberado pela senha via RLS (`crm_team_ok()`).

Trocar a senha (SQL Editor do Supabase):
```sql
update crm_priv.config set senha_hash = encode(sha256(convert_to('NOVA_SENHA','UTF8')),'hex') where id = 1;
```
