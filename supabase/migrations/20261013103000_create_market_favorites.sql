-- Watchlist pessoal de precos de mercado (feature Mercado).
--
-- So a relacao usuario<->carta -- favoritar nunca significa comprar/vender
-- nada, so marcar "quero acompanhar o preco desta carta depois". Vinculada
-- ao usuario (profiles), nao a uma Conta FC: quem acompanha preco e a
-- pessoa, nao um perfil de jogo especifico dela.
--
-- Sem coluna mutavel alem de created_at -- nao ha "update" de um favorito,
-- so existir ou nao. Por isso a PK composta em vez de um id proprio: a
-- unicidade (usuario, carta) e o unico invariante que importa, e ela ja
-- funciona como indice de lookup nos dois sentidos de join.

create table public.market_favorites (
    user_id uuid not null references public.profiles (id) on delete cascade,
    card_id uuid not null references public.fc_player_cards (id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, card_id)
);

comment on table public.market_favorites is
    'Watchlist pessoal de cartas para acompanhar preco de mercado -- favoritar nunca significa comprar/vender, so monitorar.';

-- Resolve "quem favoritou esta carta" -- nao usado pelo app hoje, mas e o
-- lado barato de manter (a PK ja cobre "favoritos de um usuario").
create index market_favorites_card_idx on public.market_favorites (card_id);

alter table public.market_favorites enable row level security;

create policy market_favorites_select_own
    on public.market_favorites
    for select
    to authenticated
    using ((select auth.uid()) = user_id);

create policy market_favorites_insert_own
    on public.market_favorites
    for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

create policy market_favorites_delete_own
    on public.market_favorites
    for delete
    to authenticated
    using ((select auth.uid()) = user_id);

revoke all on table public.market_favorites from anon;
grant select, insert, delete on table public.market_favorites to authenticated;
