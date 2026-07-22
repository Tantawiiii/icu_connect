import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';

class StringListEditor extends StatefulWidget {
  const StringListEditor({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.maxLength = 500,
    this.enabled = true,
    this.hintText,
  });

  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final int maxLength;
  final bool enabled;
  final String? hintText;

  @override
  State<StringListEditor> createState() => _StringListEditorState();
}

class _StringListEditorState extends State<StringListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty || !widget.enabled) return;
    final next = [...widget.items, value];
    _controller.clear();
    widget.onChanged(next);
  }

  void _remove(int index) {
    if (!widget.enabled) return;
    final next = [...widget.items]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(widget.maxLength),
                ],
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Enter value',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: widget.enabled ? _add : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(AppTexts.addListItem),
            ),
          ],
        ),
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                InputChip(
                  label: Text(widget.items[i]),
                  onDeleted: widget.enabled ? () => _remove(i) : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
