import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: authState.isLoading
            ? const SizedBox(
                width: 20, height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)
              )
            : const Icon(Icons.logout),
        label: Text(
          authState.isLoading ? 'Saliendo...' : 'Log Out',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: authState.isLoading
            ? null
            : () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/');
                }
              },
      ),
    );
  }
}
