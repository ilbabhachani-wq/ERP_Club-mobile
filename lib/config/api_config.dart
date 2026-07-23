/// Backend SaaS — même base que le proxy Vite web (sans préfixe /api).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://erp-club-backend-production.up.railway.app',
);

const String kSocketBaseUrl = String.fromEnvironment(
  'SOCKET_BASE_URL',
  defaultValue: 'https://erp-club-backend-production.up.railway.app',
);
