import 'dart:async';

import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_model.dart';

import '../repository/hospital_drugs_repository.dart';

class DrugPickerField extends StatefulWidget {
  const DrugPickerField({
    super.key,
    required this.onSelected,
    this.initialLabel,
    this.enabled = true,
    this.label = 'Search drug',
    this.allowCustomName = true,
    this.onCustomName,
  });

  final ValueChanged<DrugModel> onSelected;
  final ValueChanged<String>? onCustomName;
  final String? initialLabel;
  final bool enabled;
  final String label;
  final bool allowCustomName;

  @override
  State<DrugPickerField> createState() => _DrugPickerFieldState();
}

class _DrugPickerFieldState extends State<DrugPickerField> {
  final _repo = const HospitalDrugsRepository();
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<DrugModel> _results = const [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialLabel ?? '';
  }

  @override
  void didUpdateWidget(covariant DrugPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLabel != oldWidget.initialLabel &&
        (widget.initialLabel ?? '') != _controller.text) {
      _controller.text = widget.initialLabel ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search(value);
    });
    setState(() => _showResults = true);
  }

  Future<void> _search(String raw) async {
    final q = raw.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchDrugs(search: q.isEmpty ? null : q);
      if (!mounted) return;
      setState(() {
        _results = items;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _results = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load drugs';
        _loading = false;
        _results = const [];
      });
    }
  }

  void _pick(DrugModel drug) {
    final label = hospitalDrugDisplayName(drug);
    _controller.text = label;
    setState(() => _showResults = false);
    widget.onSelected(drug);
  }

  void _useCustom() {
    final name = _controller.text.trim();
    if (name.isEmpty || widget.onCustomName == null) return;
    setState(() => _showResults = false);
    widget.onCustomName!(name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          onChanged: _onQueryChanged,
          onTap: () {
            setState(() => _showResults = true);
            if (_results.isEmpty && !_loading) _search(_controller.text);
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Type to search…',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.medication_outlined),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: widget.enabled
                            ? () {
                                _controller.clear();
                                setState(() {
                                  _results = const [];
                                  _showResults = false;
                                });
                              }
                            : null,
                      )
                    : null),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_showResults) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  )
                : _results.isEmpty && !_loading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'No drugs found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (widget.allowCustomName &&
                                _controller.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _useCustom,
                                child: Text(
                                  'Use "${_controller.text.trim()}"',
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final drug = _results[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              hospitalDrugDisplayName(drug),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: drug.indications.isEmpty
                                ? null
                                : Text(
                                    drug.indications.take(2).join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                            onTap: () => _pick(drug),
                          );
                        },
                      ),
          ),
        ],
      ],
    );
  }
}
