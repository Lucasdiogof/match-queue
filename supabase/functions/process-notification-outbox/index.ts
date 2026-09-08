// Worker da outbox de notificacoes.
//
// Nao decide nada sobre a fila: apenas entrega alertas de eventos que o
// Postgres ja decidiu e ja commitou. Se este worker ficar fora do ar, o
// estado do matchmaking continua correto -- so os pushes atrasam, e a
// outbox os guarda ate serem entregues.
//
// Invocacao: pg_net dispara assim que a outbox recebe linha (latencia de
// segundos) e um cron de 1 minuto cobre a falha desse disparo.
//
// Segredos (Edge Function secrets, nunca no Git):
//   WORKER_SECRET          header compartilhado com o trigger do Postgres
//   FIREBASE_PROJECT_ID    projeto do Firebase
//   FIREBASE_CLIENT_EMAIL  service account
//   FIREBASE_PRIVATE_KEY   chave privada da service account (PEM)
// SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY sao injetados pela plataforma.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.47.10';

type NotificationType = 'YOUR_TURN' | 'SEARCH_EXPIRING' | 'SEARCH_EXPIRED';

interface OutboxItem {
  id: string;
  type: NotificationType;
  team_id: string | null;
  session_id: string | null;
  payload: Record<string, unknown>;
  locale: string | null;
  tokens: string[];
}

// O texto vive aqui, nao na outbox: guardar a frase pronta no banco
// impediria escolher o idioma do destinatario na hora da entrega.
const COPY: Record<string, Record<NotificationType, { title: string; body: string }>> = {
  pt: {
    YOUR_TURN: { title: 'Sua vez de buscar!', body: 'Chegou a sua vez na fila. Abra o app e comece a busca.' },
    SEARCH_EXPIRING: { title: 'Faltam 30 segundos', body: 'Sua busca está perto de terminar.' },
    SEARCH_EXPIRED: { title: 'Seu tempo de busca terminou', body: 'A vez passou para o próximo da fila.' },
  },
  en: {
    YOUR_TURN: { title: 'Your turn to search!', body: 'You are up in the queue. Open the app and start searching.' },
    SEARCH_EXPIRING: { title: '30 seconds left', body: 'Your search is about to end.' },
    SEARCH_EXPIRED: { title: 'Your search time is over', body: 'The turn moved to the next player in the queue.' },
  },
  es: {
    YOUR_TURN: { title: '¡Tu turno de buscar!', body: 'Llegó tu turno en la fila. Abre la app y empieza la búsqueda.' },
    SEARCH_EXPIRING: { title: 'Quedan 30 segundos', body: 'Tu búsqueda está por terminar.' },
    SEARCH_EXPIRED: { title: 'Tu tiempo de búsqueda terminó', body: 'El turno pasó al siguiente de la fila.' },
  },
};

const copyFor = (type: NotificationType, locale: string | null) => {
  const language = (locale ?? 'en').split('-')[0].toLowerCase();
  return (COPY[language] ?? COPY.en)[type];
};

function pemToDer(pem: string): Uint8Array {
  const body = pem
    .replace(/\\n/g, '\n')
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s+/g, '');
  return Uint8Array.from(atob(body), (ch) => ch.charCodeAt(0));
}

const base64Url = (input: string | Uint8Array): string => {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

// FCM v1 exige OAuth2; o token e obtido assinando um JWT com a service
// account. Fica em cache enquanto vale, para nao pagar essa ida a cada lote.
let cachedAccessToken: { value: string; expiresAt: number } | null = null;

async function accessToken(): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.value;
  }

  const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL');
  const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY');
  if (!clientEmail || !privateKey) {
    throw new Error('firebase credentials are not configured');
  }

  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64Url(JSON.stringify({
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  const assertion = `${header}.${claims}.${base64Url(signature)}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!res.ok) {
    throw new Error(`oauth token request failed: ${res.status}`);
  }
  const json = await res.json();
  cachedAccessToken = {
    value: json.access_token,
    expiresAt: Date.now() + (json.expires_in ?? 3600) * 1000,
  };
  return cachedAccessToken.value;
}

// Codigos em que insistir nao adianta: o token nao existe mais. Qualquer
// outro erro e tratado como temporario e volta pelo backoff da outbox.
const DEAD_TOKEN_ERRORS = new Set(['UNREGISTERED', 'INVALID_ARGUMENT', 'SENDER_ID_MISMATCH']);

async function sendToToken(
  projectId: string,
  token: string,
  item: OutboxItem,
): Promise<{ ok: boolean; dead: boolean; error?: string }> {
  const { title, body } = copyFor(item.type, item.locale);
  const bearer = await accessToken();

  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        // Só ids: o app relê o estado oficial ao abrir. Nada de e-mail,
        // token ou composicao da fila no payload.
        data: {
          type: item.type,
          team_id: item.team_id ?? '',
          session_id: item.session_id ?? '',
        },
        android: {
          priority: item.type === 'YOUR_TURN' ? 'HIGH' : 'NORMAL',
          notification: { channel_id: 'queue_alerts' },
        },
        apns: {
          headers: { 'apns-priority': item.type === 'YOUR_TURN' ? '10' : '5' },
          payload: { aps: { sound: item.type === 'YOUR_TURN' ? 'default' : undefined } },
        },
      },
    }),
  });

  if (res.ok) {
    return { ok: true, dead: false };
  }

  const detail = await res.text();
  let code = '';
  try {
    code = JSON.parse(detail)?.error?.details?.[0]?.errorCode ?? JSON.parse(detail)?.error?.status ?? '';
  } catch { /* keep raw */ }

  return { ok: false, dead: DEAD_TOKEN_ERRORS.has(code), error: `${res.status} ${code || detail.slice(0, 160)}` };
}

Deno.serve(async (req) => {
  if (req.headers.get('x-worker-secret') !== Deno.env.get('WORKER_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }

  const projectId = Deno.env.get('FIREBASE_PROJECT_ID');
  if (!projectId) {
    return new Response(JSON.stringify({ error: 'firebase is not configured' }), { status: 503 });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data, error } = await supabase.rpc('claim_notification_batch', { p_limit: 25 });
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  const items = (data ?? []) as OutboxItem[];
  let delivered = 0;
  let failed = 0;

  for (const item of items) {
    const results = await Promise.all(
      item.tokens.map(async (token) => {
        try {
          const result = await sendToToken(projectId, token, item);
          if (result.dead) {
            await supabase.rpc('deactivate_device_token', { p_fcm_token: token });
          }
          return result;
        } catch (e) {
          return { ok: false, dead: false, error: (e as Error).message };
        }
      }),
    );

    // Um unico aparelho que recebeu ja cumpre o proposito do alerta. Se
    // nenhum recebeu, o evento continua pendente e volta pelo backoff.
    const anyDelivered = results.some((r) => r.ok);
    const firstError = results.find((r) => !r.ok)?.error ?? null;

    await supabase.rpc('complete_notification', {
      p_id: item.id,
      p_success: anyDelivered,
      p_error: anyDelivered ? null : firstError,
    });

    anyDelivered ? delivered++ : failed++;
  }

  return new Response(JSON.stringify({ claimed: items.length, delivered, failed }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
