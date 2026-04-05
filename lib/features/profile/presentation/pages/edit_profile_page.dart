import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Leer los datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      if (profile != null && profile['full_name'] != null) {
        _nameController.text = profile['full_name'];
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    await ref.read(editProfileNotifierProvider.notifier).updateName(newName);
    
    // Si no hubo error, regresar
    if (mounted && !ref.read(editProfileNotifierProvider).hasError) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: AppTheme.textGrey),
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.accentPurple),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              
              if (editState.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  editState.error.toString(),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              
              const Spacer(),
              ElevatedButton(
                onPressed: editState.isLoading ? null : _saveProfile,
                child: editState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
