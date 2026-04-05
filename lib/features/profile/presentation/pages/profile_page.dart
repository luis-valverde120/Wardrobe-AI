import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/settings_blocks.dart';
import '../widgets/profile_logout_button.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || 
                      (themeMode == ThemeMode.system && 
                       MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              floating: true,
              elevation: 0,
              centerTitle: true,
              title: Text(
                'My Profile',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  children: [
                    const ProfileHeaderCard(),
                    
                    const SizedBox(height: 32),
                    
                    const SettingsSectionHeader(title: 'General'),
                    SettingsTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {
                      context.push('/edit-profile');
                    }),
                    SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
                    
                    const SizedBox(height: 24),
                    
                    const SettingsSectionHeader(title: 'Preferences'),
                    SettingsSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      value: isDarkMode,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).toggleTheme(value);
                      },
                    ),
                    SettingsTile(icon: Icons.language_outlined, title: 'Language', onTap: () {}),
                    
                    const SizedBox(height: 40),
                    
                    const ProfileLogoutButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
