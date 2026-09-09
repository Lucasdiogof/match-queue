-- UI/UX refresh: card "Clubes" no Controle precisa de contagem de cartas e
-- rating medio por clube -- agregado que nao existia antes (so
-- get_fc_clubs, uma listagem simples sem numeros). SECURITY DEFINER porque
-- agrega fc_player_cards, mas filtra is_active = true manualmente (uma
-- funcao definer ignora RLS -- ver a lambrina do bug de is_active na
-- Etapa 17, 20260926100000_fc_catalog_active_only_select.sql): nunca conta
-- carta desativada.
create function public.get_fc_club_catalog_summary(p_limit integer default 12)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(jsonb_agg(
        jsonb_build_object(
            'club_id', c.id,
            'name', c.name,
            'logo_image_url', c.logo_image_url,
            'league_name', l.name,
            'card_count', counts.card_count,
            'average_rating', counts.average_rating
        )
        order by counts.card_count desc, c.name
    ), '[]'::jsonb)
    from public.fc_clubs as c
    join lateral (
        select
            count(*) as card_count,
            round(avg(pc.rating)) as average_rating
        from public.fc_player_cards as pc
        where pc.club_id = c.id and pc.is_active
    ) as counts on counts.card_count > 0
    left join public.fc_leagues as l on l.id = c.league_id
    limit greatest(1, least(coalesce(p_limit, 12), 50));
$$;

revoke execute on function public.get_fc_club_catalog_summary(integer)
    from public, anon;
grant execute on function public.get_fc_club_catalog_summary(integer)
    to authenticated;
