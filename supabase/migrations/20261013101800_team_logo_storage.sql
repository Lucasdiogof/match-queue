-- Logo do time (secoes 27-29 da etapa de Solicitacoes). Primeiro uso de
-- Supabase Storage no projeto -- ate aqui todo image_url era CDN externa
-- (artwork da EA) ou string digitada pelo proprio usuario.
--
-- Bucket publico: teams.logo_url e consumido como URL https simples direta
-- (NetworkImage no cliente, sem passar pelo PostgREST/RLS), e
-- resolve_team_invite ja devolve team_logo_url pra ANON no preview do
-- convite -- teria que ser publico de qualquer forma. Nenhuma politica de
-- SELECT extra e necessaria: bucket publico serve leitura pela URL
-- publica independente de RLS.
--
-- Caminho de objeto fixo por time: '<team_id>/logo.<ext>'. Reenviar
-- substitui (upsert), nunca acumula lixo de uploads antigos.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'team-logos', 'team-logos', true, 2097152,
    array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

-- Escrita (insert/update/delete) so pro OWNER do time cujo id e o primeiro
-- segmento do caminho -- nunca ADMIN (gerente): secao 28 e explicita que
-- alterar logo e OWNER-only, diferente do resto da edicao do time.
create policy team_logos_insert_owner_only
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'team-logos'
        and public.is_team_owner(((storage.foldername(name))[1])::uuid)
    );

create policy team_logos_update_owner_only
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'team-logos'
        and public.is_team_owner(((storage.foldername(name))[1])::uuid)
    )
    with check (
        bucket_id = 'team-logos'
        and public.is_team_owner(((storage.foldername(name))[1])::uuid)
    );

create policy team_logos_delete_owner_only
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'team-logos'
        and public.is_team_owner(((storage.foldername(name))[1])::uuid)
    );

-- Defesa em profundidade: teams_update_admin ja libera OWNER e ADMIN pra
-- editar QUALQUER coluna de teams via update direto (PostgREST). Sem este
-- trigger, um ADMIN poderia trocar logo_url sozinho mesmo nunca escrevendo
-- no Storage -- so apontando pra uma URL https qualquer. O trigger fecha
-- essa porta especificamente pra logo_url, sem mexer em mais nada que
-- teams_update_admin ja permite.
create function public.teams_guard_logo_owner_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.logo_url is distinct from old.logo_url
        and not public.is_team_owner(old.id)
    then
        raise exception 'only the team owner can change the logo'
            using errcode = 'FQ012';
    end if;
    return new;
end;
$$;

create trigger teams_guard_logo_owner_only
    before update on public.teams
    for each row
    execute function public.teams_guard_logo_owner_only();
