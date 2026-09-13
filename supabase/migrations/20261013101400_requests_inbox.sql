-- Payload unico para a nova tab "Solicitacoes": convites recebidos pelo
-- usuario + pedidos pendentes dos times que ele administra. Um RPC so, no
-- mesmo padrao de get_public_profile/get_team_member_profile, em vez de dois
-- selects PostgREST com embed atraves de tabelas com RLS diferentes.
create function public.get_requests_inbox()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_id uuid := (select auth.uid());
    v_invitations jsonb;
    v_join_requests jsonb;
begin
    if v_user_id is null then
        raise exception 'authentication required' using errcode = 'FQ003';
    end if;

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', i.id,
            'team_id', i.team_id,
            'team_name', t.name,
            'team_tag', t.tag,
            'team_logo_url', t.logo_url,
            'member_count', (
                select count(*) from public.team_members m where m.team_id = t.id
            ),
            'fc_account_name', a.name,
            'created_at', to_jsonb(i.created_at)
        ) order by i.created_at desc
    ), '[]'::jsonb)
    into v_invitations
    from public.team_invitations as i
    join public.teams as t on t.id = i.team_id
    left join public.user_fc_accounts as a on a.id = i.fc_account_id
    where i.invitee_user_id = v_user_id and i.status = 'PENDING';

    select coalesce(jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'team_id', r.team_id,
            'team_name', t.name,
            'requester_user_id', r.user_id,
            'requester_display_name', p.display_name,
            'requester_avatar_url', p.avatar_url,
            'fc_account_name', a.name,
            'created_at', to_jsonb(r.created_at)
        ) order by r.created_at desc
    ), '[]'::jsonb)
    into v_join_requests
    from public.team_join_requests as r
    join public.teams as t on t.id = r.team_id
    join public.profiles as p on p.id = r.user_id
    join public.user_fc_accounts as a on a.id = r.fc_account_id
    where r.status = 'PENDING' and public.is_team_admin(r.team_id);

    return jsonb_build_object(
        'invitations_received', v_invitations,
        'join_requests_to_review', v_join_requests
    );
end;
$$;

comment on function public.get_requests_inbox() is
    'Payload da tab Solicitacoes: convites PENDING recebidos pelo usuario + pedidos PENDING dos times que ele administra (OWNER/ADMIN). Badge da bottom nav soma os dois tamanhos.';

revoke execute on function public.get_requests_inbox() from public, anon;
grant execute on function public.get_requests_inbox() to authenticated;
