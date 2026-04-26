# Wardrobe-AI 👚🤖

**Wardrobe-AI** is a cutting-edge cross-platform mobile application engineered to digitize, organize, and optimize personal wardrobe usage through Artificial Intelligence. By streamlining the daily dressing process, it aims to eliminate decision fatigue while subconsciously promoting a circular textile economy.

---

## 🛠️ Technology Stack & Architecture

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod (Leveraging `AsyncNotifierProvider` for robust asynchronous state handling).
- **Backend / BaaS:** Supabase (PostgreSQL, Auth, and Storage for optimized image buffer management).
- **AI Integration:** fal.ai (Harnessing generative diffusion models for real-time virtual try-on inference).
- **Routing:** GoRouter (Declarative Routing for deep-link support).
- **Design System:** Material 3 (Custom dynamic color implementation with persistent theme state).

---

## 🏗️ Architecture Design

We enforce a strict **Clean Architecture (Feature-First)** structure. This ensures each domain of the application operates independently, minimizing coupling and maximizing scalability.

### Folder Structure
The codebase resides under `lib/` and divides into two main areas:
```
lib/
 ┣ core/                     # Shared utilities, router, and design tokens
 ┃ ┣ router/app_router.dart  # GoRouter configuration
 ┃ ┗ theme/app_theme.dart    # Global Material Design configuration (Colors, Dark Mode)
 ┃
 ┗ features/                 # Modular feature-first packages
   ┣ auth/                   # Authentication & User Sessions
   ┣ home/                   # Main Layout, Navigation Bar, and Dashboard
   ┣ profile/                # Profile editing, App Settings, Log out
   ┗ closet/                 # The core Digital Wardrobe (Clothing items)
```

Each **Feature** is internally isolated with its own:
- `/data`: Repositories (communication with Supabase) and Models.
- `/presentation`: UI Views (`pages/`, `widgets/`) and State Logic (`providers/`).

---

## 📊 Data Management & Riverpod

The application follows an **Unidirectional Data Flow**:
1. **Providers (`StateNotifier` / `AsyncNotifier`)**: Serve as the Single Source of Truth linking the UI with the Repositories.
2. **UI (`ConsumerWidget`)**: Listens to changes globally without needing `setState()`.
3. **Repository**: Executes HTTP bindings securely using the injected `SupabaseClient`.

We utilize Riverpod's native `<AsyncValue>` capabilities to effortlessly handle `loading`, `data`, and `error` states on the UI layers, preventing crashes and blank screens during network fetching.

---

## 💾 API Contract & Database Schema

The backend architecture consists of a public PostgreSQL Database governed strictly by **Row Level Security (RLS)** to protect user data. 

### 1. `profiles` Table
Automatically instantiated when a user signs up via Supabase Auth (Trigger-based).
| Column Name  | Type        | Nullable | Description                                  |
|--------------|-------------|----------|----------------------------------------------|
| `id`         | `uuid`      | `false`  | Primary Key (References `auth.users`)        |
| `full_name`  | `text`      | `false`  | User's Display Name                          |
| `avatar_url` | `text`      | `true`   | Supabase Storage Public URL for avatar       |
| `bio`        | `text`      | `true`   | User biography or style description          |
| `gender`     | `text`      | `true`   | Gender Identity for AI demographic contexts  |
| `birthday`   | `text`      | `true`   | ISO-8601 String to calculate age dynamically |
| `created_at` | `timestamptz`| `false` | Registration Timestamp                       |

### 2. `clothes` Table
The primary entity holding the physical garments uploaded to the cloud.
| Column Name  | Type        | Nullable | Description                                  |
|--------------|-------------|----------|----------------------------------------------|
| `id`         | `uuid`      | `false`  | Primary Key                                  |
| `user_id`    | `uuid`      | `false`  | Owner ID (References `auth.users`)           |
| `title`      | `text`      | `false`  | Given name to the garment (e.g. Red Shirt)   |
| `category`   | `text`      | `false`  | Garment type (Tops, Bottoms, Shoes, etc)     |
| `color`      | `text`      | `true`   | Primary visually-detected color              |
| `image_url`  | `text`      | `false`  | Supabase Storage Public URL for garment      |
| `created_at` | `timestamptz`| `false` | Upload timestamp                             |

---

## 🌎 Global Routing Map (`app_router.dart`)

- **Public Routes:**
  - `/` : `WelcomePage` (Entry point with Sign In / Register gateway).
  - `/login` : `LoginPage` (Email authentication).
  - `/register` : `RegisterPage` (Secure account creation).
- **Protected Routes (Require Auth Session):**
  - `/home` : `MainLayout` (Dashboard rendering the Closet Grid).
  - `/edit-profile` : `EditProfilePage` (Avatar upload, Bio, Birthday, Gender configuration).
  - `/add-clothing` : `AddClothingPage` (Camera execution to upload and tag new clothes to storage).