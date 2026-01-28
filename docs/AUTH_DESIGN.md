# Design: Login and security in the app

## Requirements

1. **App login** – one or both of:
   - **Username + password** – server validates against local SQLite DB.
   - **Google account** – sign in with Google Sign-In; server accepts Google ID token and creates/links user.

2. **Device password** – stored **securely** on device (not in plain JSON):
   - Use **flutter_secure_storage** (or similar) for session token / credentials.
   - On app launch – if a valid token exists in secure storage, user stays "logged in" without re-entering password.

3. **On delete / dangerous actions** – additional confirmation required:
   - **Biometrics** (fingerprint, face) – via **local_auth**.
   - Or **PIN** – set by user in settings; for "Delete all", "Empty trash", bulk "Move to Trash" – show biometric or PIN entry screen first.

---

## Components

### Server (sync_server)

- **SQLite DB** – `users` table (username, password_hash).
- **POST /auth/login** – `{ "User": "", "Password": "" }` → on success returns `{ "Token": "..." }` (JWT or random token stored in DB).
- **POST /auth/register** – creates user (optional, if registration is enabled).
- **Dangerous endpoints** (`/delete-all`, `/empty-trash`) – require `Authorization: Bearer <token>` header or password in body; server verifies token/password before execution.
- **POST /auth/google** (phase 2) – accepts Google ID token, validates it, creates/returns session token.

### Client (sync_client)

- **Secure storage** – `flutter_secure_storage` for:
  - `auth_token` – after successful login/Google sign-in.
  - Optionally: do not store password in plain text in DeviceSettings; token only.
- **Login screen** – current (email + password) + "Sign in with Google" button (phase 2).
  - On successful login – store token in secure storage and state (currentUser + token).
- **On startup** – read token from secure storage; if valid token → auto login (no login screen).
- **API requests** – all requests to server include `Authorization: Bearer <token>` (when token exists).
- **Dangerous actions** – before calling `apiDeleteAllFiles` / `apiEmptyTrash` / bulk "Move to Trash":
  - Show dialog: "Confirm with biometrics or PIN".
  - **local_auth**: `authenticate()` – on success proceed with request.
  - If biometrics unavailable or user chooses PIN – show PIN entry screen (PIN stored in secure storage when first set in settings).

### PIN

- In **Settings / Account** – option "Set PIN for delete confirmation".
- PIN stored only in **secure storage** (hashed or encrypted).
- On first "Delete all" / "Empty trash" – if no PIN set, prompt user to set PIN or use biometrics only.

---

## Implementation phases

| Phase | Description |
|-------|-------------|
| **1** | Server: SQLite auth DB + `/auth/login` + protect `/delete-all` and `/empty-trash` with password or token. Client: store token in secure storage, send in requests; before delete/empty-trash – require biometrics (local_auth). |
| **2** | Client: PIN option in settings; for dangerous actions – biometrics or PIN entry. |
| **3** | Google sign-in: button on login screen, `google_sign_in`, server endpoint `/auth/google`. |
| **4** | Remove password from DeviceSettings (plain text); token only in secure storage. |

This document describes the overall design; concrete implementation follows these phases.
