var VERSION = "0.2.0"
var CACHE_NAME = 'dative-' + VERSION;

// TODO: this list needs to be generated dynamically, especially given the
// grunt build process...
// Grunt build needs to trigger a script that updates the ``urlsToCache`` array
// so that it contains:
// /scripts/f7fa69fd.main.js
// /scripts/vendor/a52a8685.modernizr.js
// /scripts/vendor/require.js
// /styles/9a6856a3.main.css
// /styles/fonts/GentiumPlus-I.woff
// /styles/fonts/GentiumPlus-R.woff
// /styles/images/* --- ? many images; when, if ever, are these requested?
// /bower_components/jqueryui/themes/pepper-grinder/ --- every thing in here (?)
// /help/html/help.html
// /images/help/* --- requested when help dialog opens
// /images/jqueryui-theme-examples/* --- requested when app settings opened
// /404.html ???
// /UnicodeData.json --- requested when app settings or input validation opened
// /favicon.png
// /index.html
// /package.json
// /robots.txt
// /servers.json

var urlsToCache = [
  '/scripts/routes/router.js'
];

self.addEventListener('install', function(event) {
  // Perform install steps
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(function(cache) {
        console.log('Opened cache');
        return cache.addAll(urlsToCache);
      })
  );
});

self.addEventListener('activate', function(event) {
  console.log('service worker ACTIVATED');
  var cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then(function(cacheNames) {
      return Promise.all(
        cacheNames.map(function(cacheName) {
          if (cacheWhitelist.indexOf(cacheName) === -1) {
            console.log('deleting cache ' + cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.match(event.request)
      .then(function(response) {
        // Cache hit - return response
        if (response) {
          return response;
        }
        // IMPORTANT: Clone the request. A request is a stream and
        // can only be consumed once. Since we are consuming this
        // once by cache and once by the browser for fetch, we need
        // to clone the response.
        var fetchRequest = event.request.clone();
        return fetch(fetchRequest).then(
          function(response) {
            // If we have no response, a not-ok response or a cross-origin
            // response, just return it without caching.
            if(!response || response.status !== 200 ||
                response.type !== 'basic') {
              return response;
            }
            // IMPORTANT: Clone the response. A response is a stream
            // and because we want the browser to consume the response
            // as well as the cache consuming the response, we need
            // to clone it so we have two streams.
            var responseToCache = response.clone();
            caches.open(CACHE_NAME)
              .then(function(cache) {
                cache.put(event.request, responseToCache);
              });
            return response;
          }
        );
      })
    );
});

