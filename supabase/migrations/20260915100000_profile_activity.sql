-- Timestamp de atividade recente. Nao e presenca de verdade (websocket
-- "estou aqui agora") -- e um heartbeat espacado que o cliente escreve no
-- foreground e em acoes relevantes, nunca a cada segundo. profiles ja tem
-- RLS de update-own (Etapa 1); nenhuma RPC nova e necessaria pra escrever,
-- so a coluna.
alter table public.profiles
    add column last_active_at timestamptz;

comment on column public.profiles.last_active_at is
    'Heartbeat espacado (cliente escreve, nunca a cada segundo). Base para RECENTLY_ACTIVE/OFFLINE, nunca presenca em tempo real.';

-- Suporta o filtro "quem esteve ativo nos ultimos N minutos" sem varrer a
-- tabela inteira quando o time crescer.
create index profiles_last_active_at_idx
    on public.profiles (last_active_at)
    where last_active_at is not null;
