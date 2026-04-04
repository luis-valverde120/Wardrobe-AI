import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryBlack),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. Título de bienvenida
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to access your digital closet.',
                style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 40),

              // 2. Formulario de Login
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

              // 3. Recuperar contraseña (Alineado a la derecha)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 0,
                    ),
                  ),
                  onPressed: () {
                    // Lógica para recuperar contraseña
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppTheme.accentPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 4. Botón de Login Normal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                  ),
                  onPressed: () {
                    // Llamar al UseCase de Login con Email
                  },
                  child: const Text('Sign In'),
                ),
              ),

              const SizedBox(height: 30),

              // 5. Divisor Visual
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

              // 6. Botón de Google
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
                    // Llamar al SignInWithGoogleUseCase
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

              // 7. Redirección al Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navegar a la pantalla de Registro
                      context.pushReplacement('/register');
                    },
                    child: const Text(
                      'Sign Up',
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

  // Mismo componente reutilizable para mantener la consistencia
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
