'use strict';

// Bumped automatically at deploy time (see deploy-pages.yml): the CI replaces
// the __BUILD__ token with the git commit SHA. This changes the file bytes on
// every deploy (so browsers detect the update) and rotates the cache name (so
// stale caches are purged).
const BUILD = '__BUILD__';
const CACHE_NAME = 'pomodoro-pro-' + BUILD;
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(
        names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Only handle same-origin GET requests; let the network deal with the rest.
  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;

  // Network-first for everything so a fresh deploy is always picked up; the
  // cache is only ever used as an offline fallback. (Cache-first here is what
  // previously forced users to hard-refresh to see new builds.)
  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response && response.status === 200 && response.type === 'basic') {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy));
        }
        return response;
      })
      .catch(() => {
        if (request.mode === 'navigate') return caches.match('./index.html');
        return caches.match(request);
      })
  );
});
