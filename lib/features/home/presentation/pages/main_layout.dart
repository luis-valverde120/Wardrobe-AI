import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const Center(child: Text('Saved Outfits')),
    const Center(child: Text('Store')),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentPurple,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          _showAIGeneratorOptions(context);
        },
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BARRA INFERIOR CORREGIDA
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        // 1. Reseteamos el padding interno que Material 3 pone por defecto
        padding: const EdgeInsets.symmetric(horizontal: 0),
        // 2. Le damos la altura directamente al componente
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildNavBarItem(
                icon: Icons.checkroom,
                index: 0,
                label: 'Closet',
              ),
            ),
            Expanded(
              child: _buildNavBarItem(
                icon: Icons.style_outlined,
                index: 1,
                label: 'Outfits',
              ),
            ),

            const SizedBox(width: 70),

            Expanded(
              child: _buildNavBarItem(
                icon: Icons.shopping_bag_outlined,
                index: 2,
                label: 'Store',
              ),
            ),
            Expanded(
              child: _buildNavBarItem(
                icon: Icons.person_outline,
                index: 3,
                label: 'Profile',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.accentPurple : AppTheme.textGrey,
            size: 24, // Tamaño balanceado
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.accentPurple : AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  void _showAIGeneratorOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Outfit Generator ✨',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.shuffle, color: AppTheme.accentPurple),
              title: const Text('Surprise Me (Auto-Match)'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(
                Icons.wb_sunny_outlined,
                color: Colors.orange,
              ),
              title: const Text('Generate by Weather'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: Colors.purple),
              title: const Text('Asesor de Moda IA (Gemma)'),
              onTap: () {
                Navigator.pop(context); // Cerrar modal
                context.push('/fashion-advisor');
              },
            ),
          ],
        ),
      ),
    );
  }
}
