-- Companheiros de time precisam se enxergar para a lista de membros existir.
-- A alternativa preguicosa seria abrir profiles para qualquer usuario
-- autenticado, o que entregaria a base inteira de jogadores da plataforma.
-- Aqui a leitura continua fechada e so abre no recorte "compartilhamos ao
-- menos um time".
--
-- Limitacao conhecida: RLS filtra linha, nao coluna. Quem compartilha time
-- enxerga a linha inteira do profile -- inclusive locale, que nao tem valor
-- social nenhum. Enquanto profiles guardar apenas identidade publica isso e
-- aceitavel; no dia em que entrar um campo realmente privado, ele nao pode
-- morar nesta tabela (ou a leitura passa a ser por uma view/RPC que projeta
-- so as colunas publicas). Ver docs/database.md.

drop policy profiles_select_own on public.profiles;

create policy profiles_select_visible
    on public.profiles
    for select
    to authenticated
    using (
        (select auth.uid()) = id
        or public.shares_team_with(id)
    );
