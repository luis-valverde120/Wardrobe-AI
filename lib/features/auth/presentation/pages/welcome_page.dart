import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // Variables para controlar el inicio de las animaciones
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Iniciamos la animación 100ms después de que carga la pantalla
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _animate = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usamos MediaQuery para que el diseño se adapte a cualquier tamaño de pantalla
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo decorativo minimalista (Un degradado sutil azul)
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: AnimatedOpacity(
              duration: const Duration(seconds: 2),
              opacity: _animate ? 0.05 : 0,
              child: Container(
                height: size.height * 0.5,
                width: size.height * 0.5,
                decoration: const BoxDecoration(
                  color: AppTheme.accentPurple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // 2. Contenido Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),

                  // 3. LOGO (Animación de opacidad y posición)
                  AnimatedAnimatedElement(
                    animate: _animate,
                    delayMilliseconds: 100,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPurple.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        // Reemplaza esto con tu logo real (.png o .svg)
                        child: const Icon(
                          Icons.checkroom_rounded,
                          size: 80,
                          color: AppTheme.accentPurple,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. TÍTULO Y SUBTÍTULO
                  AnimatedAnimatedElement(
                    animate: _animate,
                    delayMilliseconds: 300,
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            text: 'Elevate Your Style\nwith ',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlack,
                              height: 1.2,
                            ),
                            children: [
                              TextSpan(
                                text: 'Wardrobe AI',
                                style: TextStyle(color: AppTheme.accentPurple),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your personalized digital closet assistant.\nOrganize, plan, and discover outfits instantly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textGrey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 5. BOTONES DE ACCIÓN (LOGIN Y REGISTRO)
                  AnimatedAnimatedElement(
                    animate: _animate,
                    delayMilliseconds: 500,
                    child: Column(
                      children: [
                        // Botón de Registro (Elevated - Azul)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPurple,
                            ),
                            onPressed: () {
                              // Navegar a Registro
                              context.push('/register');
                            },
                            child: const Text('Create Account'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botón de Login (TextButton - Minimalista)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                            onPressed: () {
                              // Navegar a Login
                              context.push('/login');
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppTheme.primaryBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar para manejar las animaciones de entrada
class AnimatedAnimatedElement extends StatelessWidget {
  final bool animate;
  final int delayMilliseconds;
  final Widget child;

  const AnimatedAnimatedElement({
    super.key,
    required this.animate,
    required this.delayMilliseconds,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      // Retrasamos el inicio de la opacidad
      opacity: animate ? 1 : 0,
      curve: Curves.easeOut,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        // Retrasamos el inicio del movimiento (de abajo hacia arriba)
        padding: animate
            ? EdgeInsets.zero
            : const EdgeInsets.only(top: 30), // Empieza 30px abajo
        child: child,
      ),
    );
  }
}
