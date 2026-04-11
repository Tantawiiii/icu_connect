import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';

import '../models/hospital_doctor.dart';
import '../repository/hospital_doctors_repository.dart';
import 'doctor_card.dart';

class AddDoctorBottomSheet extends StatefulWidget {
  const AddDoctorBottomSheet({
    super.key,
    required this.hospitalId,
    required this.onListsChanged,
  });

  final int hospitalId;
  final VoidCallback onListsChanged;

  @override
  State<AddDoctorBottomSheet> createState() => _AddDoctorBottomSheetState();
}

class _AddDoctorBottomSheetState extends State<AddDoctorBottomSheet> {
  static const _repo = HospitalDoctorsRepository();

  bool _loading = true;
  String? _error;
  List<HospitalDoctor> _pendingPool = [];
  List<HospitalDoctor> _inactivePending = [];

  final Set<int> _addingIds = {};
  final Set<int> _acceptingIds = {};
  final Set<int> _activatingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.fetchPendingDoctorsPool(widget.hospitalId),
        _repo.fetchInactivePendingDoctorRequests(widget.hospitalId),
      ]);
      if (!mounted) return;
      setState(() {
        _pendingPool = results[0];
        _inactivePending = results[1];
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load doctors.';
        _loading = false;
      });
    }
  }

  Future<void> _afterMutation(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      widget.onListsChanged();
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _load();
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addDoctor(int doctorId) async {
    if (_addingIds.contains(doctorId)) return;
    setState(() => _addingIds.add(doctorId));
    await _afterMutation(
      () async {
        await _repo.addDoctorToHospital(
          hospitalId: widget.hospitalId,
          doctorId: doctorId,
        );
      },
      successMessage: AppTexts.doctorAddedSuccessfully,
    );
    if (mounted) setState(() => _addingIds.remove(doctorId));
  }

  Future<void> _accept(int doctorId) async {
    if (_acceptingIds.contains(doctorId)) return;
    setState(() => _acceptingIds.add(doctorId));
    await _afterMutation(() async {
      await _repo.acceptDoctor(
        hospitalId: widget.hospitalId,
        doctorId: doctorId,
      );
    });
    if (mounted) setState(() => _acceptingIds.remove(doctorId));
  }

  Future<void> _activate(int doctorId) async {
    if (_activatingIds.contains(doctorId)) return;
    setState(() => _activatingIds.add(doctorId));
    await _afterMutation(() async {
      await _repo.activateDoctor(doctorId);
    });
    if (mounted) setState(() => _activatingIds.remove(doctorId));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppTexts.addDoctor,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: AppTexts.retry,
                      width: 160,
                      onPressed: _load,
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH.clamp(200, 900)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(AppTexts.addDoctorPendingPoolSection),
                      const SizedBox(height: 8),
                      if (_pendingPool.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            AppTexts.notAvailable,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ..._pendingPool.map(_buildPoolTile),
                      _sectionTitle(AppTexts.addDoctorRequestsSection),
                      const SizedBox(height: 8),
                      if (_inactivePending.isEmpty)
                        const Text(
                          AppTexts.notAvailable,
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        ..._inactivePending.map(_buildRequestCard),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildPoolTile(HospitalDoctor d) {
    final adding = _addingIds.contains(d.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.email,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 88,
                child: AppButton(
                  label: AppTexts.add,
                  height: 40,
                  isLoading: adding,
                  onPressed: adding ? null : () => _addDoctor(d.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(HospitalDoctor d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DoctorCard(
        doctor: d,
        isAdmin: true,
        accepting: _acceptingIds.contains(d.id),
        activating: _activatingIds.contains(d.id),
        onAccept: () => _accept(d.id),
        onActivate: () => _activate(d.id),
      ),
    );
  }
}
