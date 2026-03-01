import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/products/presentation/screens/home_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/search_screen.dart';
import '../../features/products/presentation/screens/category_explorer_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/checkout_success_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/wishlist/presentation/screens/favorites_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/security_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_products_screen.dart';
import '../../features/admin/presentation/screens/admin_product_form_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_returns_screen.dart';
import '../../features/admin/presentation/screens/admin_flash_offers_screen.dart';
import '../../features/admin/presentation/screens/admin_coupons_screen.dart';
import '../../features/settings/presentation/screens/static_page_screen.dart';
import '../../features/settings/presentation/screens/contact_screen.dart';
import '../../features/returns/presentation/screens/returns_screen.dart';
import '../../features/returns/presentation/screens/refund_request_screen.dart';
import '../../shared/widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Provider del router con GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  // Supabase puede no haberse inicializado (sin red al arrancar)
  SupabaseClient? supabase;
  try {
    supabase = Supabase.instance.client;
  } catch (_) {
    debugPrint('[Router] Supabase no disponible — modo offline');
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final session = supabase?.auth.currentSession;
      final isLoggedIn = session != null;
      final location = state.matchedLocation;

      // Rutas públicas que no requieren autenticación
      final publicRoutes = [
        '/',
        '/login',
        '/register',
        '/productos',
        '/search',
        '/tienda',
        '/cart',
        '/contacto',
        '/faq',
        '/envios',
        '/devoluciones',
        '/terminos',
        '/privacidad',
        '/cookies',
        '/sobre-nosotros',
        '/sostenibilidad',
      ];

      final isPublicRoute =
          publicRoutes.contains(location) ||
          location.startsWith('/productos/') ||
          location.startsWith('/tienda') ||
          location.startsWith('/categoria/') ||
          location.startsWith('/novedades') ||
          location.startsWith('/ofertas') ||
          location.startsWith('/mujer') ||
          location.startsWith('/hombre');

      final isAuthRoute = location == '/login' || location == '/register';

      // Si no está logueado y la ruta requiere auth
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // Si está logueado e intenta ir a login/register
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      // Rutas admin: verificar si es admin
      if (location.startsWith('/admin')) {
        if (!isLoggedIn || supabase == null) return '/login';

        try {
          final adminCheck = await supabase
              .from('admin_users')
              .select('id')
              .eq('user_id', session.user.id)
              .maybeSingle();

          if (adminCheck == null) return '/';
        } catch (_) {
          return '/';
        }
      }

      return null; // No redirigir
    },
    routes: [
      // ─── Shell principal con bottom nav ───
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/productos',
            name: 'products',
            builder: (context, state) => const CategoryExplorerScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/perfil',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ─── Rutas fuera del shell (full-screen) ───

      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Lista de productos (navegación desde explorador de categorías)
      GoRoute(
        path: '/tienda',
        name: 'tienda',
        builder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return ProductListScreen(
            initialGenderId: queryParams['genderId'],
            initialCategoryId: queryParams['categoryId'],
            initialIsNew: queryParams['isNew'] == 'true' ? true : null,
            initialIsOnSale: queryParams['isOnSale'] == 'true' ? true : null,
          );
        },
      ),

      // Novedades (productos nuevos)
      GoRoute(
        path: '/novedades',
        name: 'novedades',
        builder: (context, state) {
          final queryParams = state.uri.queryParameters;
          return ProductListScreen(
            initialIsNew: true,
            initialGenderId: queryParams['genderId'],
          );
        },
      ),

      // Detalle producto (Hero animation)
      GoRoute(
        path: '/productos/:slug',
        name: 'product-detail',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return ProductDetailScreen(slug: slug);
        },
      ),

      // Checkout
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CheckoutScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/checkout/exito',
        name: 'checkout-success',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: CheckoutSuccessScreen(
            orderId: state.uri.queryParameters['order'],
          ),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),

      // Pedidos
      GoRoute(
        path: '/perfil/mis-pedidos',
        name: 'orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/perfil/mis-pedidos/:id',
        name: 'order-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/perfil/mis-pedidos/:id/reembolso',
        name: 'refund-request',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RefundRequestScreen(orderId: id);
        },
      ),

      // Favoritos
      GoRoute(
        path: '/perfil/favoritos',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Seguridad
      GoRoute(
        path: '/perfil/seguridad',
        name: 'security',
        builder: (context, state) => const SecurityScreen(),
      ),

      // ─── Páginas estáticas ───
      GoRoute(
        path: '/contacto',
        name: 'contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) =>
            const StaticPageScreen(title: 'Preguntas Frecuentes', type: 'faq'),
      ),
      GoRoute(
        path: '/envios',
        name: 'shipping',
        builder: (context, state) =>
            const StaticPageScreen(title: 'Política de Envíos', type: 'envios'),
      ),
      GoRoute(
        path: '/devoluciones',
        name: 'returns-policy',
        builder: (context, state) => const StaticPageScreen(
          title: 'Política de Devoluciones',
          type: 'devoluciones',
        ),
      ),
      GoRoute(
        path: '/terminos',
        name: 'terms',
        builder: (context, state) => const StaticPageScreen(
          title: 'Términos y Condiciones',
          type: 'terminos',
        ),
      ),
      GoRoute(
        path: '/privacidad',
        name: 'privacy',
        builder: (context, state) => const StaticPageScreen(
          title: 'Política de Privacidad',
          type: 'privacidad',
        ),
      ),
      GoRoute(
        path: '/sobre-nosotros',
        name: 'about',
        builder: (context, state) =>
            const StaticPageScreen(title: 'Sobre Nosotros', type: 'sobre'),
      ),

      // ─── Admin routes (premium transitions) ───
      GoRoute(
        path: '/admin',
        name: 'admin-dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
          transitionDuration: const Duration(milliseconds: 550),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutExpo,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/admin/productos',
        name: 'admin-products',
        pageBuilder: (context, state) => _adminSlideTransition(
          key: state.pageKey,
          child: const AdminProductsScreen(),
          beginOffset: const Offset(1.0, 0.0),
        ),
      ),
      GoRoute(
        path: '/admin/productos/nuevo',
        name: 'admin-product-new',
        pageBuilder: (context, state) => _adminSlideTransition(
          key: state.pageKey,
          child: const AdminProductFormScreen(productId: null),
          beginOffset: const Offset(0.0, 0.3),
        ),
      ),
      GoRoute(
        path: '/admin/productos/:id/editar',
        name: 'admin-product-edit',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _adminSlideTransition(
            key: state.pageKey,
            child: AdminProductFormScreen(productId: id),
            beginOffset: const Offset(0.0, 0.3),
          );
        },
      ),
      GoRoute(
        path: '/admin/pedidos',
        name: 'admin-orders',
        pageBuilder: (context, state) => _adminSlideTransition(
          key: state.pageKey,
          child: const AdminOrdersScreen(),
          beginOffset: const Offset(1.0, 0.05),
        ),
      ),
      GoRoute(
        path: '/admin/pedidos/:id',
        name: 'admin-order-detail',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _adminSlideTransition(
            key: state.pageKey,
            child: OrderDetailScreen(orderId: id),
            beginOffset: const Offset(1.0, 0.0),
          );
        },
      ),
      GoRoute(
        path: '/admin/devoluciones',
        name: 'admin-returns',
        pageBuilder: (context, state) => _adminSlideTransition(
          key: state.pageKey,
          child: const AdminReturnsScreen(),
          beginOffset: const Offset(-1.0, 0.05),
        ),
      ),
      GoRoute(
        path: '/admin/flash-offers',
        name: 'admin-flash-offers',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminFlashOffersScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/admin/cupones',
        name: 'admin-coupons',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminCouponsScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        path: '/admin/devoluciones-usuario',
        name: 'user-returns',
        builder: (context, state) => const ReturnsScreen(),
      ),
    ],
  );
});

/// Reusable admin slide + fade transition
CustomTransitionPage _adminSlideTransition({
  required LocalKey key,
  required Widget child,
  required Offset beginOffset,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      );
    },
  );
}
