import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/hospital_form_cubit.dart';
import '../cubit/hospital_form_state.dart';
import '../models/hospital_model.dart';
import '../models/hospital_request_model.dart';

class HospitalFormScreen extends StatelessWidget {
  const HospitalFormScreen({super.key, this.hospital});

  /// Null = create mode, non-null = edit mode.
  final HospitalModel? hospital;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HospitalFormCubit(),
      child: _HospitalFormView(hospital: hospital),
    );
  }
}

class _HospitalFormView extends StatefulWidget {
  const _HospitalFormView({this.hospital});

  final HospitalModel? hospital;

  @override
  State<_HospitalFormView> createState() => _HospitalFormViewState();
}

class _HospitalFormViewState extends State<_HospitalFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  final List<_GroupDraft> _groups = [];

  bool get _isEdit => widget.hospital != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.hospital?.name ?? '');
    _locationCtrl =
        TextEditingController(text: widget.hospital?.location ?? '');

    if (widget.hospital != null && widget.hospital!.groups.isNotEmpty) {
      for (final g in widget.hospital!.groups) {
        _groups.add(
          _GroupDraft(
            id: g.id,
            name: g.name,
            totalBeds: g.totalBeds.toString(),
            availableBeds: g.availableBeds.toString(),
          ),
        );
      }
    } else {
      _groups.add(_GroupDraft(name: 'Group A'));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    for (final group in _groups) {
      group.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final groups = _groups
        .map(
          (g) => HospitalGroupRequest(
            id: g.id,
            delete: g.markedForDeletion,
            name: g.markedForDeletion ? null : g.nameCtrl.text.trim(),
            totalBeds: g.markedForDeletion
                ? null
                : int.tryParse(g.totalBedsCtrl.text.trim()) ?? 0,
            availableBeds: g.markedForDeletion
                ? null
                : int.tryParse(g.availableBedsCtrl.text.trim()) ?? 0,
          ),
        )
        .toList();

    final request = HospitalRequest(
      name: _nameCtrl.text.trim(),
      location: _isEdit ? null : _locationCtrl.text.trim(),
      groups: groups,
    );

    if (_isEdit) {
      context
          .read<HospitalFormCubit>()
          .updateHospital(widget.hospital!.id, request);
    } else {
      context.read<HospitalFormCubit>().createHospital(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroups = _groups.where((g) => !g.markedForDeletion).toList();

    final int totalBedsSum = activeGroups.fold<int>(
      0,
      (sum, g) => sum + (int.tryParse(g.totalBedsCtrl.text.trim()) ?? 0),
    );
    final int availableBedsSum = activeGroups.fold<int>(
      0,
      (sum, g) => sum + (int.tryParse(g.availableBedsCtrl.text.trim()) ?? 0),
    );
    final int occupiedBeds = (totalBedsSum - availableBedsSum).clamp(0, totalBedsSum);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editHospital : AppTexts.addHospital,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<HospitalFormCubit, HospitalFormState>(
        listener: (context, state) {
          if (state is HospitalFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }
          if (state is HospitalFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is HospitalFormLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hospital info ────────────────────────────────────────
                  _SectionHeader('Hospital Information'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            labelText: AppTexts.name,
                            prefixIcon:
                                const Icon(Icons.local_hospital_outlined),
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Hospital name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _locationCtrl,
                            labelText: AppTexts.location,
                            prefixIcon:
                                const Icon(Icons.location_on_outlined),
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            validator: (v) {
                              if (!_isEdit &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Location is required';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Groups ────────────────────────────────────────────────
                  _SectionHeader('Hospital Groups'),
                  const SizedBox(height: 12),
                  ...List.generate(
                    activeGroups.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Builder(
                        builder: (_) {
                          final draft = activeGroups[index];
                          final sourceIndex = _groups.indexOf(draft);
                          return _GroupCard(
                            key: ValueKey('group_$sourceIndex'),
                            draft: draft,
                            enabled: !isLoading,
                            canRemove: activeGroups.length > 1,
                            onRemove: () {
                              setState(() {
                                final group = _groups[sourceIndex];
                                if (_isEdit && group.id != null) {
                                  group.markedForDeletion = true;
                                } else {
                                  _groups.removeAt(sourceIndex);
                                  group.dispose();
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            setState(() {
                              _groups.add(
                                _GroupDraft(
                                  name: 'Group ${String.fromCharCode(65 + _groups.length)}',
                                ),
                              );
                            });
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Group'),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatChip(
                            label: 'Total',
                            value: totalBedsSum,
                            color: AppColors.accent,
                          ),
                          _StatChip(
                            label: 'Available',
                            value: availableBedsSum,
                            color: AppColors.success,
                          ),
                          _StatChip(
                            label: 'Occupied',
                            value: occupiedBeds,
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Submit ───────────────────────────────────────────────
                  AppButton(
                    label: _isEdit
                        ? AppTexts.editHospital
                        : AppTexts.addHospital,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.local_hospital_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GroupDraft {
  _GroupDraft({
    this.id,
    String name = '',
    String totalBeds = '',
    String availableBeds = '',
  })  : nameCtrl = TextEditingController(text: name),
        totalBedsCtrl = TextEditingController(text: totalBeds),
        availableBedsCtrl = TextEditingController(text: availableBeds);

  final int? id;
  bool markedForDeletion = false;
  final TextEditingController nameCtrl;
  final TextEditingController totalBedsCtrl;
  final TextEditingController availableBedsCtrl;

  void dispose() {
    nameCtrl.dispose();
    totalBedsCtrl.dispose();
    availableBedsCtrl.dispose();
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    super.key,
    required this.draft,
    required this.enabled,
    required this.canRemove,
    required this.onRemove,
  });

  final _GroupDraft draft;
  final bool enabled;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: draft.nameCtrl,
              labelText: 'Group Name',
              prefixIcon: const Icon(Icons.groups_2_outlined),
              textInputAction: TextInputAction.next,
              enabled: enabled,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Group name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: draft.totalBedsCtrl,
              labelText: AppTexts.totalBeds,
              prefixIcon: const Icon(Icons.bed_outlined),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              enabled: enabled,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Total beds is required';
                }
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: draft.availableBedsCtrl,
              labelText: AppTexts.availableBeds,
              prefixIcon: const Icon(Icons.check_circle_outline),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              enabled: enabled,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Available beds is required';
                }
                final available = int.tryParse(v.trim());
                if (available == null || available < 0) {
                  return 'Enter a valid number';
                }
                final total = int.tryParse(draft.totalBedsCtrl.text.trim());
                if (total != null && available > total) {
                  return 'Cannot exceed total beds ($total)';
                }
                return null;
              },
            ),
            if (canRemove) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Group'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toString(),
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}
