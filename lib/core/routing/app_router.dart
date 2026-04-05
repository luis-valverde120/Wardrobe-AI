import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/main_layout.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/closet/presentation/pages/add_clothing_page.dart';

// Configuramos nuestro enrutador global
final goRouter = GoRouter(
  initialLocation: '/', // La ruta con la que arranca la app
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    
    // Rutas protegidas vs públicas
    final isAuthRoute = state.matchedLocation == '/' || 
                        state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';

    if (isLoggedIn && isAuthRoute) {
      return '/home'; // Si ya está logueado, directo a home
    }
    
    if (!isLoggedIn && !isAuthRoute) {
      return '/'; // Si intenta entrar a una pantalla privada, kick al welcome
    }

    return null; // Todo correcto, dejar pasar
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const MainLayout()),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/add-clothing',
      builder: (context, state) => const AddClothingPage(),
    ),
  ],
);
