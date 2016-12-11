// Dative Service Worker
// - for caching requests in the browser
// - for offline capability
// - for speedier launch
//
// See:
// - https://developers.google.com/web/fundamentals/primers/service-worker/
// - https://developer.mozilla.org/en-US/docs/Web/API/Cache
// - https://github.com/w3c/ServiceWorker/blob/master/explainer.md

// This constant is set by scripts/set_ci_version.sh when the grunt task
// 'build' is run.
var VERSION = "4.34.10";

var CACHE_NAME = 'dative-' + VERSION;

// The ``urlsToCache`` array is generated dynamically via
// scripts/set-sw-cache-paths. This generation is triggered via ``grunt build``.
var urlsToCache = [];

// When Dative requests the servers.json file, the service worker will
// intercept that and store the servers in memory here. That way, we can create
// a cache for each server so that the user can have offline read-only access
// to their textual data.
var oldServers = [];

// We open a Dative-version-specific cache on install. Then we download and
// cache all of the URLs in ``urlsToCache``.
self.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('INSTALL event');
        console.log('Opened cache ' + CACHE_NAME);
        return cache.addAll(urlsToCache);
      })
  );
});

// When the 'activate' event occurs, we destroy all caches aside from
// ``CACHE_NAME``;
self.addEventListener('activate', function(event) {
  var cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      console.log('ACTIVATE event');
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            console.log('Deleted cache ' + cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

// Whenever the app tries to fetch a file from the network, we first
// check if we have a cached response. If so, we return it. If not, we perform
// the request across the network and possible cache the response before
// returning it to the application logic.
self.addEventListener('fetch', function(event) {
  if (/\/login\/authenticate$/.test(event.request.url)) {
    oldCacheName = event.request.url.replace('/login/authenticate', '');
    console.log('AUTHENTICATING TO OLD ' + oldCacheName);
    // TODO: create a cache for these requests ...
  }
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // We have a cached response --- return it!
        if (response) {
          var r = event.request.clone();
          console.log('returning cached response to request: '
                      + r.method + ' ' + r.url);
          return response;
        }
        // We have no cached response so we perform the fetch across the
        // network. (Cloning the request is necessary.)
        var fetchRequest = event.request.clone();
        return fetch(fetchRequest).then(
          function(response) {
            // If we have no response, a not-ok response or a cross-origin
            // response, just return it without caching.
            if(!response || response.status !== 200 ||
                response.type !== 'basic') {
              var r = event.request.clone();
              console.log('NOT caching response to not-OK interceded request: '
                          + r.method + ' ' + r.url);
              return response;
            }
            // IMPORTANT: Necessary to clone the response.
            var responseToCache = response.clone();
            caches.open(CACHE_NAME)
              .then(function(cache) {
                var r = event.request.clone();
                console.log('caching response to interceded request: '
                            + r.method + ' ' + r.url);
                cache.put(event.request, responseToCache);
              });
            return response;
          }
        );
      })
    );
});

