import 'package:flutter/material.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/core/widgets/app_text_field.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

import 'admission_details_empty_hint.dart';
import 'admission_details_item_actions.dart';
import 'admission_details_section_container.dart';

class AdmissionPlansSection extends StatefulWidget {
  const AdmissionPlansSection({
    super.key,
    required this.plans,
    required this.adding,
    required this.editingItemId,
    required this.saving,
    required this.contentController,
    required this.onStartAdd,
    required this.onCancelAdd,
    required this.onSaveAdd,
    required this.onBeginEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onDelete,
  });

  final List<TreatmentPlanModel> plans;
  final bool adding;
  final int? editingItemId;
  final bool saving;
  final TextEditingController contentController;
  final VoidCallback onStartAdd;
  final VoidCallback onCancelAdd;
  final VoidCallback onSaveAdd;
  final void Function(TreatmentPlanModel plan) onBeginEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final void Function(int id) onDelete;

  @override
  State<AdmissionPlansSection> createState() => _AdmissionPlansSectionState();
}

class _AdmissionPlansSectionState extends State<AdmissionPlansSection> {
  final Set<int> _completedIds = {};

  @override
  void didUpdateWidget(covariant AdmissionPlansSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final aliveIds = widget.plans.map((p) => p.id).toSet();
    _completedIds.removeWhere((id) => !aliveIds.contains(id));
  }

  void _toggleCompleted(int id) {
    setState(() {
      if (_completedIds.contains(id)) {
        _completedIds.remove(id);
      } else {
        _completedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = !widget.adding && widget.editingItemId == null;

    return AdmissionDetailsSectionContainer(
      title: AppTexts.plansSection,
      headerAction: canAdd
          ? IconButton(
              tooltip: 'Add plan',
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              onPressed: widget.onStartAdd,
            )
          : null,
      child: Column(
        children: [
          if (widget.adding)
            _PlanForm(
              title: 'Add plan',
              saving: widget.saving,
              contentController: widget.contentController,
              onCancel: widget.onCancelAdd,
              onSave: widget.onSaveAdd,
            ),
          if (widget.plans.isEmpty && !widget.adding)
            const AdmissionDetailsEmptyHint('No plans recorded.')
          else
            for (final plan in widget.plans) ...[
              if (widget.editingItemId == plan.id)
                _PlanForm(
                  title: 'Edit plan',
                  isEditing: true,
                  saving: widget.saving,
                  contentController: widget.contentController,
                  onCancel: widget.onCancelEdit,
                  onSave: widget.onSaveEdit,
                )
              else
                _PlanChecklistTile(
                  plan: plan,
                  completed: _completedIds.contains(plan.id),
                  onToggle: () => _toggleCompleted(plan.id),
                  onEdit: () => widget.onBeginEdit(plan),
                  onDelete: () => widget.onDelete(plan.id),
                ),
            ],
        ],
      ),
    );
  }
}

class _PlanChecklistTile extends StatelessWidget {
  const _PlanChecklistTile({
    required this.plan,
    required this.completed,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TreatmentPlanModel plan;
  final bool completed;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: completed,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              plan.planContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: completed
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 14,
                decoration: completed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
          AdmissionDetailsItemActions(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _PlanForm extends StatelessWidget {
  const _PlanForm({
    required this.title,
    required this.saving,
    required this.contentController,
    required this.onCancel,
    required this.onSave,
    this.isEditing = false,
  });

  final String title;
  final bool saving;
  final TextEditingController contentController;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: saving ? null : onCancel,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          AppTextField(
            controller: contentController,
            hintText: 'Plan content *',
            maxLines: 4,
            enabled: !saving,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: AppButton(
              label: saving
                  ? 'Saving...'
                  : isEditing
                  ? AppTexts.saveChanges
                  : 'Save Entry',
              onPressed: saving ? null : onSave,
            ),
          ),
        ],
      ),
    );
  }
}
