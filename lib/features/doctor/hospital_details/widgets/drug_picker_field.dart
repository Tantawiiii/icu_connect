import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/features/superAdmin/drugs/models/drug_model.dart';

import '../repository/hospital_drugs_repository.dart';
import '../screens/add_drug_screen.dart';

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
  final _focusNode = FocusNode();
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
    _focusNode.dispose();
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
    _focusNode.unfocus();
    setState(() => _showResults = false);
    widget.onSelected(drug);
  }

  void _useCustom() {
    final name = _controller.text.trim();
    if (name.isEmpty || widget.onCustomName == null) return;
    _focusNode.unfocus();
    setState(() => _showResults = false);
    widget.onCustomName!(name);
  }

  Future<void> _openAddDrug() async {
    _focusNode.unfocus();
    final drug = await Navigator.of(context).push<DrugModel>(
      MaterialPageRoute(
        builder: (_) => AddDrugScreen(
          initialGenericName: _controller.text.trim().isEmpty
              ? null
              : _controller.text.trim(),
        ),
      ),
    );
    if (drug == null || !mounted) return;
    _pick(drug);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _showResults
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            onChanged: _onQueryChanged,
            onTap: () {
              setState(() => _showResults = true);
              if (_results.isEmpty && !_loading) _search(_controller.text);
            },
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: 'Type to search…',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.medication_outlined,
                size: 20,
                color: _showResults
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            color: AppColors.textSecondary,
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
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _showResults
              ? _buildResultsPanel()
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildResultsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading && _results.isEmpty)
              _buildLoadingSkeleton()
            else if (_error != null)
              _buildErrorState()
            else if (_results.isEmpty)
              _buildEmptyState()
            else
              Flexible(child: _buildResultsList()),
            _buildAddNewDrugRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: List.generate(
          3,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == 2 ? 0 : 8),
            child: Shimmer.fromColors(
              baseColor: AppColors.border,
              highlightColor: AppColors.surface,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 26,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'No drugs found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.allowCustomName && _controller.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _useCustom,
              child: Text('Use "${_controller.text.trim()}"'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final drug = _results[index];
        return InkWell(
          onTap: () => _pick(drug),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospitalDrugDisplayName(drug),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (drug.indications.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          drug.indications.take(2).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddNewDrugRow() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? _openAddDrug : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    AppTexts.addNewDrug,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
