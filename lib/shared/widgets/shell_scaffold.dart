import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_text_styles.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';

/// Scaffold con navegación inferior animada estilo Dribbble.
/// - Indicador dorado deslizante bajo el icono activo
/// - Bounce del icono al pulsar
/// - Transición suave de color y tamaño
class ShellScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold>
    with TickerProviderStateMixin {
  static const _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
      path: '/',
    ),
    _NavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Tienda',
      path: '/productos',
    ),
    _NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Buscar',
      path: '/search',
      isSpecial: true,
    ),
    _NavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'Carrito',
      path: '/cart',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
      path: '/perfil',
    ),
  ];

  // Controllers para el bounce de cada tab
  late final List<AnimationController> _bounceControllers;
  late final List<Animation<double>> _bounceAnimations;

  @override
  void initState() {
    super.initState();
    _bounceControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    _bounceAnimations = _bounceControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 15),
        TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _bounceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].path) return i;
    }
    return 0;
  }

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    _bounceControllers[index].forward(from: 0);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateIndex(context);
    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.itemCount;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        height: 64 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Indicador deslizante dorado
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: 0,
              left: _indicatorLeft(context, currentIndex),
              child: Container(
                width: _tabWidth(context),
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.gold500,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Tabs
            Row(
              children: List.generate(_navItems.length, (i) {
                final isActive = i == currentIndex;
                final item = _navItems[i];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(i),
                    child: AnimatedBuilder(
                      animation: _bounceAnimations[i],
                      builder: (context, child) => Transform.scale(
                        scale: _bounceAnimations[i].value,
                        child: child,
                      ),
                      child: _buildTab(item, isActive, i == 3, cartCount),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  double _tabWidth(BuildContext context) =>
      MediaQuery.of(context).size.width / _navItems.length;

  double _indicatorLeft(BuildContext context, int index) =>
      index * _tabWidth(context);

  Widget _buildTab(_NavItem item, bool isActive, bool isCart, int cartCount) {
    // Tab especial de Buscar con icono destacado
    if (item.isSpecial) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [AppColors.gold400, AppColors.gold600],
                      )
                    : null,
                color: isActive
                    ? null
                    : AppColors.gold500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                item.activeIcon,
                size: 21,
                color: isActive ? Colors.white : AppColors.gold500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? AppColors.gold500 : AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(item, isActive, isCart, cartCount),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.gold500 : AppColors.textMuted,
              fontSize: isActive ? 10.5 : 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(_NavItem item, bool isActive, bool isCart, int cartCount) {
    final icon = AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        isActive ? item.activeIcon : item.icon,
        key: ValueKey(isActive),
        size: isActive ? 26 : 23,
        color: isActive ? AppColors.gold500 : AppColors.textMuted,
      ),
    );

    if (isCart && cartCount > 0) {
      return badges.Badge(
        badgeContent: Text(
          '$cartCount',
          style: AppTextStyles.caption.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        badgeStyle: const badges.BadgeStyle(
          badgeColor: AppColors.gold500,
          padding: EdgeInsets.all(4),
          elevation: 2,
        ),
        badgeAnimation: const badges.BadgeAnimation.scale(
          animationDuration: Duration(milliseconds: 300),
        ),
        child: icon,
      );
    }

    return icon;
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final bool isSpecial;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.isSpecial = false,
  });
}
