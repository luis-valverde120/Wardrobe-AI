import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      // El AppBar permite volver atrás automáticamente
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // <-- El secreto para que el teclado no rompa la UI
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. Título de la pantalla
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Wardrobe AI to digitize your closet.',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 40),

              // 2. Formulario Tradicional
              _buildInputField(
                label: 'Full Name',
                icon: Icons.person_outline,
                hintText: 'John Doe',
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Email',
                icon: Icons.email_outlined,
                hintText: 'hello@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                label: 'Password',
                icon: Icons.lock_outline,
                hintText: '••••••••',
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // 3. Botón de Registro Normal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                  ),
                  onPressed: () {
                    // Aquí llamaremos al UseCase de Registro en el futuro
                  },
                  child: const Text('Sign Up'),
                ),
              ),

              const SizedBox(height: 30),

              // 4. Divisor Visual (UX)
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.black12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or continue with',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.black12)),
                ],
              ),

              const SizedBox(height: 30),

              // 5. Botón de Google (Social Login)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    // Aquí llamaremos al SignInWithGoogleUseCase
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Usamos una imagen de red temporal para el logo de Google
                      Image.network(
                        'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Google',
                        style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 6. Redirección al Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navegar a la pantalla de Login
                      context.pushReplacement('/login');
                    },
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
              const SizedBox(height: 30), // Espacio extra al fondo
            ],
          ),
        ),
      ),
    );
  }

  // Componente reutilizable para los campos de texto
  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlack,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppTheme.textGrey, size: 22),
            // Si es contraseña, agregamos el ojito
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
