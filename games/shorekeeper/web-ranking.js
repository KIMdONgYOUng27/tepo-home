// Configure this URL after deploying the Vercel /api/ranking endpoint.
window.TepoRankingConfig = {endpoint: location.hostname.endsWith('.vercel.app') ? '/api/ranking' : ''};
