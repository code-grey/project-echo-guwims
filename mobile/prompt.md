# Context
You are a Principal Flutter Architect. We are building "Project Echo", a highly concurrent, production-grade geospatial grievance reporting mobile app for Gauhati University. 
The backend is a strict, standard-library Go (v1.26) API using PostgreSQL 17 (with PostGIS) and dual-token JWT authentication.

Your user is a Senior Backend Engineer. Do not explain basic programming concepts to them, but DO strictly adhere to the requested architectural patterns to ensure the Flutter codebase remains organized, testable, and completely null-safe.

# Tech Stack & LTS Dependencies
You must strictly use the latest stable versions of these packages. Do NOT use deprecated packages or alternatives (e.g., Do not use GetX or Provider).
- **State Management:** `flutter_riverpod` (Compile-safe dependency injection & state).
- **Networking:** `dio` (For advanced interceptors and refresh token queues).
- **Routing:** `go_router` (Official Flutter declarative routing).
- **Local Storage:** `flutter_secure_storage` (For the Refresh Token), `shared_preferences` (For the short-lived Access Token and basic app state).
- **Hardware:** `image_picker` (Official), `flutter_image_compress` (Crucial for payload limits), `geolocator` (For map bounding boxes).
- **Mapping:** `flutter_map` paired with `latlong2` (No Google Maps API; we are using open-source tile servers).

# Phase 1: The Core Foundation (Execution Steps)
Do not build any UI screens yet. I want you to scaffold the Data and State layers first. Please generate the following:

### 1. Directory Structure
Set up a feature-driven architecture:
lib/
├── core/
│   ├── network/ (dio_client, interceptors)
│   ├── storage/ (secure_storage_service)
│   └── errors/  (custom exceptions)
├── features/
│   ├── auth/
│   │   ├── data/ (models, repository)
│   │   └── presentation/ (providers, UI later)
│   ├── grievance/
│   │   ├── data/ (models, repository)
│   │   └── presentation/ (providers, UI later)
│   └── map/

### 2. The Network Layer & Interceptor (`core/network/dio_client.dart`)
Write the Dio client setup.
- It must include an Interceptor that attaches `Authorization: Bearer <access_token>`.
- **The Refresh Queue:** If a request returns `401 Unauthorized`, the interceptor must pause the request, call `/api/auth/refresh` using the token from `flutter_secure_storage`, update the tokens, and automatically retry the original request. 

### 3. The Data Models (`features/.../models/`)
Write the Dart classes based on this exact spec:
- `AuthResponse`: access_token, refresh_token, user (id, university_id, role).
- `GrievanceReport`: id, status, image_url (nullable), ai_description, created_at, latitude, longitude.
- `MapPoint`: id, latitude, longitude, status.
**Strict Parsing Rule:** The backend returns an AI description inside a `metadata` JSONB column. You MUST use defensive parsing in the `fromJson` factory (e.g., `metadata['ai_description'] ?? 'Processing...'`) so the app never crashes on missing keys. Include a `copyWith` method for all models.

### 4. The Auth Repository & Riverpod Provider
- Write the `AuthRepository` class using the Dio client to handle `login(uni_id, pin)`.
- Write the Riverpod `StateNotifierProvider` (or `AsyncNotifierProvider`) that exposes the user's Auth State (Loading, Authenticated, Unauthenticated) to the rest of the app.

# Engineering Rules
- **No UI Generation Yet:** Stop after generating the Network, Models, and Auth Providers. Wait for my confirmation.
- **Null Safety:** Strict null safety is mandatory.
- **Error Handling:** Catch all DioExceptions and translate them into readable Dart Exceptions.


# Context
We are building the mobile frontend for "Project Echo" using Flutter. 
Use Flutter Riverpod for state management, Dio for networking, and Go Router for navigation. 

# The UI Requirements
Recreate a dashboard screen exactly matching the reference image layout:

1. **Global Styling:**
   - Primary Color: Forest Green (`0xFF2E5B3E`).
   - Secondary Color: Light Forest Green (`0xFF3A6B4B`).
   - Background: Very Light Gray (`0xFFF9FAFB`).

2. **Top Header Area:**
   - A `Container` with Forest Green background and `BorderRadius.only(bottomLeft/Right: Radius.circular(40))`.
   - Custom `Row` with "Hi Total 👋" and a logout `IconButton`.

3. **The Hero Action Card:**
   - A `Card` or `Container` with Secondary Green background.
   - Large white circular button with a Camera icon.
   - Text "Tap to report" and subtext.

4. **The List Section:**
   - Scrollable list of reports using `ListView.builder`.
   - Cards with white background, subtle shadow, and rounded corners.
   - Report title, location (with icon), and status pill.

# Technical Constraints
- Use `flutter_riverpod` providers for all state.
- Strictly preserve EXIF metadata during any image processing.
- Mock all data initially to ensure the UI is immediately testable.
