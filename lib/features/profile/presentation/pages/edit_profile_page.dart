import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _selectedImage;
  String? _currentAvatarUrl;
  
  String? _selectedGender;
  DateTime? _selectedBirthday;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        _nameController.text = profile['full_name'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        setState(() {
          _currentAvatarUrl = profile['avatar_url'];
          _selectedGender = profile['gender'];
          if (profile['birthday'] != null) {
            _selectedBirthday = DateTime.tryParse(profile['birthday'] as String);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Subir la imagen inmediatamente al seleccionarla
      await ref.read(editProfileNotifierProvider.notifier).uploadAvatar(_selectedImage!);
    }
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(DateTime.now().year - 20),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.accentPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  String _calculateAge() {
    if (_selectedBirthday == null) return '';
    final now = DateTime.now();
    int age = now.year - _selectedBirthday!.year;
    if (now.month < _selectedBirthday!.month || 
        (now.month == _selectedBirthday!.month && now.day < _selectedBirthday!.day)) {
      age--;
    }
    return age.toString();
  }

  void _saveProfile() async {
    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();
    if (newName.isEmpty) return;

    await ref.read(editProfileNotifierProvider.notifier).updateProfile(
          fullName: newName,
          bio: newBio.isEmpty ? null : newBio,
          gender: _selectedGender,
          birthday: _selectedBirthday?.toIso8601String(),
        );

    // Si todo salió bien, cerramos. Notar que la imagen ya se subió en el paso anterior.
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AVATAR COMPONENT
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentPurple.withOpacity(0.1),
                        border: Border.all(color: AppTheme.accentPurple.withOpacity(0.5), width: 3),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : (_currentAvatarUrl != null)
                                ? Image.network(_currentAvatarUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.person, size: 70, color: AppTheme.accentPurple),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: editState.isLoading ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
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
              const SizedBox(height: 16),
              
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about your style...',
                  labelStyle: const TextStyle(color: AppTheme.textGrey),
                  prefixIcon: const Icon(Icons.edit_note, color: AppTheme.accentPurple),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedGender,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: const TextStyle(color: AppTheme.textGrey),
                  prefixIcon: const Icon(Icons.transgender, color: AppTheme.accentPurple),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) {
                  setState(() => _selectedGender = val);
                },
              ),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _pickBirthday,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Birthday',
                    labelStyle: const TextStyle(color: AppTheme.textGrey),
                    prefixIcon: const Icon(Icons.cake, color: AppTheme.accentPurple),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedBirthday == null 
                            ? 'Select your birthday' 
                            : '${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: _selectedBirthday == null ? AppTheme.textGrey : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (_selectedBirthday != null)
                        Text(
                          '(Age: ${_calculateAge()})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: AppTheme.accentPurple,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              if (editState.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  editState.error.toString(),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              
              const SizedBox(height: 48),
              
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
