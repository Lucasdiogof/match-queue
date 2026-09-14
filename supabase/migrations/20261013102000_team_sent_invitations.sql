-- Lista de convites PENDING que o proprio time enviou, pra tela do time
-- poder mostrar "convite pendente pra fulano" e oferecer cancelar
-- (revoke_team_invitation ja existia, so nao tinha de onde ser chamado).
--
-- Security definer resolvendo o nome/avatar do convidado aqui, no mesmo
-- padrao de get_requests_inbox: nunca um embed PostgREST direto em
-- profiles, porque o convidado ainda nao e membro do time (a policy de
-- profiles baseada em shares_team_with nao alcancaria ele antes de aceitar).
create function public.get_team_sent_invitations(p_team_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not public.is_team_admin(p_team_id) then
        raise exception 'permission denied' using errcode = 'FQ012';
    end if;

    return coalesce((
        select jsonb_agg(
            jsonb_build_object(
                'id', i.id,
                'invitee_user_id', i.invitee_user_id,
                'invitee_display_name', p.display_name,
                'invitee_avatar_url', p.avatar_url,
                'created_at', to_jsonb(i.created_at)
            ) order by i.created_at desc
        )
        from public.team_invitations as i
        join public.profiles as p on p.id = i.invitee_user_id
        where i.team_id = p_team_id and i.status = 'PENDING'
    ), '[]'::jsonb);
end;
$$;

comment on function public.get_team_sent_invitations(uuid) is
    'Convites PENDING enviados por este time, com identidade minima do convidado ja resolvida. OWNER/ADMIN only.';

revoke execute on function public.get_team_sent_invitations(uuid) from public, anon;
grant execute on function public.get_team_sent_invitations(uuid) to authenticated;
