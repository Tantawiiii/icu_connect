import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/constants/app_texts.dart';
import 'package:icu_connect/core/network/network_exceptions.dart';
import 'package:icu_connect/core/widgets/app_button.dart';
import 'package:icu_connect/features/doctor/hospital_details/repository/hospital_admissions_repository.dart';
import 'package:icu_connect/features/doctor/patients/screens/patient_detail_screen.dart';
import 'package:icu_connect/features/doctor/patients/screens/patient_form_screen.dart';
import 'package:icu_connect/features/doctor/patients/widgets/patient_card.dart';
import 'package:icu_connect/features/superAdmin/patients/models/patient_admission_models.dart';

/// Lists all patients for the hospital role (`GET /patients` with pagination).
class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  static const int _perPage = 15;

  final _scrollController = ScrollController();
  final _repository = const HospitalAdmissionsRepository();

  final List<AdmissionPatientModel> _patients = [];
  bool _initialLoading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _initialLoading) return;
    if (_currentPage >= _lastPage) return;
    final pos = _scrollController.position;
    if (!pos.hasViewportDimension) return;
    if (pos.pixels > pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _errorMessage = null;
      _patients.clear();
      _currentPage = 0;
      _lastPage = 1;
    });
    try {
      final page = await _repository.listPatientsPage(page: 1, perPage: _perPage);
      if (!mounted) return;
      setState(() {
        _patients.addAll(page.patients);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _initialLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load patients.';
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final next = _currentPage + 1;
    if (next > _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.listPatientsPage(page: next, perPage: _perPage);
      if (!mounted) return;
      setState(() {
        _patients.addAll(page.patients);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _loadingMore = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  String _metaLine(AdmissionPatientModel p) {
    final parts = <String>[
      '${AppTexts.age}: ${p.age}',
      if (p.gender.isNotEmpty) p.gender,
      if (p.phone.isNotEmpty) p.phone,
    ];
    return parts.join(' · ');
  }

  String _badge(AdmissionPatientModel p) {
    if (p.bloodGroup.isNotEmpty) return p.bloodGroup;
    if (p.nationalId.isNotEmpty) return '#${p.nationalId.length > 8 ? '${p.nationalId.substring(0, 8)}…' : p.nationalId}';
    return AppTexts.notAvailable;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PatientFormScreen()),
    );
    if (created == true && mounted) _loadFirstPage();
  }

  Future<void> _openEdit(AdmissionPatientModel p) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PatientFormScreen(existing: p)),
    );
    if (updated == true && mounted) _loadFirstPage();
  }

  Future<void> _deletePatient(AdmissionPatientModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTexts.deletePatientAdmin),
        content: Text(AppTexts.deletePatientConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppTexts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppTexts.deletePatientAdmin,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repository.deletePatient(p.id);
      if (!mounted) return;
      setState(() => _patients.removeWhere((x) => x.id == p.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppTexts.patientDeleted),
          backgroundColor: AppColors.success,
        ),
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text(
          AppTexts.addPatientAdmin,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          AppTexts.patientsLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: AppTexts.retry,
                          onPressed: _loadFirstPage,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadFirstPage,
                  child: _patients.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No patients yet.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _patients.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _patients.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              );
                            }
                            final p = _patients[index];
                            return PatientCardWidget(
                              name: p.name,
                              bedNumber: _badge(p),
                              admittedDate: _metaLine(p),
                              plainDetailLine: true,
                              onTap: () async {
                                final refreshed =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PatientDetailScreen(patientId: p.id),
                                  ),
                                );
                                if (refreshed == true && mounted) {
                                  _loadFirstPage();
                                }
                              },
                              onEdit: () => _openEdit(p),
                              onDelete: () => _deletePatient(p),
                            );
                          },
                        ),
                ),
    );
  }
}
