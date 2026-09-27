// deno test supabase/functions/_shared/
import { normalizeMarketPlatform } from './market_platform.ts';
import { corsHeaders, withCors } from './cors.ts';

function assertEquals(actual: unknown, expected: unknown, msg: string) {
  if (actual !== expected) throw new Error(`${msg}: esperado ${expected}, veio ${actual}`);
}

Deno.test('platform: so ps/pc passam; resto cai em ps (nao fura o cache pago)', () => {
  assertEquals(normalizeMarketPlatform('ps'), 'ps', 'ps');
  assertEquals(normalizeMarketPlatform('pc'), 'pc', 'pc');
  assertEquals(normalizeMarketPlatform(undefined), 'ps', 'ausente');
  assertEquals(normalizeMarketPlatform('x1'), 'ps', 'valor inventado');
  assertEquals(normalizeMarketPlatform('ps&foo=bar'), 'ps', 'injecao na URL');
  assertEquals(normalizeMarketPlatform(42), 'ps', 'nao-string');
});

Deno.test('cors: preflight responde 204 sem chamar o handler', async () => {
  let called = false;
  const h = withCors(async () => {
    called = true;
    return new Response('x');
  });
  const res = await h(new Request('https://x/f', { method: 'OPTIONS' }));
  assertEquals(res.status, 204, 'status');
  assertEquals(called, false, 'handler');
  assertEquals(res.headers.get('Access-Control-Allow-Origin'), '*', 'origin');
});

Deno.test('cors: resposta normal (inclusive erro) leva os headers', async () => {
  const h = withCors(async () => new Response('{}', { status: 401 }));
  const res = await h(new Request('https://x/f', { method: 'POST' }));
  assertEquals(res.status, 401, 'status preservado');
  assertEquals(
    res.headers.get('Access-Control-Allow-Headers'),
    corsHeaders['Access-Control-Allow-Headers'],
    'allow-headers',
  );
});
