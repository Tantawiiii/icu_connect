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
  late final TextEditingController _totalBedsCtrl;
  late final TextEditingController _availableBedsCtrl;

  bool get _isEdit => widget.hospital != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.hospital?.name ?? '');
    _locationCtrl =
        TextEditingController(text: widget.hospital?.location ?? '');
    _totalBedsCtrl = TextEditingController(
        text: widget.hospital != null
            ? widget.hospital!.totalBeds.toString()
            : '');
    _availableBedsCtrl = TextEditingController(
        text: widget.hospital != null
            ? widget.hospital!.availableBeds.toString()
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _totalBedsCtrl.dispose();
    _availableBedsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final totalBeds = int.tryParse(_totalBedsCtrl.text.trim()) ?? 0;
    final availableBeds = int.tryParse(_availableBedsCtrl.text.trim()) ?? 0;

    final request = HospitalRequest(
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      totalBeds: totalBeds,
      availableBeds: availableBeds,
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
                              if (v == null || v.trim().isEmpty) {
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

                  // ── Bed capacity ─────────────────────────────────────────
                  _SectionHeader('Bed Capacity'),
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
                            controller: _totalBedsCtrl,
                            labelText: AppTexts.totalBeds,
                            prefixIcon: const Icon(Icons.bed_outlined),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
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
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _availableBedsCtrl,
                            labelText: AppTexts.availableBeds,
                            prefixIcon:
                                const Icon(Icons.check_circle_outline),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Available beds is required';
                              }
                              final available = int.tryParse(v.trim());
                              if (available == null || available < 0) {
                                return 'Enter a valid number';
                              }
                              final total = int.tryParse(
                                  _totalBedsCtrl.text.trim());
                              if (total != null &&
                                  available > total) {
                                return 'Cannot exceed total beds ($total)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Preview card (only shown in edit mode when values entered)
                  if (_isEdit) ...[
                    const SizedBox(height: 20),
                    _SectionHeader('Current Occupancy'),
                    const SizedBox(height: 12),
                    _OccupancyPreview(
                      totalCtrl: _totalBedsCtrl,
                      availableCtrl: _availableBedsCtrl,
                    ),
                  ],

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

// ── Occupancy preview (live-updating) ─────────────────────────────────────────

class _OccupancyPreview extends StatefulWidget {
  const _OccupancyPreview({
    required this.totalCtrl,
    required this.availableCtrl,
  });

  final TextEditingController totalCtrl;
  final TextEditingController availableCtrl;

  @override
  State<_OccupancyPreview> createState() => _OccupancyPreviewState();
}

class _OccupancyPreviewState extends State<_OccupancyPreview> {
  @override
  void initState() {
    super.initState();
    widget.totalCtrl.addListener(_rebuild);
    widget.availableCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.totalCtrl.removeListener(_rebuild);
    widget.availableCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = int.tryParse(widget.totalCtrl.text.trim()) ?? 0;
    final available = int.tryParse(widget.availableCtrl.text.trim()) ?? 0;
    final occupied = (total - available).clamp(0, total);
    final rate = total > 0 ? occupied / total : 0.0;

    final Color barColor = rate < 0.5
        ? AppColors.success
        : rate < 0.8
            ? const Color(0xFFF59E0B)
            : AppColors.error;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(label: 'Total', value: total, color: AppColors.accent),
                _StatChip(
                    label: 'Available',
                    value: available,
                    color: AppColors.success),
                _StatChip(
                    label: 'Occupied', value: occupied, color: AppColors.error),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Occupancy rate',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  '${(rate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 12,
                      color: barColor,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate,
                minHeight: 8,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
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
