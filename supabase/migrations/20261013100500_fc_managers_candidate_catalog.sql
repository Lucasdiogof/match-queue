-- FC 27 Ultimate Team ainda nao tem lista oficial fechada -- as duas fontes
-- disponiveis hoje sao candidatas, nao confirmadas (uma ainda mostra dado do
-- FC26, a outra e a expectativa do FC27 pra Career+UT). Este catalogo entra
-- como candidato agora e sera reconciliado (candidate -> confirmed, ou
-- candidate -> removed) numa proxima rodada quando a fonte fechar de vez.
--
-- is_selectable e o unico campo que controla visibilidade no picker --
-- status e source_tags sao so proveniencia/auditoria, nunca usados pra
-- filtrar sozinhos (um manager pode ficar CONFIRMED mas ainda assim
-- desabilitado por outro motivo no futuro, entao a decisao de mostrar fica
-- num campo proprio, nao emprestada de status).
alter table public.fc_managers
    add column is_selectable boolean not null default true,
    add column status text
        check (status is null or status in ('CANDIDATE', 'CONFIRMED', 'REMOVED')),
    add column source_tags text[] not null default '{}';

comment on column public.fc_managers.is_selectable is
    'Controla só a visibilidade no picker (search_fc_managers). Nunca apaga nem desvincula fc_squads.manager_id existente.';
comment on column public.fc_managers.status is
    'Proveniência do dado, não visibilidade: CANDIDATE (ainda não confirmado numa fonte oficial fechada), CONFIRMED, REMOVED (saiu do catálogo numa reconciliação). NULL para linhas fora deste ciclo (ex.: LOCAL).';
comment on column public.fc_managers.source_tags is
    'De quais listas candidatas este registro veio: UT_LEGACY_CANDIDATE (fifauteam.com, ainda mostrando dado FC26), FC27_EXPECTED_CANDIDATE (fifplay.com, expectativa FC27 Career+UT). Vazio para linhas fora deste ciclo.';

-- Chave de deduplicação do PRÓPRIO app para o import idempotente -- nunca um
-- id da EA nem de qualquer fonte externa (nenhuma delas expõe um id por
-- manager). Reimportar a mesma lista nunca duplica; reconciliar dá upsert
-- pela mesma chave.
alter table public.fc_managers
    add column name_key text generated always as (
        lower(regexp_replace(btrim(name), '\s+', ' ', 'g'))
    ) stored;

create unique index fc_managers_candidate_dedupe_idx
    on public.fc_managers (provider, name_key, coalesce(nation_id::text, ''))
    where provider = 'FC27_UT_CANDIDATE';

-- Os 24 managers ficticios (dev/teste, nunca vieram de fonte real) somem do
-- picker sem tocar em nenhuma linha de fc_squads -- auditado antes desta
-- migration: nenhum fc_squads.manager_id aponta pra eles hoje, mas a
-- estrategia e a mesma mesmo que algum dia apontasse (is_selectable nunca
-- deleta nem desvincula).
update public.fc_managers
set is_selectable = false
where provider = 'LOCAL';

-- search_fc_managers passa a só oferecer quem está selecionável -- REMOVED
-- de uma reconciliação futura também cai aqui automaticamente, sem precisar
-- de outro deploy.
create or replace function public.search_fc_managers(
    p_nation_id uuid default null,
    p_query text default null,
    p_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
    v_query text := nullif(btrim(coalesce(p_query, '')), '');
begin
    if (select auth.uid()) is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    return (
        select coalesce(jsonb_agg(
            jsonb_build_object(
                'id', m.id,
                'name', m.name,
                'image_url', m.image_url,
                'nation', case when n.id is null then null else jsonb_build_object(
                    'id', n.id, 'name', n.name,
                    'flag_image_url', n.flag_image_url
                ) end
            ) order by m.name
        ), '[]'::jsonb)
        from (
            select * from public.fc_managers
            where is_selectable
              and (p_nation_id is null or nation_id = p_nation_id)
              and (v_query is null or name ilike '%' || v_query || '%')
            order by name
            limit v_limit
        ) as m
        left join public.fc_nations as n on n.id = m.nation_id
    );
end;
$$;
