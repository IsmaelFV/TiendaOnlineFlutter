import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/widgets/loader.dart';
import '../../../../shared/widgets/animations.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppColors.gold500.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.gold500.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            autofocus: true,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isFocused
                    ? const GoldIcon(
                        key: ValueKey('gold'),
                        icon: Icons.search,
                        size: 22,
                      )
                    : const Icon(
                        Icons.search,
                        key: ValueKey('normal'),
                        color: AppColors.textMuted,
                        size: 22,
                      ),
              ),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? const AnimatedEmptyState(
              icon: Icons.search,
              title: 'Buscar productos',
              subtitle: 'Busca por nombre, categor\u00eda\no material',
            )
          : searchResults.when(
              loading: () => const Loader(),
              error: (_, _) => const AnimatedEmptyState(
                icon: Icons.error_outline,
                title: 'Error en la b\u00fasqueda',
                subtitle: 'Int\u00e9ntalo de nuevo m\u00e1s tarde',
              ),
              data: (products) {
                if (products.isEmpty) {
                  return AnimatedEmptyState(
                    icon: Icons.search_off,
                    title: 'Sin resultados',
                    subtitle: 'No se encontraron productos para "$query"',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.52,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => ScaleFadeIn(
                    delay: Duration(milliseconds: 60 * index),
                    child: ProductCard(product: products[index]),
                  ),
                );
              },
            ),
    );
  }
}
