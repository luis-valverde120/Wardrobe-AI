import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/profile_provider.dart';

class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          profileAsync.when(
            data: (profile) {
              final avatarUrl = profile?['avatar_url'] as String?;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(avatarUrl, fit: BoxFit.cover)
                      : const Center(
                          child: Icon(Icons.person, size: 50, color: AppTheme.accentPurple),
                        ),
                ),
              );
            },
            loading: () => const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(color: AppTheme.accentPurple),
            ),
            error: (_, __) => const Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(height: 16),
          profileAsync.when(
            data: (profile) {
              final name = profile?['full_name'] ?? 'Guest';
              final bio = profile?['bio'];
              final email = Supabase.instance.client.auth.currentUser?.email ?? 'No email';
              return Column(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (bio != null && bio.toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Text('Error loading profile'),
          ),
        ],
      ),
    );
  }
}
