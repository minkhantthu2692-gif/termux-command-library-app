# Groq API setup (BYOK)

The AI assistant is optional. It uses **your own Groq API key** (bring your own
key) and is disabled by default. The app has no bundled provider key and will not
work with AI until a key is entered, tested and saved.

The Groq key is **not** needed to build the app. Firebase and Groq are independent:
you can run local-only with AI, or online sync without AI.

---

## 1. Create a key

1. Sign in at <https://console.groq.com>.
2. Open **API Keys** → <https://console.groq.com/keys>.
3. Create a new key and copy it once. Groq shows the full key only at creation.
4. Treat the key like a password. Do not paste it into GitHub, screenshots, issues
   or shared build scripts.

## 2. Configure it in the app

1. Open **Profile → Settings → AI Assistant** (or the Assistant tab's setup card).
2. Paste the key into the secure field.
3. Use **Test key**. This calls `GET https://api.groq.com/openai/v1/models` with
   `Authorization: Bearer <key>` and accepts only HTTP 200.
4. Use **Fetch models** to load the current model list.
5. Select a model.
6. Toggle AI on.
7. Optionally open the help dialog/setup guide for cache and history controls.

The app never hard-codes a model name. The list always comes from the provider,
so new Groq models appear without an app update. The picker only lists
chat-capable models: an entry must accept text input, produce text output and not
be a moderation classifier. Groq's speech, transcription and prompt-guard models
are therefore hidden automatically, including models added after this release.

## 3. Where the key is stored

`SecureApiKeyStore` is the only code that touches the key:

- Android `flutter_secure_storage` (backed by the Android Keystore).
- Stored under a provider-scoped name such as `tcl.ai.apiKey.groq`.
- Never written to SQLite, Firestore, AI history, cache entries, logs, crash
  reports, analytics or Git.
- The UI only exposes whether a key exists; repository methods read the key when
  making a request and do not return it to widgets.
- Removing the key deletes the secure-storage entry.

Secure storage protects against casual data extraction, but it cannot make a
compromised or rooted device completely safe. If you believe a key leaked, revoke
it in the Groq console and create a new one.

## 4. Provider abstraction

The UI depends on `AiProvider`, not on Groq:

```text
AiProvider
  providerId
  validateApiKey
  fetchModels
  streamChat
```

`GroqAiProvider` implements the OpenAI-compatible endpoints:

- Base URL: `https://api.groq.com/openai/v1`
- Models: `GET /models`
- Chat: `POST /chat/completions` with `stream: true`
- Timeout: 45 seconds
- SSE `data:` frames, `[DONE]`, content deltas, finish reason and usage metadata.
  Live Groq streams deliver token usage in the final chunk's `x_groq.usage`
  wrapper (not a top-level `usage` field), so both shapes are parsed.

To add Gemini or another provider:

1. Implement `AiProvider`.
2. Register it in `aiProviderProvider` (or a provider factory) without changing
   feature UI.
3. Add its key storage namespace and model discovery.
4. Extend settings/provider selection and localization.
5. Add HTTP/SSE tests like `test/data/groq_provider_test.dart`.

Do not put provider-specific HTTP code in widgets or repositories.

## 5. Models

- Models are fetched dynamically and cached locally with a one-day TTL.
- Only chat-capable models are listed. The filter uses the API's own capability
  metadata (`input_modalities` must include `text`, `output_modalities` must
  include `text`) plus a guard-model exclusion, so no chat allow-list is
  hard-coded.
- Inactive models (`active: false`) are marked unavailable.
- The selected model ID is stored in local settings, not Firestore.
- If a saved model disappears, the UI asks the user to choose another; it does not
  silently substitute a model.
- Model context window metadata is displayed when provided.

### Verified against the live API (2026-10-28)

- `GET /models` returned 11 models; 4 passed the chat-capable filter
  (`qwen/qwen3.8-27b`, `openai/gpt-oss-120b`, `openai/gpt-oss-20b`,
  `allam-2-7b`). Speech, transcription and guard models were hidden.
- `POST /chat/completions` with `stream: true` streamed content deltas and
  `[DONE]`; the final chunk carried token usage under `x_groq.usage`.
- On a real Android device, **Test key**, **Save key**, **Fetch models**, model
  selection, a streamed answer, the local history entry and a cache hit were all
  confirmed.

## 6. Chat, context and attachments

- Full conversations stream responses into the local database.
- The assistant rebuilds provider history from SQLite immediately before each
  request, so the transcript and context stay consistent.
- Contextual actions include explaining a guide, reviewing a command, generating a
  title, rewriting a description and translating English ↔ Myanmar.
- Supported attachments: `.txt`, `.md`, `.sh`, `.py`, `.log`.
- Maximum attachment size: 256 KB; one file per message.
- Only the leading 20,000 characters are placed in a prompt. The composer tells
  the user when truncation occurs.
- Attachment **contents** are not stored in AI history; only the file name is kept.
  The user must explicitly choose a file before its contents are sent.
- Do not attach secrets, private keys or sensitive logs.

## 7. Cache and history

**Cache**

- Keyed by a SHA-256 hash of provider ID, model, prompt version, messages and
  request parameters (temperature, max tokens).
- Different context or parameters cannot collide.
- Cache duration is configurable; zero disables it.
- Cache entries are local only and can be cleared independently.
- Responses are only reused when the key matches exactly.

**History**

- Stored locally in SQLite by default.
- Searchable; individual conversations can be deleted; all history can be cleared.
- Not synchronized to Firestore.
- Clearing history does not clear the response cache; both controls are separate.

## 8. Error handling

| Condition | App behavior |
| --- | --- |
| Invalid key / 401 | Shows an authentication error and keeps the key field editable |
| Rate limit / 429 | Shows a retryable rate-limit message |
| Server error / 5xx | Retryable provider error |
| Network/timeout | Retryable network/timeout message |
| Empty stream | Reported as an error, never displayed as a successful answer |
| AI disabled or key/model missing | Clear configuration error before any request |
| Oversized conversation | Rejected locally before calling the provider |

The app does not display raw API error bodies that could contain sensitive data.

## 9. Privacy and cost

- Requests go directly from the device to Groq. There is no proxy server in this
  project.
- Your Groq account is billed according to Groq's terms and usage.
- Only the current conversation, selected guide context and an explicitly chosen
  attachment are sent.
- History and cache stay on the device unless you clear them.
- Firebase receives no API key and no AI history.
- Do not use the assistant to send data you are not allowed to share with Groq.

## 10. Verification checklist

With a key configured:

1. Test a valid key and an invalid key.
2. Fetch models twice and confirm the list is cached, not re-fetched constantly.
3. Select a model, send a prompt, and confirm the answer streams.
4. Ask for an explanation from a command details screen.
5. Send a `.sh` file, confirm the size limit and truncation notice.
6. Send the same prompt twice; the second answer should come from the cache when
   caching is enabled.
7. Disable the cache and confirm a new request is made.
8. Clear history and confirm cache entries remain until cleared separately.
9. Revoke the key and confirm a clear authentication error.
