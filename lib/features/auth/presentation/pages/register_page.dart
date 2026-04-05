import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // Controladores para atrapar el texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Buena práctica de ingeniería: limpiar memoria al salir
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el estado de autenticación para saber si está cargando
    final authState = ref.watch(authNotifierProvider);

    // Escuchamos CAMBIOS en el estado para mostrar errores o navegar al Home
    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      next.when(
        data: (_) {
          // Si el registro fue exitoso y el estado anterior era "loading", navegamos al Home
          if (previous is AsyncLoading) {
            context.go('/home');
          }
        },
        error: (error, stack) {
          // Mostrar mensaje de error (ej. contraseña muy corta)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Wardrobe AI to digitize your closet.',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 40),

              // Formularios conectados a los controladores
              _buildInputField(
                label: 'Full Name',
                icon: Icons.person_outline,
                hintText: 'John Doe',
                controller: _nameController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Email',
                icon: Icons.email_outlined,
                hintText: 'hello@example.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Password',
                icon: Icons.lock_outline,
                hintText: '••••••••',
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 30),

              // Botón de Registro con indicador de carga
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          // Verificamos que no envíen campos vacíos
                          if (_nameController.text.isEmpty ||
                              _emailController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                            return;
                          }
                          // Ejecutamos la función de registro
                          ref
                              .read(authNotifierProvider.notifier)
                              .signUp(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                                _nameController.text.trim(),
                              );
                        },
                  // Cambiamos el texto por un spinner si está cargando
                  child: authState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up'),
                ),
              ),
              // ... Aquí iría el resto del código del botón de Google y la redirección al Login (puedes dejar el que ya tenías)
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => context.pushReplacement('/login'),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppTheme.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hintText,
    required TextEditingController controller, // <-- Añadido el controlador
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller, // <-- Conectado al TextField
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 22),
            suffixIcon: isPassword
                ? const Icon(
                    Icons.visibility_off_outlined,
                    color: AppTheme.textGrey,
                    size: 22,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
