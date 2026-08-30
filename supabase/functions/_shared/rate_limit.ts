// Simple in-memory rate limiter for edge functions
// Note: This resets on function cold starts, but provides basic protection
const requestCounts = new Map<string, { count: number; resetAt: number }>()

export function checkRateLimit(
  identifier: string,
  maxRequests: number = 10,
  windowMs: number = 60_000
): { allowed: boolean; retryAfterMs: number } {
  const now = Date.now()
  const entry = requestCounts.get(identifier)

  if (!entry || now >= entry.resetAt) {
    requestCounts.set(identifier, { count: 1, resetAt: now + windowMs })
    return { allowed: true, retryAfterMs: 0 }
  }

  entry.count++
  if (entry.count > maxRequests) {
    return { allowed: false, retryAfterMs: entry.resetAt - now }
  }

  return { allowed: true, retryAfterMs: 0 }
}

export function getRateLimitHeaders(retryAfterMs: number): Record<string, string> {
  return {
    'Retry-After': String(Math.ceil(retryAfterMs / 1000)),
    'X-RateLimit-Reset': String(Math.ceil(retryAfterMs / 1000)),
  }
}
