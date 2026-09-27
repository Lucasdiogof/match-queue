// CORS das functions chamadas pelo app (inclusive o Flutter Web em
// match-queue.web.app). `functions.invoke` manda Authorization, entao o
// navegador faz preflight (OPTIONS): sem estas respostas a chamada nem sai
// do browser. Nao abre nada alem do que o JWT ja protege -- a autorizacao
// continua sendo o Bearer do usuario, validado em cada function.

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function withCors(
  handler: (req: Request) => Promise<Response>,
): (req: Request) => Promise<Response> {
  return async (req: Request) => {
    if (req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    const res = await handler(req);
    const headers = new Headers(res.headers);
    for (const [key, value] of Object.entries(corsHeaders)) {
      headers.set(key, value);
    }
    return new Response(res.body, { status: res.status, statusText: res.statusText, headers });
  };
}
