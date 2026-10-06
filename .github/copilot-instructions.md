# Copilot instructions: family care calendar

Project: shared family care calendar for 3 users, low traffic, personal Azure tenant.

## Working conventions
- One logical change per PR, with clear success criteria.
- Back up state before any destructive Terraform operation.
- If unsure about azurerm or azuread provider coverage, ask me. Do not guess.
- When a prompt references an existing repo with #githubRepo, inspect it first and
  match its Terraform module layout, variable and resource naming, remote state
  backend pattern, tagging, and GitHub Actions structure (triggers, job naming,
  secret handling). Flag any place you deliberately deviate and why.

## Identity and tenant
- Existing personal Entra ID and M365 tenant (not a work tenant).
- One sibling is already a native member. Two are invited as B2B guests, redeeming
  via Google, personal Microsoft account, or email one-time passcode (iCloud users).
- Guest invites and Enterprise App user assignment are done MANUALLY, outside
  Terraform. This avoids granting the CI/CD service principal broad Graph
  permissions.
- Terraform must NEVER manage azuread_invitation or azuread_app_role_assignment.
- Terraform DOES own azuread_application and azuread_service_principal with
  app_role_assignment_required = true.
- The 3 siblings' object IDs are Terraform input variables only.

## Architecture
- Frontend: Vite + React SPA (not Astro), FullCalendar with the Forma theme, PWA via
  vite-plugin-pwa. Hosted on Azure Static Web Apps, Standard plan. Build output: dist.
- Backend: separate standalone Azure Functions app (Consumption plan), linked as
  Bring-Your-Own Functions. NOT SWA Managed Functions, which lacks Managed Identity
  and Key Vault support. It has its own deploy workflow.
- Auth: Entra app registration and Enterprise App with assignment required. The CRUD
  API stays behind SWA's authenticated /api proxy.
- Managed Identity from Function App to Cosmos DB and Key Vault. No stored secrets
  or connection strings.
- Database: Cosmos DB, free tier, NoSQL API.
- Edge: my EXISTING Azure Front Door Standard profile. Do not create a new profile.
  Two routes:
  1. SWA app (authenticated).
  2. ICS feed routed DIRECT to the Function App, bypassing SWA. Anonymous auth level
     on ICS functions only. CRUD functions stay behind SWA's auth proxy.
- IaC: Terraform with azurerm (plus azuread), in ./terraform, remote state, TF_VAR_*
  variables sourced from 1Password via GitHub Actions.
- CI: GitHub-hosted runners only. No self-hosted runner, no local-network dependency.
- This is a new standalone repo. No shared state or workflow coupling with my homelab
  repo.

## Data model: sibling events
Colour is dynamic. It is assigned on first sign-in from a fixed palette (FullCalendar
theme colours if available), then persisted against the user's object ID. Use a
conditional or atomic Cosmos DB write so two near-simultaneous first sign-ins cannot
claim the same colour.
- Holiday: start/end date, UK or Abroad flag, optional location (text).
- Unavailable: start/end datetime, subject (text), body (text).

## Data model: mother events
Colour is fixed per type (4 colours, preselected in config), regardless of which
sibling logs the event.
- MedicalAppointment: quick-pick type (Doctor, Dentist, Hospital, etc.) plus free text.
- CarerVisit: supports a defined recurring schedule, materialized into instances.
- Social: friend visit, lunch, etc.
- Other: closed catch-all (gardener, maintenance, etc.).

## Rules
- Permissions: any of the 3 siblings can create, edit, or delete any event. No owner
  restriction.
- Concurrency: last-write-wins on live data.
- Audit: separate append-only audit log (who, what, when) written on every mutation.
- Retention: indefinite. No TTL or purge logic.
- Timezone: Europe/London throughout, handling BST and GMT correctly. No per-user
  timezone field in v1.

## Recurrence (CarerVisit)
- The schedule definition is the source of truth. The backend materializes individual
  stored instances. Do not store a raw RRULE and interpret it at read time.
- Schedule edits apply from a chosen point forward. Past instances are untouched.
- A one-off single-occurrence override must be possible without altering the series.
- On schedule change, re-materialize affected instances so stored events and the ICS
  feed stay in sync.

## ICS feed
- One high-entropy, unguessable token URL per sibling (3 distinct tokens). No auth.
- Token rotation invalidates the old URL.
- Default VALARM: 24h before for all-day or multi-day events, 2h before for timed
  events.
- Subscription link in the PWA uses the webcal:// scheme for native iOS and Android.

## Notifications
In-PWA activity view only. No push or email in v1.
