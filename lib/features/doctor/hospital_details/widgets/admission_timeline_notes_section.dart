import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';

import '../models/admission_timeline_note.dart';
import 'admission_details_formatters.dart';
import 'admission_details_section_container.dart';

class AdmissionTimelineNotesSection extends StatefulWidget {
  const AdmissionTimelineNotesSection({
    super.key,
    required this.notes,
    required this.loading,
    required this.sending,
    required this.onRefresh,
    required this.onSend,
    this.asSheet = false,
    this.onOpenAiAssistant,
  });

  final List<AdmissionTimelineNote> notes;
  final bool loading;
  final bool sending;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String content) onSend;
  final bool asSheet;
  final VoidCallback? onOpenAiAssistant;

  @override
  State<AdmissionTimelineNotesSection> createState() =>
      _AdmissionTimelineNotesSectionState();
}

class _AdmissionTimelineNotesSectionState
    extends State<AdmissionTimelineNotesSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.sending) return;
    await widget.onSend(text);
    if (!mounted) return;
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.notes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final listBody = widget.loading && sorted.isEmpty
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : sorted.isEmpty
            ? Center(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 36,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 10),
                      Text(
                        AppTexts.timelineNoteEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: widget.onRefresh,
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final note = sorted[index];
                    final previous =
                        index < sorted.length - 1 ? sorted[index + 1] : null;
                    final showDateSeparator = previous == null ||
                        !_sameDay(previous.createdAt, note.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(label: _dayLabel(note.createdAt)),
                        _TimelineNoteBubble(note: note),
                      ],
                    );
                  },
                ),
              );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.asSheet)
          Expanded(child: listBody)
        else if (sorted.isEmpty || (widget.loading && sorted.isEmpty))
          listBody
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: listBody,
          ),
        const SizedBox(height: 12),
        _ComposerBar(
          controller: _controller,
          focusNode: _focusNode,
          sending: widget.sending,
          onSend: _submit,
        ),
      ],
    );

    if (widget.asSheet) {
      return Material(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        AppTexts.clinicalTimelineSection,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (widget.onOpenAiAssistant != null)
                      IconButton(
                        tooltip: AppTexts.aiClinicalAssistant,
                        onPressed: widget.onOpenAiAssistant,
                        icon: const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: widget.loading ? null : widget.onRefresh,
                      icon: widget.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.refresh_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AdmissionDetailsSectionContainer(
      title: AppTexts.clinicalTimelineSection,
      headerAction: IconButton(
        tooltip: 'Refresh',
        onPressed: widget.loading ? null : widget.onRefresh,
        icon: widget.loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.refresh_outlined,
                size: 20,
                color: AppColors.primary,
              ),
      ),
      child: content,
    );
  }

  bool _sameDay(String a, String b) {
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) return a.substring(0, 10) == b.substring(0, 10);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  String _dayLabel(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return admissionDetailsFormatDate(raw);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _TimelineNoteBubble extends StatelessWidget {
  const _TimelineNoteBubble({required this.note});

  final AdmissionTimelineNote note;

  @override
  Widget build(BuildContext context) {
    final author = note.author;
    final name = (author?.name.trim().isNotEmpty ?? false)
        ? author!.name.trim()
        : 'Unknown';
    final role = author?.role.trim() ?? '';
    final initials = author?.initials ?? '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: AppColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (role.isNotEmpty)
                                TextSpan(
                                  text: ' · $role',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeLabel(note.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) {
      final formatted = admissionDetailsFormatDateTime(raw);
      final parts = formatted.split(' ');
      return parts.length > 1 ? parts.last : formatted;
    }
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              inputFormatters: [
                LengthLimitingTextInputFormatter(5000),
              ],
              decoration: const InputDecoration(
                hintText: AppTexts.timelineNoteHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: sending ? null : onSend,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
