import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dose_units_service.dart';
import '../../../../core/widgets/app_text_field.dart';

String _normalizeUnitToken(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Bounded in-process cache so every screen that shows the dose-unit dropdown
/// doesn't refetch the (near-static) lookup list on every mount — one fetch
/// per role per app session is enough.
class _DoseUnitsCache {
  static final Map<UserRole, Future<List<DoseUnit>>> _futures = {};

  static Future<List<DoseUnit>> fetch(UserRole role) {
    return _futures.putIfAbsent(role, () => DoseUnitsService(role).fetchAll());
  }
}

/// "Dose amount" text field + unit dropdown, used by the doctor-side
/// add-drug form, the superAdmin drug form, and the admission medication
/// form so all three stay in sync. The unit list is fetched from
/// `/hospital/dose-units` or `/admin/dose-units` depending on [role].
class DoseInputRow extends StatefulWidget {
  const DoseInputRow({
    super.key,
    required this.role,
    required this.amountController,
    required this.unitId,
    required this.onUnitChanged,
    this.enabled = true,
    this.amountLabel = AppTexts.doseAmount,
    this.unitCodeFilter,
    this.lockedDisplayLabel,
  });

  final UserRole role;
  final TextEditingController amountController;
  final int? unitId;
  final ValueChanged<int?> onUnitChanged;
  final bool enabled;
  final String amountLabel;

  /// When set, the unit dropdown only offers units whose `code` (matched
  /// case-insensitively) is in this list — e.g. restricting it to `ml/h`
  /// for an infusion rate. If the filtered list has exactly one option it
  /// is auto-selected.
  final List<String>? unitCodeFilter;

  /// When set, the unit picker is replaced with a plain, non-interactive
  /// display of this text (e.g. "ml/h") instead of a dropdown — the real
  /// `dose_unit_id` is still resolved from [unitCodeFilter] behind the
  /// scenes and reported via [onUnitChanged].
  final String? lockedDisplayLabel;

  @override
  State<DoseInputRow> createState() => _DoseInputRowState();
}

class _DoseInputRowState extends State<DoseInputRow> {
  late Future<List<DoseUnit>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _unitsFuture = _DoseUnitsCache.fetch(widget.role);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: AppTextField(
            controller: widget.amountController,
            labelText: widget.amountLabel,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: FutureBuilder<List<DoseUnit>>(
            future: _unitsFuture,
            builder: (context, snapshot) {
              final allUnits = snapshot.data ?? const <DoseUnit>[];
              final filter = widget.unitCodeFilter
                  ?.map(_normalizeUnitToken)
                  .toSet();
              final filtered = filter == null
                  ? allUnits
                  : allUnits.where((u) {
                      final tokens = [
                        _normalizeUnitToken(u.code),
                        _normalizeUnitToken(u.label),
                        _normalizeUnitToken(u.name),
                      ];
                      return filter.any(
                        (f) => tokens.any((t) => t.contains(f)),
                      );
                    }).toList();
              // Fall back to the full list if nothing matched the filter
              // (e.g. the backend's unit code doesn't exactly match what we
              // expect) so the dropdown never ends up empty/unusable.
              final filterMatched = filter == null || filtered.isNotEmpty;
              final units = filterMatched ? filtered : allUnits;
              final loading =
                  snapshot.connectionState != ConnectionState.done;
              final validId = units.any((u) => u.id == widget.unitId)
                  ? widget.unitId
                  : null;

              if (!loading && validId == null && units.length == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) widget.onUnitChanged(units.first.id);
                });
              }

              // Only show the static locked label once the filter actually
              // matched a real unit — otherwise fall through to a normal,
              // interactive dropdown so the user can pick manually instead
              // of silently submitting with no dose_unit_id resolved.
              if (widget.lockedDisplayLabel != null &&
                  !loading &&
                  filterMatched) {
                return InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppTexts.doseUnit,
                    suffixIcon: loading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : null,
                  ),
                  child: Text(widget.lockedDisplayLabel!),
                );
              }

              return DropdownButtonFormField<int>(
                value: validId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppTexts.doseUnit,
                  suffixIcon: loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                selectedItemBuilder: (context) => units
                    .map(
                      (u) => Text(
                        u.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                    .toList(),
                items: units
                    .map(
                      (u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(
                          u.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.enabled && !loading
                    ? widget.onUnitChanged
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
