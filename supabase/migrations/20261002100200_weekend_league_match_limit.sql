-- Weekend League tem 15 partidas. O record manual aceitava 150/0.
--
-- FQ046: record acima do limite da competicao.
--
-- A regra vive no banco, nao so no formulario: a RPC e o caminho de escrita
-- real, e uma validacao que so existe no cliente nao e validacao.
-- A constraint na tabela e a rede de seguranca -- os dados atuais ja
-- respeitam o limite (conferido antes de aplicar), entao ela entra valida.

create function public._weekend_league_max_matches()
returns integer
language sql
immutable
as $$ select 15 $$;

comment on function public._weekend_league_max_matches() is
    'Numero de partidas de uma Weekend League. Um lugar so, nunca 15 espalhado.';

alter table public.fc_account_weekend_league_progress
    add constraint fc_account_wl_progress_manual_limit
    check (
        manual_wins is null
        or manual_losses is null
        or manual_wins + manual_losses <= 15
    );

create or replace function public.set_weekend_league_manual_record(
    p_fc_account_id uuid,
    p_event_id uuid,
    p_wins integer,
    p_losses integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    if not exists (
        select 1 from public.user_fc_accounts
        where id = p_fc_account_id and user_id = v_user_id
    ) then
        raise exception 'fc account not found' using errcode = 'FQ025';
    end if;

    if p_wins is null or p_losses is null then
        delete from public.fc_account_weekend_league_progress
        where fc_account_id = p_fc_account_id and weekend_league_event_id = p_event_id;
        return;
    end if;

    if p_wins < 0 or p_losses < 0 then
        raise exception 'invalid record' using errcode = 'FQ024';
    end if;

    if p_wins + p_losses > public._weekend_league_max_matches() then
        raise exception 'record exceeds the weekend league match limit'
            using errcode = 'FQ046';
    end if;

    insert into public.fc_account_weekend_league_progress
        (fc_account_id, weekend_league_event_id, manual_wins, manual_losses)
    values (p_fc_account_id, p_event_id, p_wins, p_losses)
    on conflict (fc_account_id, weekend_league_event_id) do update
        set manual_wins = excluded.manual_wins,
            manual_losses = excluded.manual_losses,
            updated_at = now();
end;
$$;

comment on function public.set_weekend_league_manual_record(uuid, uuid, integer, integer) is
    'Record manual da Weekend League. Vitorias + derrotas nunca passam de 15 (FQ046).';
