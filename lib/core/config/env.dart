/// Development-only fallback key, injected via
/// `--dart-define-from-file=env.json`. Empty in CI/release builds.
const String kTmdbApiKeyFromEnv = String.fromEnvironment('TMDB_API_KEY');
