import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

// Configuramos nuestro enrutador global
final goRouter = GoRouter(
  initialLocation: '/', // La ruta con la que arranca la app
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    // Aquí agregaremos el '/home' más adelante
  ],
);
