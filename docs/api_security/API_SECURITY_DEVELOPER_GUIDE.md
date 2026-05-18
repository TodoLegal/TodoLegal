# API Security Developer Guide — TodoLegal

**Last Updated:** May 1, 2026
**Companion doc:** [API_SECURITY_ARCHITECTURE.md](API_SECURITY_ARCHITECTURE.md) — read that first for system understanding.

---

## Quick Reference

| File | What it does |
|------|-------------|
| `config/initializers/cors.rb` | CORS origin whitelist (`CORS_ALLOWED_ORIGINS` env var) |
| `config/initializers/rack_attack.rb` | Rate limits, bot blocklist, honeypot, Fail2Ban |
| `config/initializers/doorkeeper.rb` | OAuth2 config (expiry, hashing, refresh tokens) |
| `app/controllers/api/v1/base_controller.rb` | `verify_turnstile_token!` — Turnstile enforcement + bypass logic |
| `app/controllers/concerns/api/v1/turnstile_verifiable.rb` | Same Turnstile logic as concern (for Devise controllers) |
| `app/services/turnstile_verifier.rb` | Calls Cloudflare siteverify API, caches in Redis |
| `lib/tasks/doorkeeper_hash_tokens.rake` | Batch-hash plaintext tokens to SHA256 |
| `src/api/apiClient.js` | Axios instance with Bearer + refresh interceptors |
| `src/api/turnstileTokenStore.js` | Turnstile token store + `getTurnstileHeaders()` helper |
| `src/context/TurnstileContext.js` | Invisible Turnstile widget (React) |

---

## Adding a New Rails API Endpoint

### Decision checklist

```
1. Does the endpoint return sensitive/premium data?
   YES → Add doorkeeper_authorize! (require login)
   NO  → Continue

2. Is the data fully public (tags, sitemap, search listings)?
   YES → Add skip_before_action :verify_turnstile_token!
   NO  → Leave default (Turnstile enforced for anonymous users)

3. Does the controller inherit from Api::V1::BaseController?
   YES → Turnstile is automatic (inherited before_action)
   NO  → Include Api::V1::TurnstileVerifiable concern
```

### Example: New public endpoint (no auth, no Turnstile)

```ruby
class Api::V1::StatsController < Api::V1::BaseController
  skip_before_action :verify_turnstile_token!

  def index
    render json: { total_documents: Document.count }
  end
end
```

### Example: New protected endpoint (auth required)

```ruby
class Api::V1::BookmarksController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def index
    user = User.find(doorkeeper_token.resource_owner_id)
    render json: user.bookmarks
  end
end
```

Turnstile is still inherited but will be auto-skipped because `doorkeeper_token.present?` returns `true` for authenticated requests.

### Example: Devise-based controller (cannot inherit from BaseController)

```ruby
class Api::V1::CustomSessionsController < Devise::SessionsController
  include Api::V1::TurnstileVerifiable
  # Turnstile verification is now active via the concern
end
```

---

## Adding a New React API Call

### Decision checklist

```
1. Does the call need authentication (Bearer token)?
   YES → Use apiClient (gets Bearer + refresh for free)
   NO  → Use plain axios

2. Does the endpoint validate Turnstile for anonymous users?
   YES → Add getTurnstileHeaders() call before the request
   NO  → Just use apiClient or plain axios directly

3. Is the endpoint fully public (no auth, no Turnstile)?
   YES → Use plain axios (like ui.js does for tags)
```

### Current pattern by action file

| File | Import | Turnstile | Why |
|------|--------|-----------|-----|
| `document.js` | `apiClient` + `getTurnstileHeaders` | Yes | `get_document` validates Turnstile for anonymous users |
| `feed.js` | `apiClient` | No | `get_documents` is Turnstile-exempt server-side |
| `user.js` | `apiClient` | No | Authenticated-only endpoints; Turnstile auto-skipped |
| `auth.js` | `apiClient` | No | `/oauth/token` is Doorkeeper's controller (not behind BaseController) |
| `ui.js` | plain `axios` | No | Tags are fully public — no auth, no Turnstile |

### Example: New call to a Turnstile-validated endpoint

```javascript
import apiClient from '../../api/apiClient';
import { getTurnstileHeaders } from '../../api/turnstileTokenStore';

export const fetchSomething = (id) => {
  return async (dispatch) => {
    const turnstileHeaders = await getTurnstileHeaders();
    const response = await apiClient.get(`${baseUrl}/something/${id}`, {
      headers: turnstileHeaders,
    });
    dispatch(success(response.data));
  };
};
```

`getTurnstileHeaders()` returns `{}` immediately for logged-in users (checks `localStorage` for `access_token`). No Turnstile wait.

### Example: New call to a Turnstile-exempt endpoint

```javascript
import apiClient from '../../api/apiClient';

export const fetchListing = () => {
  return async (dispatch) => {
    const response = await apiClient.get(`${baseUrl}/listing`);
    dispatch(success(response.data));
  };
};
```

---

## Debugging Auth Failures

### 401 Unauthorized

**Meaning:** No valid Doorkeeper token. The request either has no `Authorization: Bearer` header, or the token is expired/revoked.

**Check:**
1. Is `access_token` in `localStorage`? → If missing, user is logged out
2. Is the token expired? → The refresh interceptor should handle this automatically. Check browser console for refresh errors.
3. Did the refresh fail? → Both `access_token` and `refresh_token` will be cleared from `localStorage`. User needs to log in again.
4. Is `apiClient` being used? → Plain `axios` calls don't get Bearer headers. Switch to `apiClient`.

### 403 Forbidden

**Meaning:** Request reached the controller but was rejected. Check the response body:

| Response body | Layer | Cause | Fix |
|--------------|-------|-------|-----|
| `{ "error": "Forbidden", "reason": "turnstile_failed" }` | Turnstile | Missing or invalid Turnstile token | Ensure `getTurnstileHeaders()` is called, Turnstile widget is mounted |
| `{ "error": "Forbidden" }` (no reason) | Rack::Attack | Blocked user agent or rate limit ban | Check `rack_attack.rb` blocklist patterns |

### 429 Too Many Requests

**Meaning:** Rack::Attack throttle limit hit. Response includes `Retry-After` header.

**Check:** Which throttle rule was triggered — look at Rails logs for `[Rack::Attack]` entries.

### CORS error (browser console)

**Meaning:** Request origin not in `CORS_ALLOWED_ORIGINS`.

**Fix:** Add the origin to the `CORS_ALLOWED_ORIGINS` env var (comma-separated). Restart Rails.

### Turnstile verification timeline

```
Widget renders → solves challenge (~1-3s) → onSuccess → setTurnstileToken()
                                                            ↓
getTurnstileHeaders() called → getFreshToken() → returns token → request sends
                                    ↓
                         (if no token yet, waits up to 8s)
                                    ↓
                         (if token expired at 280s, clears and waits for refresh)
```

If `getTurnstileHeaders()` hangs: check that `<TurnstileProvider>` is mounted in the component tree and `REACT_APP_TURNSTILE_SITE_KEY` is set.

---

## Modifying Rack::Attack Rules

All rules are in `config/initializers/rack_attack.rb`.

### Adding a new throttle

```ruby
throttle('api/new-endpoint/ip', limit: 50, period: 5.minutes) do |req|
  req.ip if req.path.match?(/^\/api\/v1\/new_endpoint/)
end
```

### Adding a user-agent to the blocklist

Add the pattern (lowercase) to the `malicious_patterns` array in the `block-malicious-user-agents` blocklist:

```ruby
malicious_patterns = %w[
  # ... existing patterns ...
  newbotname
]
```

### Adding a temporary email domain to the blocklist

Add the domain to the `suspicious_domains` array in the `block-temporary-email-domains` blocklist.

### Testing locally

Rack::Attack uses Redis. Make sure Redis is running locally. Safelist includes `localhost` — your local requests won't be throttled. To test throttling, temporarily remove the localhost safelist.

---

## Modifying Turnstile Exemptions

### Exempting a new endpoint

In your controller:

```ruby
class Api::V1::MyController < Api::V1::BaseController
  skip_before_action :verify_turnstile_token!, only: [:public_action]
end
```

### When to exempt

- The endpoint returns only public, non-sensitive data
- Multiple concurrent requests hit the endpoint (Turnstile tokens are single-use — concurrent requests cause race conditions)
- The endpoint is called by crawlers or bots that cannot solve Turnstile

### When NOT to exempt

- The endpoint returns premium/paywalled content
- The endpoint is a primary scraping target (individual document content)

---

## Rotating Secrets

### Turnstile keys

1. Go to Cloudflare Dashboard → Turnstile → TodoLegal API widget
2. Regenerate keys
3. Update `TURNSTILE_SECRET_KEY` env var on Rails (staging + production)
4. Update `REACT_APP_TURNSTILE_SITE_KEY` env var on React (staging + production)
5. Redeploy both

### OG Worker shared secret

1. Generate a new secret: `openssl rand -hex 32`
2. Update `OG_WORKER_SECRET` env var on Rails
3. Update the secret in the Cloudflare Worker (Workers → Settings → Environment Variables)
4. Redeploy Rails

### Doorkeeper application secrets

Application secrets are hashed in the database. To rotate:

1. `rails console` → `app = Doorkeeper::Application.find_by(name: 'Valid')`
2. `app.secret = Doorkeeper::OAuth::Helpers::UniqueToken.generate` → `app.save`
3. The new secret will be auto-hashed on save
4. Update `REACT_APP_CLIENT_SECRET` env var on React
5. Redeploy React. Existing sessions will continue working until their tokens expire.

---

## Token Hashing Operations

### Running the rake task

```bash
# On production (during low traffic)
RAILS_ENV=production bundle exec rake doorkeeper:hash_existing_tokens
```

Output: `Hashed N tokens. Skipped M (already hashed).`

The task identifies plaintext tokens by checking if they match the SHA256 hex pattern (`/\A[a-f0-9]{64}\z/`). Already-hashed tokens are skipped.

### Removing `fallback: :plain`

After running the rake task and monitoring for 24-48 hours with no auth failures:

In `config/initializers/doorkeeper.rb`, change:

```ruby
# Before
hash_token_secrets fallback: :plain
hash_application_secrets fallback: :plain

# After
hash_token_secrets
hash_application_secrets
```

This disables plaintext token lookup. Any remaining unhashed tokens will stop working.

### What to monitor after removing fallback

- 401 errors in Rails logs — if a spike occurs, a token wasn't hashed
- User reports of being logged out — their token may have been missed by the rake task
- Rollback: re-add `fallback: :plain` if issues arise

---

## Common Gotchas

1. **Turnstile auto-skips for authenticated users (server-side).** `verify_turnstile_token!` returns immediately if `doorkeeper_token.present?`. Sending a Turnstile token to an authenticated endpoint is harmless but unnecessary.

2. **`getTurnstileHeaders()` skips for logged-in users (client-side).** It checks `localStorage` for `access_token`. If present, returns `{}` without waiting for the Turnstile widget. This avoids the 1-3 second widget solve delay for logged-in users.

3. **Doorkeeper's `/oauth/token` is NOT behind `BaseController`.** It's Doorkeeper's own controller, mounted via `use_doorkeeper` in routes. Turnstile tokens sent to this endpoint are silently ignored.

4. **Tags use plain `axios`, not `apiClient`.** Tags are fully public (no auth, no Turnstile). Using `apiClient` would attach a Bearer token unnecessarily. If you move tags behind auth, switch to `apiClient`.

5. **Feed uses `apiClient` but no `getTurnstileHeaders()`.** The `get_documents` endpoint is Turnstile-exempt server-side. Feed uses `apiClient` only for the Bearer + refresh interceptors.

6. **`DownloadButton.js` intentionally uses `?access_token=` query param.** Browser `<a href>` downloads cannot set custom headers. This is the only remaining use of the query parameter pattern. `ActiveStorageRedirectController` reads `params[:access_token]` for this case.

7. **CORS only affects browsers.** `curl`, Python scripts, and other non-browser clients bypass CORS entirely. They are blocked by Turnstile (can't solve the challenge) and Rack::Attack (user-agent blocklist).

8. **Rack::Attack safelists take priority.** If a request matches both a safelist and a blocklist, the safelist wins. Localhost is always safelisted.

9. **Turnstile tokens are single-use.** Each token can only be validated once via the siteverify API. The 5-minute Redis cache prevents redundant API calls for the same IP, but the original token is consumed on first verification.

10. **The `authentication_token` column still exists in the database.** The column is no longer read or written by any code. It can be dropped with a migration when convenient, but leaving it is harmless.
