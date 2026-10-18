{{flutter_js}}
{{flutter_build_config}}

// The service worker is registered manually from index.html so we can control
// update behaviour (updateViaCache: 'none' + an automatic reload when a new
// version takes control). Passing no `serviceWorkerSettings` deliberately stops
// the Flutter loader from registering its own built-in (now deprecated and
// self-unregistering) service worker, which would otherwise fight with ours.
_flutter.loader.load();
