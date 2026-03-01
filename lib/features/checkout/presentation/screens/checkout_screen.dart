import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../shared/extensions/number_extensions.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/widgets/animations.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_input.dart';
import '../../../cart/data/models/cart_state.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../products/presentation/providers/products_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isProcessing = false;
  int _currentStep = 0;

  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _staggerAnims;

  final _stepTitles = ['Envío', 'Resumen', 'Pago'];
  final _stepIcons = [
    Icons.local_shipping_outlined,
    Icons.receipt_long_outlined,
    Icons.payment_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _staggerAnims = createStaggerAnimations(
      controller: _staggerCtrl,
      count: 12,
      delayPerItem: 0.06,
      itemDuration: 0.28,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _notesController.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step == _currentStep) return;
    // Replay stagger for new step content
    _staggerCtrl.forward(from: 0);
    setState(() => _currentStep = step);
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
    if (_currentStep < 2) {
      HapticFeedback.lightImpact();
      _goToStep(_currentStep + 1);
    } else {
      _processCheckout();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _goToStep(_currentStep - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final user = ref.watch(currentUserProvider).value;

    if (user != null && _emailController.text.isEmpty) {
      _emailController.text = user.email;
      _nameController.text = user.fullName ?? '';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── HEADER ───
            _buildSliverHeader(cart),

            // ─── PROGRESS INDICATOR ───
            SliverToBoxAdapter(
              child: FadeSlideItem(
                index: 0,
                animation: _staggerAnims[0],
                child: _buildProgressBar(),
              ),
            ),

            // ─── STEP CONTENT (animated switch) ───
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildCurrentStep(cart),
                ),
              ),
            ),

            // ─── ACTIONS ───
            SliverToBoxAdapter(child: _buildActions()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SLIVER HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildSliverHeader(CartState cart) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.gray800.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold500.withValues(alpha: 0.08),
                AppColors.surface,
                AppColors.gold500.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.gold500, AppColors.gold600],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold500.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checkout',
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cart.uniqueItemCount} artículo${cart.uniqueItemCount != 1 ? 's' : ''} · ${cart.total.toCurrency}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gold400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PROGRESS BAR
  // ═══════════════════════════════════════════════════════════

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              final isActive = i == _currentStep;
              final isCompleted = i < _currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: isCompleted ? () => _goToStep(i) : null,
                  child: Row(
                    children: [
                      if (i > 0)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              color: isCompleted || isActive
                                  ? AppColors.gold500
                                  : AppColors.gray700,
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 40 : 32,
                        height: isActive ? 40 : 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: (isActive || isCompleted)
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.gold400,
                                    AppColors.gold600,
                                  ],
                                )
                              : null,
                          color: (!isActive && !isCompleted)
                              ? AppColors.gray800
                              : null,
                          border: Border.all(
                            color: (isActive || isCompleted)
                                ? AppColors.gold500
                                : AppColors.gray600,
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.gold500.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : _stepIcons[i],
                          color: (isActive || isCompleted)
                              ? Colors.white
                              : AppColors.gray500,
                          size: isActive ? 20 : 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final isActive = i == _currentStep;
              return Expanded(
                child: Text(
                  _stepTitles[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? AppColors.gold400 : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: isActive ? 0.5 : 0,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP CONTENT ROUTER
  // ═══════════════════════════════════════════════════════════

  Widget _buildCurrentStep(CartState cart) {
    switch (_currentStep) {
      case 0:
        return _buildShippingStep();
      case 1:
        return _buildSummaryStep(cart);
      case 2:
        return _buildPaymentStep(cart);
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 1: DATOS DE ENVÍO
  // ═══════════════════════════════════════════════════════════

  Widget _buildShippingStep() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Información personal',
            animIndex: 1,
          ),
          const SizedBox(height: 12),
          FadeSlideItem(
            index: 2,
            animation: _staggerAnims[2],
            child: _buildCard(
              child: Column(
                children: [
                  CustomInput(
                    controller: _nameController,
                    label: 'Nombre completo',
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]'),
                      ),
                    ],
                    maxLength: 60,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Introduce tu nombre';
                      }
                      if (v.trim().length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      if (!v.trim().contains(' ')) {
                        return 'Introduce nombre y apellido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomInput(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    maxLength: 80,
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Introduce tu email';
                      if (!RegExp(
                        r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                      ).hasMatch(v!)) {
                        return 'Email no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomInput(
                    controller: _phoneController,
                    label: 'Teléfono',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    maxLength: 9,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Introduce tu teléfono';
                      }
                      if (v.length < 9) {
                        return 'El teléfono debe tener 9 dígitos';
                      }
                      if (!RegExp(r'^[6-9]').hasMatch(v)) {
                        return 'Debe empezar por 6, 7, 8 o 9';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Dirección de envío',
            animIndex: 3,
          ),
          const SizedBox(height: 12),
          FadeSlideItem(
            index: 4,
            animation: _staggerAnims[4],
            child: _buildCard(
              child: Column(
                children: [
                  CustomInput(
                    controller: _addressController,
                    label: 'Dirección',
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: const Icon(Icons.home_outlined, size: 20),
                    maxLength: 100,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Introduce tu dirección';
                      }
                      if (v.trim().length < 5) {
                        return 'Dirección demasiado corta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomInput(
                    controller: _address2Controller,
                    label: 'Piso, puerta... (opcional)',
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: const Icon(Icons.apartment_outlined, size: 20),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CustomInput(
                          controller: _cityController,
                          label: 'Ciudad',
                          textCapitalization: TextCapitalization.words,
                          prefixIcon: const Icon(
                            Icons.location_city_outlined,
                            size: 20,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\-]'),
                            ),
                          ],
                          maxLength: 40,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            if (v.trim().length < 2) {
                              return 'Ciudad no válida';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomInput(
                          controller: _postalController,
                          label: 'C.P.',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          maxLength: 5,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (v.length != 5) return 'C.P. 5 dígitos';
                            final code = int.tryParse(v);
                            if (code == null || code < 1000 || code > 52999) {
                              return 'C.P. no válido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomInput(
                    controller: _stateController,
                    label: 'Provincia (opcional)',
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(Icons.map_outlined, size: 20),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\-]'),
                      ),
                    ],
                    maxLength: 40,
                  ),
                ],
              ),
            ),
          ),
          FadeSlideItem(
            index: 5,
            animation: _staggerAnims[5],
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Envío gratuito en todos los pedidos',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 2: RESUMEN DEL PEDIDO
  // ═══════════════════════════════════════════════════════════

  Widget _buildSummaryStep(CartState cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Artículos (${cart.uniqueItemCount})',
            animIndex: 1,
          ),
          const SizedBox(height: 12),
          ...cart.items.values.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final animIdx = (idx + 2).clamp(0, _staggerAnims.length - 1);
            return FadeSlideItem(
              index: idx + 2,
              animation: _staggerAnims[animIdx],
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: item.image != null
                            ? CachedImage(
                                imageUrl: item.image!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppColors.gray800,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.gray600,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              _buildMiniTag(item.size),
                              const SizedBox(width: 6),
                              _buildMiniTag('x${item.quantity}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      (item.price * item.quantity).toCurrency,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          _buildSectionHeader(
            icon: Icons.edit_note_rounded,
            title: 'Notas (opcional)',
            animIndex: 7,
          ),
          const SizedBox(height: 12),
          FadeSlideItem(
            index: 8,
            animation: _staggerAnims[8],
            child: _buildCard(
              child: CustomInput(
                controller: _notesController,
                label: 'Instrucciones especiales...',
                maxLines: 3,
                prefixIcon: const Icon(Icons.sticky_note_2_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideItem(
            index: 9,
            animation: _staggerAnims[9],
            child: _buildTotalsCard(cart),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STEP 3: PAGO
  // ═══════════════════════════════════════════════════════════

  Widget _buildPaymentStep(CartState cart) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.payment_outlined,
            title: 'Método de pago',
            animIndex: 1,
          ),
          const SizedBox(height: 12),
          FadeSlideItem(
            index: 2,
            animation: _staggerAnims[2],
            child: _buildPaymentOption(
              icon: Icons.credit_card_rounded,
              title: 'Tarjeta de crédito/débito',
              subtitle: 'Pago seguro con Stripe',
              isSelected: true,
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideItem(
            index: 5,
            animation: _staggerAnims[5],
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.gold500,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pago 100% seguro',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSecurityBadge(
                        Icons.verified_user_outlined,
                        'Cifrado SSL',
                      ),
                      _buildSecurityBadge(Icons.shield_outlined, '3D Secure'),
                      _buildSecurityBadge(Icons.privacy_tip_outlined, 'RGPD'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeSlideItem(
            index: 6,
            animation: _staggerAnims[6],
            child: _buildTotalsCard(cart),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          CustomButton(
            text: _currentStep == 2 ? 'CONFIRMAR Y PAGAR' : 'CONTINUAR',
            icon: _currentStep == 2 ? Icons.lock_outline : Icons.arrow_forward,
            onPressed: _isProcessing ? null : _nextStep,
            isLoading: _isProcessing,
          ),
          if (_currentStep > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text(
                  'Paso anterior',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  REUSABLE COMPONENTS
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int animIndex,
  }) {
    final idx = animIndex.clamp(0, _staggerAnims.length - 1);
    return FadeSlideItem(
      index: animIndex,
      animation: _staggerAnims[idx],
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.gold500, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTotalsCard(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.gold500.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold500.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', cart.subtotal.toCurrency),
          if (cart.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              'Descuento (${cart.discountCode})',
              '-${cart.discountAmount.toCurrency}',
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 8),
          _buildTotalRow('Envío', 'Gratis', valueColor: AppColors.success),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold500.withValues(alpha: 0.0),
                    AppColors.gold500.withValues(alpha: 0.3),
                    AppColors.gold500.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                cart.total.toCurrency,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gray800,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.gold500.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.gold500.withValues(alpha: 0.5)
              : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold500.withValues(alpha: 0.15)
                  : AppColors.gray800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDisabled
                  ? AppColors.gray600
                  : isSelected
                  ? AppColors.gold500
                  : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isDisabled ? AppColors.gray600 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold400, AppColors.gold600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            )
          else if (isDisabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gray800,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Pronto',
                style: TextStyle(
                  color: AppColors.gray500,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PAGO NATIVO CON STRIPE PAYMENT SHEET
  // ═══════════════════════════════════════════════════════════

  /// Crea un PaymentIntent en el backend y devuelve el clientSecret
  /// para inicializar el Payment Sheet nativo dentro de la app.
  /// El backend valida stock, precios y crea el PaymentIntent en Stripe.
  Future<Map<String, dynamic>> _createPaymentIntent(CartState cart) async {
    final items = cart.items.values
        .map(
          (item) => {
            'id': item.productId,
            'quantity': item.quantity,
            'size': item.size,
          },
        )
        .toList();

    return ApiClient.instance.postFunction(
      'create-payment-intent',
      body: {
        'items': items,
        'shipping': {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'addressLine1': _addressController.text.trim(),
          'addressLine2': _address2Controller.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'postalCode': _postalController.text.trim(),
          'country': 'España',
          'notes': _notesController.text.trim(),
        },
        if (cart.discountCode.isNotEmpty) 'discountCode': cart.discountCode,
      },
    );
  }

  /// Confirma el pago en el backend tras un pago exitoso.
  /// El backend verifica con Stripe, crea el pedido, descuenta stock y
  /// envía emails de confirmación.
  Future<String?> _confirmPayment(String paymentIntentId) async {
    try {
      final data = await ApiClient.instance.postFunction(
        'confirm-payment',
        body: {'paymentIntentId': paymentIntentId},
      );
      final order = data['order'] as Map<String, dynamic>?;
      return order?['id'] as String?;
    } catch (_) {
      // Si falla la confirmación, el webhook lo procesará
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  PROCESS CHECKOUT
  // ═══════════════════════════════════════════════════════════

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) {
      _goToStep(0);
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final cart = ref.read(cartProvider);

      // ─── 1. Crear PaymentIntent en el backend ───
      // El backend valida stock real, precios de BD y crea el PI en Stripe
      final paymentData = await _createPaymentIntent(cart);

      final clientSecret = paymentData['clientSecret'] as String?;
      final paymentIntentId = paymentData['paymentIntentId'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Error al preparar el pago');
      }

      // ─── 2. Inicializar Payment Sheet nativo ───
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Fashion Store',
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              background: AppColors.surface,
              primary: AppColors.gold500,
              componentBackground: AppColors.card,
              componentText: AppColors.textPrimary,
              secondaryText: AppColors.textMuted,
              placeholderText: AppColors.textMuted,
              icon: AppColors.gold500,
            ),
            shapes: const PaymentSheetShape(borderRadius: 14, borderWidth: 1),
          ),
        ),
      );

      // ─── 3. Mostrar Payment Sheet (el usuario paga aquí dentro de la app) ───
      await Stripe.instance.presentPaymentSheet();

      // ─── 4. Pago exitoso → confirmar pedido en backend ───
      // El backend verifica con Stripe, crea pedido, descuenta stock, envía email
      final orderId = await _confirmPayment(paymentIntentId ?? '');

      // ─── 5. Limpiar carrito, refrescar datos y navegar a pantalla de éxito ───
      ref.read(cartProvider.notifier).clear();

      // Refrescar stock de productos en toda la app
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(newProductsProvider);
      ref.invalidate(ordersProvider);

      if (mounted) {
        final query = orderId != null ? '?order=$orderId' : '';
        context.go('/checkout/exito$query');
      }
    } on StripeException catch (e) {
      // Usuario canceló el Payment Sheet o error de Stripe
      if (mounted) {
        final message = e.error.localizedMessage ?? 'Pago cancelado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pedido: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
