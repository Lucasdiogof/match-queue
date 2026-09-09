// Exclusao de conta (Fase A, item 8/9).
//
// O cliente nunca tem a service role key -- so ela pode remover um usuario
// de auth.users (supabase.auth.admin.deleteUser). Esta funcao existe so
// para isolar essa unica chamada privilegiada; toda a limpeza de dados
// (cancelar buscas, anonimizar historico compartilhado, dissolver/sair de
// times, deletar elencos) acontece antes, na RPC public.delete_my_account(),
// que roda como o proprio usuario (security definer, mas checa auth.uid()
// internamente -- nao precisa de service role).
//
// verify_jwt fica no default (true, ver supabase/config.toml) -- o gateway
// ja rejeita a chamada antes do codigo rodar se o JWT nao for valido. Ainda
// assim o handler extrai o usuario a partir do proprio JWT (nunca de um id
// no corpo da requisicao) chamando auth.getUser() com um client autenticado
// como o chamador -- e esse client (nao um client de service role) que
// chama a RPC, para que auth.uid() dentro dela resolva pro usuario certo.
//
// Idempotente: se chamada de novo com o mesmo token, getUser() ainda
// resolve (o usuario so e removido no final desta mesma chamada) -- mas uma
// segunda chamada so acontece se a primeira falhou antes de deletar
// auth.users, e delete_my_account() re-rodar sem ter sobrado nada pra
// cancelar/anonimizar/deletar e um no-op seguro.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.47.10';

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), { status: 405 });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'missing authorization header' }), { status: 401 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;

  // Client "como o usuario": usa a anon key + o JWT dele, nunca a service
  // role. auth.getUser() revalida o token direto no GoTrue (nao confia em
  // decodificar o JWT localmente).
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData?.user) {
    return new Response(JSON.stringify({ error: 'invalid session' }), { status: 401 });
  }
  const userId = userData.user.id;

  const { error: rpcError } = await callerClient.rpc('delete_my_account');
  if (rpcError) {
    // FQ044 (owner solo de time com outros membros) e o unico caso
    // esperado do dono do produto ler -- repassa a mensagem/codigo tal
    // qual, sem mascarar.
    return new Response(
      JSON.stringify({ error: rpcError.message, code: rpcError.code ?? null }),
      { status: 400 },
    );
  }

  // Unica etapa que exige privilegio: remover o usuario de auth.users.
  // Client separado, service role, nunca exposto ao Flutter.
  const adminClient = createClient(
    supabaseUrl,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
