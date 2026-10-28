-- CRM REC Lab · cole tudo no SQL Editor do projeto "anotou teste" e clique em Run
create schema if not exists crm_priv;
revoke all on schema crm_priv from public, anon, authenticated;
create table if not exists crm_priv.config (id int primary key default 1, senha_hash text not null);
-- Antes de rodar: troque TROQUE_A_SENHA pela senha da equipe (nunca suba a senha real para o GitHub)
insert into crm_priv.config (id, senha_hash) values (1, encode(sha256(convert_to('TROQUE_A_SENHA','UTF8')),'hex'))
on conflict (id) do update set senha_hash = excluded.senha_hash;

create or replace function public.crm_team_ok() returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce(
    encode(sha256(convert_to(coalesce(current_setting('request.headers', true)::json->>'x-team-key',''),'UTF8')),'hex')
      = (select senha_hash from crm_priv.config where id = 1), false)
$$;
grant execute on function public.crm_team_ok() to anon, authenticated;

create table if not exists public.leads (
  id bigint generated always as identity primary key,
  restaurante text not null, endereco text, telefone text, horario text,
  instagram text, link_instagram text, origem_instagram text,
  bairro text, cidade text default 'Rio de Janeiro', nicho text, rodada text,
  data_pesquisa date default current_date,
  etapa text not null default 'novo' check (etapa in ('novo','a_contatar','contatado','negociacao','fechado','perdido')),
  prioridade text check (prioridade in ('alta','media','baixa')),
  responsavel text, observacoes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint leads_unico unique (restaurante, endereco)
);
create index if not exists leads_etapa_idx on public.leads (etapa);
create index if not exists leads_rodada_idx on public.leads (rodada);

create or replace function public.crm_set_updated_at() returns trigger
language plpgsql set search_path = '' as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists leads_updated_at on public.leads;
create trigger leads_updated_at before update on public.leads
for each row execute function public.crm_set_updated_at();

alter table public.leads enable row level security;
drop policy if exists "crm_equipe" on public.leads;
create policy "crm_equipe" on public.leads for all to anon
  using (public.crm_team_ok()) with check (public.crm_team_ok());
grant select, insert, update, delete on public.leads to anon;

insert into public.leads (restaurante, endereco, telefone, horario, instagram, link_instagram, origem_instagram, bairro, rodada, data_pesquisa, etapa) values
('Santa Brasa Freguesia', 'Estr. do Pau-Ferro, 1156 - Freguesia, 22745-056', '(21) 97178-4127', 'Seg 11h–22h; Ter–Sáb 11h–00h; Dom 11h–22h', '@santabrasa.rio', 'https://instagram.com/santabrasa.rio', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Armazém Urbano', 'Estr. do Pau-Ferro, 1070 - Freguesia, 22743-052', '(21) 2425-5522', 'Seg–Dom 06h–22h', '@armazemurbanorio', 'https://instagram.com/armazemurbanorio', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Baixo Araguaia', 'R. Araguaia, 1709 - Freguesia, 22745-271', '(21) 97696-8984', 'Seg–Sáb 12h–00h; Dom 12h–20h', '@baixoaraguaiafreguesia', 'https://instagram.com/baixoaraguaiafreguesia', 'Conferir (há perfis parecidos)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Restaurante Àdorê', 'Estr. de Jacarepaguá, 7544 - Freguesia, 22755-158', '(21) 2135-5772', 'Seg–Dom 11h30–23h30', '@restaurante.adore', 'https://instagram.com/restaurante.adore', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Restaurante Rancho Verde', 'Av. Geremário Dantas, 1345 - Freguesia, 22760-400', '(21) 98756-3149', 'Seg 09h–23h40; Ter–Qui 11h10–23h40; Sex 11h10–00h40; Sáb 11h10–00h35; Dom (ver Maps)', '@restauranteranchoverde', 'https://instagram.com/restauranteranchoverde', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Baurú Restaurante', 'Estr. dos Três Rios, 445 - Freguesia, 22745-004', '(21) 99122-8087', 'Seg–Qui 11h–23h; Sex–Sáb 11h–23h30; Dom 11h30–23h', '@bauruoficiall', 'https://instagram.com/bauruoficiall', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Dos Sertões Freguesia', 'Estr. de Jacarepaguá, 7636 - Freguesia, 22755-155', '(21) 3251-7636', 'Seg–Sáb 11h–23h; Dom 11h–22h', '@dossertoesrestaurante', 'https://instagram.com/dossertoesrestaurante', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Chopp Time Freguesia', 'Estr. do Bananal, 156 - Freguesia, 22745-012', '(21) 98731-2602', 'Seg–Ter 11h–16h; Qua–Qui 11h–23h; Sex–Sáb 11h–00h; Dom 11h–23h', '@chopptimefreguesia', 'https://instagram.com/chopptimefreguesia', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('299 Moto Bar', 'R. Araguaia, 1763, Lj F - Freguesia, 22745-241', '(21) 3596-5295', 'Seg fechado; Ter–Qua 10h–22h; Qui 10h–23h; Sex–Sáb 10h–00h; Dom 10h–18h', '@299oficinamotobar', 'https://instagram.com/299oficinamotobar', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Santo Alimento', 'R. Zoroastro Pamplona, 143 - Freguesia, 22750-710', '(21) 99163-5244', 'Seg–Dom 09h30–17h', '@santoalimentorj', 'https://instagram.com/santoalimentorj', 'Conferir (há perfis parecidos)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Adega e Restaurante Sabor e Casa', 'Estr. do Bananal, 400 - Freguesia, 22750-013', '(21) 3392-1703', 'Seg fechado; Ter–Dom 07h–22h', '@saborecasa', 'https://instagram.com/saborecasa', 'Conferir (não confirmado)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Prato Carioca - Freguesia', 'Praça Professora Camisão, 18 - Freguesia, 22750-210', '(21) 3986-5879', 'Seg–Sáb 11h–16h; Dom fechado', '@pratocarioca_', 'https://instagram.com/pratocarioca_', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Formigueiro Brasa e Fogão', 'R. Araguaia, 603 - Freguesia, 22745-270', '(21) 3226-7557', 'Seg–Sáb 11h–19h; Dom 11h–18h', '@formigueirobrasaefogao', 'https://instagram.com/formigueirobrasaefogao', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Capitanea Bar e Restaurante', 'R. Araguaia, 1580 - Freguesia, 22745-271', '(21) 96776-0937', 'Não informado no Maps', '@capitanearestaurante', 'https://instagram.com/capitanearestaurante', 'Confirmado (Google Maps)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Lilly Café', 'R. Araguaia, 1763, Lj G - Freguesia, 22745-271', '(21) 99805-7859', 'Seg–Sex 09h–19h; Sáb 09h–14h; Dom fechado', '@lilly__cafe', 'https://instagram.com/lilly__cafe', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Veneto Gourmet', 'Estr. de Jacarepaguá, 7726 - Freguesia, 22755-041', '(21) 2447-8434', 'Seg–Sáb 11h–16h; Dom fechado', '@venetogourmet', 'https://instagram.com/venetogourmet', 'Conferir (há perfis parecidos)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Restaurante Vista Alegre', 'Estr. dos Três Rios, 139 - Freguesia, 22755-001', '(21) 3392-9037', 'Seg 11h30–16h; Ter–Dom 11h30–18h', '@restaurantevistaalegre', 'https://instagram.com/restaurantevistaalegre', 'Conferir (há perfis parecidos)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Porto do Sabor - Freguesia', 'Estr. dos Três Rios, 1097, Lj F - Freguesia, 22745-004', '(21) 2148-0205', 'Seg–Sáb 09h–22h; Dom 11h–20h', '@portodosabor_oficial', 'https://instagram.com/portodosabor_oficial', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('TemKilo', 'Estr. de Jacarepaguá, 7725 - Freguesia, 22755-155', '(21) 2436-1705', 'Seg–Sáb 11h30–23h; Dom 11h30–18h', '@temkilo_', 'https://instagram.com/temkilo_', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Rios Gourmet Freguesia', 'Estr. dos Três Rios, 243 - Freguesia, 22745-004', '(21) 3795-1914', 'Seg–Dom 11h–16h', '@riosgourmetfreguesia', 'https://instagram.com/riosgourmetfreguesia', 'Confirmado (Google Maps)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Bom Paladar Bar e Restaurante', 'R. Quintanilha, 656 - Freguesia, 22763-007', '(21) 98397-9052', 'Seg–Sáb 09h–22h; Dom 09h–21h', '@bompaladarrf', 'https://instagram.com/bompaladarrf', 'Conferir (não confirmado)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Sunomono Jacarepaguá', 'Av. Geremário Dantas, 1400, Lj 115/116 SS - Freguesia, 22760-401', '(21) 98206-0309', 'Seg–Dom 11h–23h30', '@sunomonodelivery', 'https://instagram.com/sunomonodelivery', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Olga Bistrô', 'Estr. de Jacarepaguá, 7187, Lj B - Freguesia, 22755-155', '(21) 98072-6305', 'Seg–Sáb 09h–17h; Dom fechado', '@olgabistrobr', 'https://instagram.com/olgabistrobr', 'Conferir (há perfis parecidos)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Restaurante Tio Frank', 'R. São Ricardo, 25 - Anil, 22750-360', '(21) 2447-8222', 'Seg 11h–16h; Ter–Sex 11h–00h; Sáb 11h–01h; Dom 11h–00h', '@restaurante.tiofrank', 'https://instagram.com/restaurante.tiofrank', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Buteco Seu Rufino - Freguesia', 'R. Araguaia, 985 - Freguesia, 22745-270', '(21) 99901-0104', 'Seg–Qui 11h–23h; Sex–Sáb 11h–00h; Dom 11h–23h', '@butecoseurufino', 'https://instagram.com/butecoseurufino', 'Busca Google (perfil da rede)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Galo Zé - Freguesia', 'R. Araguaia, 1763 - Freguesia, 22745-271', '(21) 97890-4292', 'Seg fechado; Ter–Sex 18h–23h; Sáb 12h–23h; Dom 18h–23h', '@galozefreguesia', 'https://instagram.com/galozefreguesia', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Comida de Mãe - Freguesia', 'Quality Shopping, Av. Geremário Dantas, 1400, Lj 134 - Freguesia', '(21) 3251-4906', 'Seg–Qui 11h–23h; Sex–Sáb 11h–00h; Dom 11h–21h', '@comidademae_emcasa', 'https://instagram.com/comidademae_emcasa', 'Busca Google (perfil da rede)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Hortelã Sucos', 'Estr. dos Três Rios, 200, Bl 1 Lj H - Freguesia, 22755-002', '(21) 2443-8520', 'Seg–Sex 07h–20h; Sáb 07h–18h; Dom fechado', '@hortelasucos', 'https://instagram.com/hortelasucos', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Koi Sushi Lounge', 'Estr. do Bananal, 38 - Freguesia, 22745-012', '(21) 3647-9007', 'Não informado no Maps', '@koisushilounge', 'https://instagram.com/koisushilounge', 'Busca Google', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Camarada Camarão Jacarepaguá', 'Estr. de Jacarepaguá, 6069 - Anil, 22753-045', '(21) 99635-0567', 'Seg–Qui 11h30–15h; Sex–Sáb 11h30–23h; Dom 12h–22h', '@camaradacamarao', 'https://instagram.com/camaradacamarao', 'Busca Google (perfil da rede)', 'Freguesia', 'Rodada 01 · Freguesia', '2026-10-01', 'novo'),
('Churrascaria Palace', 'R. Rodolfo Dantas, 16 - Copacabana, 22020-040', '(21) 2541-5898', 'Seg–Dom 12h–00h', '@churrascariapalace', 'https://instagram.com/churrascariapalace', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Bonde Boca Copacabana', 'R. Barata Ribeiro, 51 - Copacabana, 22011-001', '(21) 3268-9310', 'Seg–Dom 12h–23h', '@bondebocacp', 'https://instagram.com/bondebocacp', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante Famiglia', 'Rua Joaquim Nabuco, 14 - Copacabana, 22080-030', '(21) 97359-5006', 'Seg–Dom 12h–00h', null, null, 'Não encontrado', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Adega Pérola - (Copacabana)', 'Rua Siqueira Campos, 138 - Copacabana, 22031-010', '(21) 2255-9425', 'Seg–Sáb 12h–01h; Dom fechado', '@adegaperola', 'https://instagram.com/adegaperola', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante Mondego - (Copacabana)', 'R. Constante Ramos, 2936 - Copacabana, 22070-000', '(21) 2255-5160', 'Seg–Dom 09h–01h30', '@restaurantemondego', 'https://instagram.com/restaurantemondego', 'Conferir (há perfis parecidos)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante Guacamole Copacabana', 'R. Bolívar, 45 - Lj B - Copacabana, 22061-020', '(21) 3439-4397', 'Seg–Dom 12h–00h', null, null, 'Não encontrado', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Landuco | Copacabana', 'R. Barata Ribeiro, 344 - Copacabana, 22040-002', '(21) 97882-2151', 'Seg–Dom 11h–00h', '@landucocopacabana', 'https://instagram.com/landucocopacabana', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Na Brasa Columbia - Copacabana', 'Av. Atlântica, 3092 - Copacabana, 22070-000', '(21) 3586-2032', 'Seg–Sáb 11h–00h; Dom 11h–22h', '@columbia_nabrasa', 'https://instagram.com/columbia_nabrasa', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Favo Bar e Restaurante Copacabana', 'Av. Nossa Sra. de Copacabana, 403 - Copacabana, 22020-002', null, 'Seg–Sex 11h–00h; Sáb 11h05–00h; Dom 11h–00h', '@favobar', 'https://instagram.com/favobar', 'Confirmado (Google Maps)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Alloro al Miramar', 'Av. Atlântica, 3668 - Copacabana, 22070-001', '(21) 2195-6213', 'Seg–Sex 12h–23h; Sáb–Dom 12h30–23h', '@alloroalmiramar', 'https://instagram.com/alloroalmiramar', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Barraca da Chiquita Copacabana', 'R. Santa Clara, 33 - Copacabana, 22031-011', '(21) 2548-9144', 'Seg 11h–23h20; Ter–Dom 11h–23h30', '@barracadachiquita_', 'https://instagram.com/barracadachiquita_', 'Confirmado (Google Maps)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Casa das Natas Copacabana', 'Av. Nossa Sra. de Copacabana, 995 - Copacabana, 22060-001', '(21) 3449-2750', 'Seg–Sáb 10h–22h; Dom 10h–18h', null, null, 'Não encontrado (só perfis de outras unidades)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Braseiro', 'R. Domingos Ferreira, 214 - Copacabana, 22050-012', '(21) 2547-9843', 'Seg–Dom 11h–23h', '@braseiro.copacabana', 'https://instagram.com/braseiro.copacabana', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Parada de Copa Restaurante', 'R. Barata Ribeiro, 450 - Copacabana, 22040-002', '(21) 3936-0450', 'Não informado no Maps', '@paradadecopa', 'https://instagram.com/paradadecopa', 'Confirmado (Google Maps)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante Copa Suítes', 'R. Barata Ribeiro, 222 - Copacabana, 22040-002', '(21) 99185-6181', 'Seg fechado; Ter–Qua 12h–20h; Qui 12h–22h; Sex–Dom 12h–20h', null, null, 'Não encontrado', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Basha Restaurante', 'Av. Nossa Sra. de Copacabana, 198 - Copacabana, 22050-002', '(21) 2244-5868', 'Seg–Sáb 10h–23h; Dom 10h–22h', '@restaurante.basha', 'https://instagram.com/restaurante.basha', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante La Maison', 'Av. Atlântica, 2634 - Copacabana, 22041-001', '(21) 2256-2581', 'Seg–Dom 11h–00h', null, null, 'Não encontrado', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Galeto&cia Restaurante', 'Av. Nossa Sra. de Copacabana, 462 - Lj C - Copacabana, 22020-001', '(21) 96710-7852', 'Não informado no Maps', '@galetoeciarj', 'https://instagram.com/galetoeciarj', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Bistrô Santa Satisfação - Copacabana', 'R. Santa Clara, 36 - C - Copacabana, 22041-012', '(21) 97241-3139', 'Não informado no Maps', '@santasatisfacao', 'https://instagram.com/santasatisfacao', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('La Trattoria', 'R. Fernando Mendes, 7 - Lj A - Copacabana, 22021-030', '(21) 2255-3319', 'Seg–Qui 11h–23h; Sex–Sáb 11h–00h; Dom 11h–23h', '@latrattoriario', 'https://instagram.com/latrattoriario', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Sertão de Copa', 'Rua Siqueira Campos, 12 - Lj B - Copacabana, 22031-070', '(21) 97590-7316', 'Seg–Dom 11h–23h', '@sertaodecopa', 'https://instagram.com/sertaodecopa', 'Confirmado (Google Maps)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Joaquina', 'Av. Atlântica, 974 - Lj A - Copacabana, 22010-100', '(21) 2275-8569', 'Seg–Qua 12h–00h; Qui–Sáb 12h–01h; Dom 12h–00h', '@joaquinabar', 'https://instagram.com/joaquinabar', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Deck Buffet', 'Av. Atlântica, 2316 - Copacabana, 22010-000', '(21) 97254-3727', 'Seg–Dom 11h–00h', '@restaurantedeck', 'https://instagram.com/restaurantedeck', 'Conferir (não confirmado)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Alfaia Restaurante', 'Rua Inhangá, 30 - Loja A - Copacabana, 22020-060', '(21) 3497-7672', 'Não informado no Maps', '@alfaiario', 'https://instagram.com/alfaiario', 'Conferir (há perfis parecidos)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Hera Bar e Botequim', 'Av. Atlântica, 3806 - Copacabana, 22070-001', '(21) 2523-1128', 'Seg–Dom 08h–00h', '@herabarebotequim', 'https://instagram.com/herabarebotequim', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante Príncipe de Mônaco - (Copacabana)', 'R. Miguel Lemos, 18 - Copacabana, 22071-001', '(21) 2521-0195', 'Seg–Dom 09h–02h', null, null, 'Não encontrado', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Pasta & Vino - Pastificio e Vineria', 'R. Francisco Sá, 35 - Copacabana, 22080-010', '(21) 3547-0300', 'Seg–Sáb 11h30–22h; Dom 11h30–18h', '@pastaevino_copacabana', 'https://instagram.com/pastaevino_copacabana', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Sindicato do Chopp - Copacabana', 'Av. Atlântica, 3806 - Copacabana, 22070-001', '(21) 2143-3237', 'Seg–Dom 09h–01h', '@sindicatodochopp', 'https://instagram.com/sindicatodochopp', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Carretão Lido Churrascaria', 'R. Ronald de Carvalho, 55 - lojas A e B - Copacabana, 22021-020', '(21) 2543-2666', 'Seg–Dom 11h30–23h', '@carretaolidochurrascaria', 'https://instagram.com/carretaolidochurrascaria', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Farro - Nossa Srª de Copacabana', 'Av. Nossa Sra. de Copacabana, 630 - Copacabana, 22050-001', '(21) 3593-7905', 'Seg–Sáb 07h–20h; Dom 08h–16h', '@farrorio', 'https://instagram.com/farrorio', 'Busca Google (perfil da rede)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Bar Pavão Azul', 'R. Hilário de Gouveia, 71 - Copacabana, 22040-002', '(21) 3449-9419', 'Seg–Dom 12h–00h', '@pavao_azul_convida', 'https://instagram.com/pavao_azul_convida', 'Conferir (não confirmado)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('O Caranguejo', 'R. Barata Ribeiro, 771 (esq. R. Xavier da Silveira) - Copacabana', '(21) 2235-1249', 'Seg–Dom 08h–00h', '@ocaranguejocopacabana', 'https://instagram.com/ocaranguejocopacabana', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Xodózin', 'R. Santa Clara, 33 - Lj B e C - Copacabana, 22041-011', '(21) 96902-2054', 'Seg–Dom 08h–00h', '@xodozinpraiaoficial', 'https://instagram.com/xodozinpraiaoficial', 'Confirmado (Google Maps)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Brasileiro de Copa', 'R. Santa Clara, 116 - loja B - Copacabana, 22041-012', '(21) 98063-9738', 'Seg–Dom 11h–00h', null, null, 'Não encontrado', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Quick Galetos - Copacabana', 'R. Duvivier, 28 A - Copacabana, 22020-020', '(21) 2541-2897', 'Não informado no Maps', '@quickgaletos', 'https://instagram.com/quickgaletos', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Restaurante e Bar Garota de Copacabana', 'Av. Atlântica, 3744 - Copacabana, 22070-001', '(21) 2521-4705', 'Seg–Dom 11h30–00h', '@restaurantesgarota', 'https://instagram.com/restaurantesgarota', 'Busca Google (perfil da rede)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Kinjo Culinária Nikkei - Copacabana', 'R. Duvivier, 21 - Copacabana, 22020-020', '(21) 2143-5059', 'Seg–Qui 12h–16h e 19h–23h; Sex 12h–16h e 19h–00h; Sáb 12h–00h', '@kinjonikkei.br', 'https://instagram.com/kinjonikkei.br', 'Confirmado (Google Maps)', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo'),
('Clássico de Copa Restaurante e Pub', 'R. Bolívar, 27 - Copacabana, 22061-020', '(21) 3495-8208', 'Seg–Dom 11h–00h', '@classicodecopa', 'https://instagram.com/classicodecopa', 'Busca Google', 'Copacabana', 'Rodada 02 · Copacabana', '2026-10-01', 'novo')
on conflict (restaurante, endereco) do nothing;
