# MASTER AI CONTEXT: Project Echo (GU-WIMS)

## 1. System Architecture

- **Backend (Render):** Go 1.26 Monolith (Hexagonal). Must include a 14-minute interval self-pinging background goroutine.
- **Database (Supabase):** PostgreSQL 17 + PostGIS 3.5. Strictly separated from the backend to prevent ephemeral disk data loss.
- **Mobile (Flutter):** Riverpod state management. Offloads heavy tasks to Dart Isolates.

## 2. Authentication Flow (Custom)

- Students authenticate via Roll Number and bcrypt-hashed PIN.
- Go API issues 15-minute JWT Access Tokens and 6-month HttpOnly Secure Refresh Tokens.

## 3. Security Mandates

- **BOLA Prevention:** All DB queries must verify object ownership via `reporter_id` or `Role`.
- **Payload Limits:** Backend endpoints capped at 5MB via `http.MaxBytesReader`.
- **File Integrity:** Backend uses `http.DetectContentType` (Magic Bytes) on the first 512 bytes of images.
- **EXIF Preservation:** Flutter MUST NOT strip EXIF data during image compression.

**Directive:** Generate production-grade, tightly-scoped code. Follow the specific `/backend` and `/mobile` personas located in their respective directories.
