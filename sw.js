// NardIQ Service Worker v2
const CACHE = 'nardiq-v2';

self.addEventListener('install', e => {
  // Não faz cache de arquivos específicos — só instala e ativa
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  // Limpa caches antigos
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  
  // Deixa requisições do Supabase passarem direto (sem cache)
  if (url.hostname.includes('supabase.co')) {
    return;
  }

  // Para o index.html: sempre busca da rede, usa cache como fallback
  if (url.pathname.endsWith('/') || url.pathname.endsWith('index.html')) {
    e.respondWith(
      fetch(e.request)
        .then(res => {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
          return res;
        })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // Para todo o resto: rede primeiro, cache como fallback
  e.respondWith(
    fetch(e.request)
      .then(res => {
        if (res && res.status === 200) {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
