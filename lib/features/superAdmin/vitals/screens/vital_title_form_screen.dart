import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_texts.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/vitals_titles_cubit.dart';
import '../cubit/vitals_titles_state.dart';
import '../models/vital_title_model.dart';
import '../models/vital_title_request.dart';

/// Push with [BlocProvider.value] from [VitalsTitlesListScreen] so the cubit
/// is in scope (a new route is not under the list’s [BlocProvider]).
class VitalTitleFormScreen extends StatelessWidget {
  const VitalTitleFormScreen({super.key, this.vital});

  final VitalTitleModel? vital;

  @override
  Widget build(BuildContext context) {
    return _VitalTitleFormView(vital: vital);
  }
}

class _VitalTitleFormView extends StatefulWidget {
  const _VitalTitleFormView({this.vital});

  final VitalTitleModel? vital;

  @override
  State<_VitalTitleFormView> createState() => _VitalTitleFormViewState();
}

class _VitalTitleFormViewState extends State<_VitalTitleFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  bool get _isEdit => widget.vital != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.vital?.title ?? '');
    _unitCtrl = TextEditingController(text: widget.vital?.unit ?? '');
    _minCtrl =
        TextEditingController(text: widget.vital?.normalRangeMin ?? '');
    _maxCtrl =
        TextEditingController(text: widget.vital?.normalRangeMax ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _unitCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _onRangeFieldChanged() {
    _formKey.currentState?.validate();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final min = double.tryParse(_minCtrl.text.trim()) ?? 0;
    final max = double.tryParse(_maxCtrl.text.trim()) ?? 0;
    if (max <= min) return;

    final request = VitalTitleRequest(
      title: _titleCtrl.text.trim(),
      unit: _unitCtrl.text.trim(),
      normalRangeMin: min,
      normalRangeMax: max,
    );

    final cubit = context.read<VitalsTitlesCubit>();
    if (_isEdit) {
      cubit.updateVitalTitle(widget.vital!.id, request);
    } else {
      cubit.createVitalTitle(request);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEdit ? AppTexts.editVitalTitle : AppTexts.addVitalTitle,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<VitalsTitlesCubit, VitalsTitlesState>(
        builder: (context, state) {
          final isLoading = state is VitalsTitlesLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _titleCtrl,
                    labelText: AppTexts.name,
                    prefixIcon: const Icon(Icons.monitor_heart_outlined),
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _unitCtrl,
                    labelText: AppTexts.unit,
                    prefixIcon: const Icon(Icons.straighten_outlined),
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Unit is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _minCtrl,
                          labelText: AppTexts.normalRangeMin,
                          prefixIcon: const Icon(Icons.arrow_downward),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          onChanged: (_) => _onRangeFieldChanged(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _maxCtrl,
                          labelText: AppTexts.normalRangeMax,
                          prefixIcon: const Icon(Icons.arrow_upward),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          onChanged: (_) => _onRangeFieldChanged(),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Required';
                            }
                            final maxVal = double.tryParse(v.trim());
                            if (maxVal == null) {
                              return 'Invalid';
                            }
                            final minVal =
                                double.tryParse(_minCtrl.text.trim());
                            if (minVal != null && maxVal <= minVal) {
                              return AppTexts.normalRangeMaxMustExceedMin;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit
                        ? AppTexts.editVitalTitle
                        : AppTexts.addVitalTitle,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submit,
                    leadingIcon: Icon(
                      _isEdit
                          ? Icons.save_outlined
                          : Icons.monitor_heart_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

