# Durability iOS App – Technical Architecture Breakdown

## Table of Contents
- Overview
- High-Level Architecture
- App Composition and Flow
- Data Models and Persistence Shape
- Services Layer (Networking, Auth, Storage, Domain)
- Supabase Usage and Data Access
- Movement Library Implementation
- Assessment and Results Pipeline
- Plans and Workouts
- Health Integration (HealthKit)
- Error Handling and Resilience
- UI/UX Layering and Theming
- Security, Privacy, and RLS Considerations
- Current Risks and Gaps
- Near-Term Improvements (1–2 sprints)
- Medium-Term Evolution (Quarter)
- Long-Term Architecture Options

---

## Overview
The Durability app is a SwiftUI-based iOS application that authenticates users, onboards profiles, integrates with HealthKit, executes a movement assessment flow with video capture and storage, and provides analytics, progress tracking, and a movement library. Supabase is used as the backend for authentication, database, and storage.

Key capabilities:
- Authentication: Sign in with Apple via Supabase Auth
- Profile: Create, view, and update user profiles
- Health: HealthKit authorization and selective data sync into profiles
- Assessment: Record a multi-step movement assessment, persist assessment records/results, and show results
- Plans: Generate and read multi-week training plans, phases, daily workouts, and movement assignments
- Progress & Analytics: Simple analytics and progress dashboards derived from assessment results
- Movement Library: Browse movements from the backend and view detail pages, with long-form content
- Storage: Upload private assessment videos and training plan images (signed URL access)

---

## High-Level Architecture
- Pattern: MVVM with a single global `AppState` driving flow; feature-level ViewModels and Services
- UI Layer: SwiftUI views and view models
- Domain/Service Layer: Thin domain services per slice (Auth, Profile, Assessment, Plan, Storage, Movement Library, Network)
- Data Access: Supabase client for PostgREST, Auth, and Storage
- Platform Integrations: HealthKit for health data; UIKit appearance for theming

Key modules/files:
- Global State: `AppState`
- Services: `AuthService`, `ProfileService`, `AssessmentService`, `PlanService`, `StorageService`, `MovementLibraryService`, `NetworkService`
- Views/VMs: Authentication, Onboarding, Assessment flow, Main tab views (Plan, Today, Progress), Movement library, Profile, Analytics
- Models: `UserProfile`, `Assessment`, `AssessmentResult`, `Plan`, `PlanPhase`, `DailyWorkout`, `DailyWorkoutMovement`, `Movement`

---

## App Composition and Flow
- `DurabilityApp` bootstraps SwiftUI, sets global UIKit appearance, and injects `AppState`.
- `AppState` determines navigation flow via `appFlowState` (loading, unauthenticated, onboarding, assessment, assessmentResults, mainApp).
- `ContentView` displays the appropriate stack based on `appFlowState`.
- `MainTabView` provides three tabs: Plan, Today, Progress. A sheet exposes Profile & Settings.

Flow overview:
1. App launches → `AppState.init` restores session (Supabase) → loads profile → sets `appFlowState`.
2. If new user → Onboarding flow (profile details, equipment/injury/sports/goals).
3. If assessment not completed → Assessment flow with camera; results persisted and shown.
4. Main app: Plan/Today/Progress tabs; Movement library view is accessible from main (as separate screen/module).

---

## Data Models and Persistence Shape
Swift models (selected):
- `UserProfile`: Name, age, sex, anthropometrics, flags (onboarding/assessment), training plan info/img URLs, created/updated
- `Assessment`: `assessment_id` (int PK), `profile_id` (uuid string), optional `video_url`, `created_at`
- `AssessmentResult`: Auto id, `assessment_id` (int), `profile_id` (uuid string), `body_area`, and score components
- `Movement`: `id` (Int), `name`, optional `description`/`video_url`, arrays for impacted areas/tags, module impact scores
- Plans: `Plan`, `PlanPhase`, `DailyWorkout`, `DailyWorkoutMovement` with statuses and intensities

Notes:
- Dates are a mix of ISO-8601 strings from Supabase and native `Date` on the client; custom coding keys implemented where necessary.
- Weight conversions (kg↔lbs) and height conversions handled inside models/view models.

---

## Services Layer (Networking, Auth, Storage, Domain)
- `NetworkService`
  - Monitors connectivity via `NWPathMonitor` and exposes `isConnected`
  - Provides `performWithRetry` with exponential backoff for recoverable errors (timeout, connection issues)
- `AuthService`
  - Sign in/out, session restore; Sign in with Apple handled by `ASAuthorizationAppleIDCredential` tokens forwarded to Supabase
  - Upon Apple sign-in, optionally creates a basic `profiles` record
- `ProfileService`
  - CRUD for `profiles`; mapping structs for precise column names and date handling
  - Reference data fetchers for equipment, injuries, sports, goals; user selection save/load methods
- `AssessmentService`
  - Create assessment records (with or without video), upload video to private bucket via `StorageService`
  - Create/update/fetch assessment results; get latest assessment; signed video URL retrieval
- `PlanService`
  - Generate logical plans/phases/workouts in DB; query user’s current plan; update movement/workout statuses; aggregate counts
- `StorageService`
  - Upload image/video to private storage buckets; create signed URLs; delete paths
- `MovementLibraryService`
  - Fetch movements from `public.movements` (currently selecting `id`, `name`, `default_module_impact_vector`)
  - Fetch long description from `public.movement_content` by movement name (fallback to `movement_name` column if schema differs)

Concurrency:
- Most services marked `@MainActor`. This simplifies usage but mixes UI and IO on main actor. Consider removing `@MainActor` from network-bound services and returning to the main actor only when updating UI state.

---

## Supabase Usage and Data Access
- Auth: OpenID Connect with Apple via Supabase Auth
- Database: PostgREST access with fluent query builder
- Storage: Private buckets
- API/Schema considerations:
  - The app previously attempted to read `library.movements` or a `movement_library` adapter view; now targets `public.movements`
  - RLS must allow select/insert/update for the authenticated user as appropriate (profiles, assessments, assessment_results, plans, etc.)
  - Some services (Profile/Assessment) already use `NetworkService.performWithRetry`; others (MovementLibrary) do not yet

---

## Movement Library Implementation
- List: `MovementLibraryViewModel.fetch()` loads movements from `public.movements` via `MovementLibraryService`, shows a grid.
- Detail: `MovementDetailView` shows
  - Title
  - Video placeholder (player hookup pending)
  - Description sourced from `public.movement_content.long_description` (via service), falling back to `movement.description`
  - Horizontal chips: joints, muscles, super metrics, sports
  - Module scores: Recovery, Resilience, Results

Data retrieval notes:
- `MovementLibraryService` maps `default_module_impact_vector` keys (recovery, resilience, results) to module scores
- It hashes string UUIDs into Int IDs (deterministic) to fit the `Movement.id` Int requirement. Small, but non-zero risk of hash collision; consider switching `Movement.id` to String (UUID) app-wide.

---

## Assessment and Results Pipeline
- Creation path:
  1. Optional video upload to private bucket → returns storage path
  2. Insert into `assessments` (DB generates `assessment_id` int)
  3. Generate and insert `assessment_results` (Overall + body areas)
- Results and history:
  - Fetch latest assessment and results
  - Results power analytics and progress history (including super-metric visualizations)
- Retake behavior:
  - Always create a new assessment record (history preserved)
  - On first completion, set `assessment_completed = true` on profile

---

## Plans and Workouts
- Plan generation: Creates 3 phases × ~14 days each; inserts phases, workouts, and attached movements
- Plan reading: `getCurrentPlan` loads phases, workouts, and movement assignments; Today/Plan views consume it
- Status updates: movement and workout statuses can be updated independently

---

## Health Integration (HealthKit)
- Authorization: Reads steps, energy, heart rate, height, weight, DOB, sex; writes none (unless expanded)
- Sync: After authorization, fetches today’s stats; optionally upserts height/weight/DOB/sex into `profiles`
- Resilience: Attempts reauthorization for certain denied types and retries after short delays

---

## Error Handling and Resilience
- Central handler `ErrorHandler` maps Supabase errors to user-friendly messages
- `NetworkService.performWithRetry` wraps many DB calls with configurable backoff
- Areas for improvement:
  - Apply retry wrapper consistently (Movement library currently bypasses it)
  - Add structured error categories to more UI surfaces for better UX

---

## UI/UX Layering and Theming
- SwiftUI-first UI with UIKit appearance configuration for NavigationBar/TabBar
- Global dark theme palette (Dark/Light Greys + Electric Green accent)
- Consistent componentization for cards, chips, progress bars, and charts in Progress/Analytics views

---

## Security, Privacy, and RLS Considerations
- Storage buckets are private; access via signed URLs only (time-limited)
- RLS policies on all tables must be verified to ensure:
  - Users can only read/write their own profiles, assessments, plan artifacts, selections
  - Anonymous/unauthorized access is denied
- Avoid placing credentials in code; `Config` should be provided via secure means at build time

---

## Current Risks and Gaps
- ID Strategy: Hashing UUID→Int for `Movement.id` can collide; recommend using String IDs or a server-side stable int surrogate
- Schema Drift: Differences between historic `library.` schema / `movement_library` view and current `public.movements`/`movement_content`
- Inconsistent Retries: Some services use `NetworkService.performWithRetry`, others don’t
- `@MainActor` overuse: IO work on main actor may impact responsiveness on slow networks
- Missing Filtering: Movement filters (sport/equipment/mobility/strength) are placeholders without backend-driven filter logic
- Video: Detail screen uses placeholder; player integration is pending (signed URL fetch + AVPlayer)
- Local Caching: No offline-first cache; every page load depends on network availability

---

## Near-Term Improvements (1–2 sprints)
- Movement Library
  - Switch `Movement.id` to `String` (UUID) across the app to eliminate hashing risk
  - Add filter parameters (e.g., `sport`, `equipment`) to service and implement UI chips backed by real data
  - Integrate video playback via signed URL + `AVPlayer`
- Consistent Retry
  - Wrap MovementLibrary queries with `performWithRetry`
  - Add lightweight circuit breaker (skip immediate retry when `noConnection`)
- UX Polish
  - Loading/error states for movement detail long-description
  - Skeletons/placeholders for grids and charts
- CI Hygiene
  - Add basic unit tests for services’ mapping and error paths
  - Linting and Swift format checks in CI

---

## Medium-Term Evolution (Quarter)
- Offline & Caching
  - Introduce local persistence for profile and movement library (SQLite or SwiftData)
  - Cache signed URLs for a short TTL and prefetch thumbnails
- Schema & API
  - Stabilize movement data contract (name, tags, vectors, content) and publish a small typed client
  - Consider GraphQL or RPCs for composing joins server-side (reduce client over-fetching)
- Observability
  - Add lightweight analytics/telemetry (performance metrics, error rates, retry counts)
- Health & Plans
  - Bidirectional syncing with HealthKit (optional), and plan adherence tracking (write workouts)
  - Personalization: movement selection based on injuries, goals, and recent assessment deltas

---

## Long-Term Architecture Options
- Feature Modules & Clean Architecture
  - Split by features: Auth, Profile, Assessment, Movement Library, Plans, Analytics
  - Domain layer with use-cases; infra adapters for Supabase; dependency inversion for testability
- Strongly-Typed Data Access
  - Code-generation from Supabase schema to Swift types (reduce mapping errors)
  - Migrate to string/UUID IDs where appropriate and remove client-side hashing
- Background Workflows
  - Background refresh tasks for profile, plan, and health data with smarter caching
- Advanced Personalization
  - Scoring service (Edge Function) for movement/program recommendations using assessment vectors

---

## Summary
The app is structured with a pragmatic MVVM + services approach that cleanly separates UI and backend concerns, already leveraging Supabase Auth, DB, and Storage effectively. The largest payoffs now come from stabilizing the movement data contract, eliminating ID hashing, applying consistent retry/caching strategies, and enriching the movement library experience (filters, content, video). These steps improve robustness today and set a foundation for modularization, typed access, and more intelligent planning in the future.
