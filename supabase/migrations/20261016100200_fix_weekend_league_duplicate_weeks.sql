-- Bug introduzido pela propria migration 20261013103600 (janela do
-- Champions sexta 18h -> segunda 4h): list_weekend_league_events chamava
-- ensure_weekend_league_events() com o default p_weeks_back=8, entao TODA
-- vez que alguem abria o seletor de semana, a funcao recalculava as 8
-- semanas passadas usando a NOVA formula de _weekend_league_week_start
-- (deslocada 18h). Como o unique index e em starts_at (timestamp exato),
-- e as semanas #1-#3 ja existiam com o starts_at ANTIGO (fronteira 00h,
-- preservado de proposito -- ja tinham partida e notificacao reais), a
-- recalculada nao bateu com "on conflict do nothing" e criou uma segunda
-- linha nova pra cada semana ja passada. E exatamente o que apareceu no
-- seletor como "Champions #3" duas vezes com a mesma data (rotulo so
-- mostra o dia, nao a hora -- por isso pareciam identicas).
--
-- Verificado antes de apagar: nenhuma das 3 linhas duplicadas tinha
-- qualquer referencia real (game_matches.weekend_league_event_id,
-- fc_account_weekend_league_progress.weekend_league_event_id) -- foram
-- criadas ha minutos, sem ninguem ter jogado contra elas. O
-- notifications_dispatched_at que ficou preenchido nelas tambem nao
-- corresponde a nenhuma notificacao real enviada:
-- _dispatch_finished_weekend_league_notifications so notifica Contas que
-- de fato jogaram aquele evento (mesma checagem de existencia), e nao
-- havia nenhuma -- o fan-out rodou vazio, so marcou o timestamp.
delete from public.weekend_league_events
where id in (
    '76eb1762-5e2d-4666-b2dd-de78c93b656b', -- duplicata de #1
    '4923dbbe-2379-40f0-b478-3552dfd4a72b', -- duplicata de #2
    'faa1c830-f93e-4390-aa8d-2ad232a5eed8'  -- duplicata de #3
);

-- Raiz do problema: nunca ha por que "garantir" semanas do PASSADO no
-- seletor -- elas ja existem, criadas quando eram a semana atual/proxima
-- em algum momento real. p_weeks_back so existe pra backfill manual
-- deliberado (rodar a funcao direto com um valor explicito), nunca deveria
-- rodar sozinho a cada abertura do seletor. Trava aqui: so garante daqui
-- pra frente (p_weeks_back=0), preservando o forward=2 que mantem o
-- calendario futuro sempre povoado.
create or replace function public.list_weekend_league_events(p_limit integer default 12)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 12), 52));
    v_boundary timestamptz;
    v_items jsonb;
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    perform public.ensure_weekend_league_events(p_weeks_back => 0);

    select coalesce(starts_at, public._weekend_league_week_start(now()))
    into v_boundary
    from public.get_current_weekend_league_event();

    v_boundary := greatest(v_boundary, public._weekend_league_week_start(now()));

    select coalesce(jsonb_agg(item order by starts_at desc), '[]'::jsonb)
    into v_items
    from (
        select
            e.starts_at,
            jsonb_build_object(
                'id', e.id,
                'number', e.number,
                'season', e.season,
                'starts_at', to_jsonb(e.starts_at),
                'ends_at', to_jsonb(e.ends_at),
                'is_current', now() >= e.starts_at and now() < e.ends_at
            ) as item
        from public.weekend_league_events as e
        where e.is_active
          and e.starts_at <= v_boundary
        order by e.starts_at desc
        limit v_limit
    ) as page;

    return jsonb_build_object('items', v_items);
end;
$$;
