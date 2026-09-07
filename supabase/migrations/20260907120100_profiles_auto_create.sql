-- Todo usuario do Auth precisa ter um profile. Fazer esse insert do lado do
-- Flutter abriria uma janela em que existe auth.users sem public.profiles
-- (app fechado entre o signup e o insert, signup criado pelo Dashboard,
-- etc.), entao a criacao acontece server-side.
--
-- O trigger e deliberadamente defensivo: qualquer falha aqui e registrada
-- como warning e o signup segue em frente. Um usuario sem profile e um
-- problema recuperavel (o app chama ensureProfile no primeiro acesso);
-- um signup que falha inteiro nao e.

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    candidate text;
begin
    candidate := btrim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));

    if candidate = '' then
        candidate := btrim(coalesce(new.raw_user_meta_data ->> 'name', ''));
    end if;

    if candidate = '' then
        candidate := btrim(split_part(coalesce(new.email, ''), '@', 1));
    end if;

    candidate := left(candidate, 32);

    -- Respeita profiles_display_name_length (entre 2 e 32 caracteres).
    if char_length(candidate) < 2 then
        candidate := 'Jogador';
    end if;

    insert into public.profiles (id, display_name)
    values (new.id, candidate)
    on conflict (id) do nothing;

    return new;
exception
    when others then
        raise warning 'handle_new_user falhou para % (%): %',
            new.id, sqlstate, sqlerrm;
        return new;
end;
$$;

comment on function public.handle_new_user() is
    'Cria public.profiles a partir de raw_user_meta_data->>display_name. '
    'Nunca aborta o signup: falhas viram warning no log do Postgres.';

create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();
