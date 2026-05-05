# MASTER AI CONTEXT: Project Echo (GU-WIMS)

## 1. System Architecture

- **Backend (Render):** Go 1.26 Monolith (Hexagonal). Must include a 14-minute interval self-pinging background goroutine. Uses `pgxpool` (max 20 conns) and a worker pool to safely handle load limits.
- **Database (Supabase):** PostgreSQL 17 + PostGIS 3.5. Strictly separated from the backend. Currently using UUIDv4, planned migration to UUIDv7.
- **Mobile (Flutter):** Riverpod state management (must use `StateNotifier` for compatibility with `flutter_riverpod` ^3.3.1 setup). Offloads heavy tasks to Dart Isolates. UI strictly enforces `useMaterial3: true`.

## 2. Authentication Flow (Custom)

- Students authenticate via Roll Number and bcrypt-hashed PIN. Admins/Workers use similar credentials.
- Go API issues 15-minute JWT Access Tokens and 6-month HttpOnly Secure Refresh Tokens.
- **Workforce Pipeline:** Specialized queues assign tasks directly to specific departments (`ELECTRICIAN`, `SANITATION_WORKER`).
- **Admin Pipeline:** Admins have global visibility, override capability, and User Management controls including single-user creation and bulk CSV import mechanisms.

## 3. Security Mandates

- **BOLA Prevention:** All DB queries must verify object ownership via `reporter_id` or `Role`. Students ONLY see their own reports.
- **Payload Limits:** Backend endpoints capped at 5MB via `http.MaxBytesReader`.
- **File Integrity:** Backend uses `http.DetectContentType` (Magic Bytes) on the first 512 bytes of images.
- **EXIF Preservation:** Flutter MUST NOT strip EXIF data during image compression.

**Directive:** Generate production-grade, tightly-scoped code. Follow the specific `/backend` and `/mobile` personas located in their respective directories.
