import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/dashboard': return 0;
      case '/history': return 1;
      case '/savings': return 2;
      case '/reflect': return 3;
      case '/profile': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: KakeiboColors.ink,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _KakeiboBottomNav(currentIndex: index),
    );
  }
}

class _KakeiboBottomNav extends StatelessWidget {
  final int currentIndex;
  const _KakeiboBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KakeiboColors.paperWhite,
        border: Border(top: BorderSide(color: KakeiboColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_outlined, label: '家', index: 0, currentIndex: currentIndex, route: '/dashboard'),
              _NavItem(icon: Icons.receipt_long_outlined, label: '記録', index: 1, currentIndex: currentIndex, route: '/history'),
              const SizedBox(width: 56),
              _NavItem(icon: Icons.savings_outlined, label: '貯金', index: 2, currentIndex: currentIndex, route: '/savings'),
              _NavItem(icon: Icons.person_outline, label: 'Profil', index: 4, currentIndex: currentIndex, route: '/profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isActive ? KakeiboColors.ink : KakeiboColors.inkFade),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? KakeiboColors.ink : KakeiboColors.inkFade,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
