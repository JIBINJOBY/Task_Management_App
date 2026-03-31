# Task Management App (Flodo AI Assignment)

A polished local-first Task Management Flutter app built for **Track B (Mobile Specialist)**.

## Features

- Full CRUD for tasks
- Required model fields: Title, Description, Due Date, Status, Blocked By (optional)
- Blocked task visual state until dependency task is marked Done
- Search by title
- Status filter (All / To-Do / In Progress / Done)
- Draft persistence on create form
- 2-second simulated delay for Create/Update with non-blocking UI and disabled Save button
- Stretch Goal: Debounced search (300ms) + highlighted title match

## Tech Stack

- Flutter + Dart
- Hive (local persistence)
- Riverpod (state management)
- intl, uuid

## Architecture

- `presentation/` - UI screens and widgets
- `presentation/providers/` - Riverpod state and business flow
- `data/models/` - Task and Draft models
- `data/services/` - Hive init + boxes
- `data/repositories/` - persistence abstraction

## Setup

1. Install Flutter SDK (stable)
2. Enable Windows Developer Mode (required for plugin symlinks):
   - Run: `start ms-settings:developers`
   - Turn on **Developer Mode**
3. Get dependencies:
   - `flutter pub get`
4. Run app:
   - `flutter run`

## Stretch Goal Chosen

- **Debounced autocomplete-like search** with title match highlighting.

## AI Usage Report

- AI was used to accelerate architecture scaffolding, state management wiring, and UI component generation.
- The output was manually validated and adjusted for requirement alignment.
- One correction applied: refined loading behavior to ensure Save is disabled during the 2-second async create/update window.
