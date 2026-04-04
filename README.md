# Wardrobe-AI
Wardrobe-AI is a cross-platform mobile application designed to digitize, organize, and optimize personal wardrobe usage through Artificial Intelligence. The platform solves daily dressing decision fatigue and combats textile waste by promoting the circular economy.

An AI-powered digital closet management mobile application.

## 🏗️ Architecture
The project follows a **Clean Architecture** approach structured by layers (Feature-First) to ensure high cohesion and low coupling:
- **Presentation:** UI and reactive state management (`Riverpod`).
- **Domain:** Pure business logic and contracts (Use Cases, Entities).
- **Data:** Repository implementations, API consumption, and Local Cache (`Offline-First`).

## 🗺️ Routing Map (GoRouter)
- `/` : `WelcomePage` (Splash & entry decision).
- `/login` : `LoginPage` (Existing user authentication).
- `/register` : `RegisterPage` (New account creation).
- `/home` *(In Progress)*: Main dashboard and wardrobe grid.