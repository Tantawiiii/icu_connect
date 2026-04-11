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
  static const int _perPage = 10;

  final _repository = const HospitalAdmissionsRepository();
  final _searchController = TextEditingController();

  final List<AdmissionPatientModel> _patients = [];
  bool _initialLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() {});
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _errorMessage = null;
      _patients.clear();
      _currentPage = 0;
      _lastPage = 1;
      _total = 0;
    });
    try {
      final page = await _repository.listPatientsPage(
        page: 1,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        _patients.addAll(page.patients);
        _currentPage = page.currentPage;
        _lastPage = page.lastPage;
        _total = page.total;
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

  Future<void> _loadPage(int page) async {
    if (page < 1 || page > _lastPage) return;
    setState(() {
      _initialLoading = true;
      _errorMessage = null;
    });
    try {
      final result =
          await _repository.listPatientsPage(
        page: page,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        _patients
          ..clear()
          ..addAll(result.patients);
        _currentPage = result.currentPage;
        _lastPage = result.lastPage;
        _total = result.total;
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
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(builder: (_) => const PatientFormScreen()),
    );
    if (mounted && (result is int || result == true)) _loadFirstPage();
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
    final query = _searchController.text.trim().toLowerCase();
    final filteredPatients = query.isEmpty
        ? _patients
        : _patients.where((p) {
            if (p.name.toLowerCase().contains(query)) return true;
            if (p.nationalId.toLowerCase().contains(query)) return true;
            if (p.phone.toLowerCase().contains(query)) return true;
            if (p.bloodGroup.toLowerCase().contains(query)) return true;
            return false;
          }).toList();

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
                  onRefresh: () => _loadPage(_currentPage == 0 ? 1 : _currentPage),
                  child: _patients.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _applySearch(),
                                decoration: InputDecoration(
                                  hintText: 'Search patients',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.textSecondary,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _applySearch();
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 120),
                            const Center(
                              child: Text(
                                'No patients yet.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _applySearch(),
                                decoration: InputDecoration(
                                  hintText: 'Search patients',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.textSecondary,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            _applySearch();
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _total == 0
                                    ? 'Showing 0-0 of 0 patients'
                                    : 'Showing ${((_currentPage - 1) * _perPage) + 1}-'
                                        '${(((_currentPage - 1) * _perPage) + filteredPatients.length)} '
                                        'of $_total patients',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            ...filteredPatients.map(
                              (p) => PatientCardWidget(
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
                              ),
                            ),
                            const SizedBox(height: 6),
                            _PaginationControls(
                              currentPage: _currentPage,
                              lastPage: _lastPage,
                              onPrevious: () => _loadPage(_currentPage - 1),
                              onNext: () => _loadPage(_currentPage + 1),
                            ),
                          ],
                        ),
                ),
    );
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.lastPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int lastPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final safeCurrent = currentPage <= 0 ? 1 : currentPage;
    final isFirst = safeCurrent <= 1;
    final isLast = safeCurrent >= lastPage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirst ? null : onPrevious,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$safeCurrent/$lastPage',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLast ? null : onNext,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
