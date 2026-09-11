-- Correcao de 20261012100000: o revoke de public tirou o execute tambem de
-- service_role, que herda dele -- e service_role e justamente o unico
-- chamador possivel desta funcao (o probe roda server-side com a secret key).
-- Sem este grant a funcao era inalcancavel por qualquer role.
--
-- Nao e grant profilatico: e o chamador real e unico. anon e authenticated
-- seguem sem acesso, como devem, porque nem o app nem um usuario logado tem
-- motivo para escrever disponibilidade de artwork.

grant execute on function public.apply_card_artwork_probe(uuid[], text[], uuid[])
    to service_role;
