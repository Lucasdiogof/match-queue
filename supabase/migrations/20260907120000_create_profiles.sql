-- Identidade publica/social do jogador dentro do FIFA Queue.
-- O e-mail NAO e copiado para ca: ele continua vivendo em auth.users, sob
-- responsabilidade do Supabase Auth. Convite por e-mail sera resolvido no
-- backend numa etapa futura, sem expor uma lista pesquisavel de e-mails.

create table public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    display_name text not null,
    avatar_url text,
    locale text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint profiles_display_name_not_blank
        check (btrim(display_name) <> ''),
    constraint profiles_display_name_length
        check (char_length(btrim(display_name)) between 2 and 32),
    constraint profiles_avatar_url_scheme
        check (avatar_url is null or avatar_url ~ '^https://'),
    constraint profiles_locale_format
        check (locale is null or locale ~ '^[a-z]{2}(-[A-Za-z0-9]{2,8})?$')
);

comment on table public.profiles is
    'Identidade publica do jogador. 1:1 com auth.users. Sem e-mail.';
comment on column public.profiles.display_name is
    'Nome ou apelido exibido no app. Obrigatorio, nao precisa ser unico.';

-- Mantem updated_at coerente sem depender do cliente enviar o valor.
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

create trigger profiles_set_updated_at
    before update on public.profiles
    for each row
    execute function public.set_updated_at();
