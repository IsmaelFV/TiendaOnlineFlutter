import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';

/// Input personalizado reutilizable con estilo premium y animación de focus
class CustomInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool hideCounter;
  final TextCapitalization textCapitalization;

  const CustomInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.contentPadding,
    this.inputFormatters,
    this.maxLength,
    this.hideCounter = true,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput>
    with SingleTickerProviderStateMixin {
  late final FocusNode _internalFocus;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocus = widget.focusNode ?? FocusNode();
    _internalFocus.addListener(_onFocusChange);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOutCubic);
  }

  void _onFocusChange() {
    final focused = _internalFocus.hasFocus;
    if (focused != _isFocused) {
      setState(() => _isFocused = focused);
      if (focused) {
        _glowCtrl.forward();
      } else {
        _glowCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _internalFocus.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _glowAnim.value > 0
              ? [
                  BoxShadow(
                    color: AppColors.gold500.withValues(
                      alpha: 0.15 * _glowAnim.value,
                    ),
                    blurRadius: 12 * _glowAnim.value,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        focusNode: _internalFocus,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          contentPadding: widget.contentPadding,
          counterText: widget.hideCounter ? '' : null,
        ),
      ),
    );
  }
}
