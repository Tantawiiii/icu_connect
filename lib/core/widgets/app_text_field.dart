import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.isPassword = false,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofillHints,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;

  final bool isPassword;

  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final showToggle = widget.isPassword && widget.suffixIcon == null;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType ??
          (widget.isPassword ? TextInputType.visiblePassword : null),
      textInputAction: widget.textInputAction,
      obscureText: widget.isPassword ? _obscure : false,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? 2 : 1,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: showToggle
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
      ),
    );
  }
}