import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';

import '../models/doctor_hospital_creation_request.dart';
import '../repository/doctor_hospitals_repository.dart';

class RequestHospitalScreen extends StatefulWidget {
  const RequestHospitalScreen({super.key});

  @override
  State<RequestHospitalScreen> createState() => _RequestHospitalScreenState();
}

class _RequestHospitalScreenState extends State<RequestHospitalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final List<_GroupDraft> _groups = [_GroupDraft(name: 'ICU Wing A')];
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    for (final group in _groups) {
      group.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final request = DoctorHospitalCreationRequest(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        groups: _groups
            .map(
              (g) => DoctorHospitalRequestGroup(
                name: g.nameCtrl.text.trim(),
                totalBeds: int.parse(g.totalBedsCtrl.text.trim()),
              ),
            )
            .toList(),
      );
      await const DoctorHospitalsRepository().submitHospitalRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.hospitalRequestSubmitted),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppTexts.hospitalRequestSubmitFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          AppTexts.requestNewHospital,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(AppTexts.hospitalInformation),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameCtrl,
                        labelText: AppTexts.name,
                        prefixIcon: const Icon(Icons.local_hospital_outlined),
                        textInputAction: TextInputAction.next,
                        enabled: !_loading,
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
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        textInputAction: TextInputAction.next,
                        enabled: !_loading,
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
              const _SectionHeader(AppTexts.hospitalGroups),
              const SizedBox(height: 12),
              ...List.generate(
                _groups.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GroupCard(
                    key: ValueKey('group_$index'),
                    draft: _groups[index],
                    enabled: !_loading,
                    canRemove: _groups.length > 1,
                    onRemove: () {
                      setState(() {
                        final group = _groups.removeAt(index);
                        group.dispose();
                      });
                    },
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _groups.add(
                            _GroupDraft(
                              name:
                                  'ICU Wing ${String.fromCharCode(65 + _groups.length)}',
                            ),
                          );
                        });
                      },
                icon: const Icon(Icons.add),
                label: const Text(AppTexts.addHospitalGroup),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: AppTexts.requestNewHospital,
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
                leadingIcon: const Icon(
                  Icons.send_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupDraft {
  _GroupDraft({
    String name = '',
    String totalBeds = '',
  })  : nameCtrl = TextEditingController(text: name),
        totalBedsCtrl = TextEditingController(text: totalBeds);

  final TextEditingController nameCtrl;
  final TextEditingController totalBedsCtrl;

  void dispose() {
    nameCtrl.dispose();
    totalBedsCtrl.dispose();
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
              labelText: AppTexts.hospitalGroupName,
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
              textInputAction: TextInputAction.done,
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
            if (canRemove) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(AppTexts.removeHospitalGroup),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
