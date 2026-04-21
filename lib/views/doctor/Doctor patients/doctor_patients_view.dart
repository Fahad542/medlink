import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/user_model.dart';
import 'package:medlink/views/Patient App/consultation/chat_view.dart';
import 'package:medlink/views/Patient App/consultation/waiting_room_view.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
// import 'package:medlink/views/doctor/Patient%20Dashboard/patient_dashboard_view.dart';

import 'package:provider/provider.dart';
import 'package:medlink/views/doctor/Doctor%20patients/doctor_patients_view_model.dart';

import '../Doctor Patient Dashboard/patient_dashboard_view.dart';
import '../Doctor Patient Dashboard/doctor_patient_dashboard_view_model.dart';
import 'package:medlink/widgets/no_data_widget.dart';
// ... other imports ...

import 'package:medlink/views/services/session_view_model.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';

class DoctorPatientsView extends StatefulWidget {
  final bool showBackButton;
  const DoctorPatientsView({super.key, this.showBackButton = false});

  @override
  State<DoctorPatientsView> createState() => _DoctorPatientsViewState();
}

class _DoctorPatientsViewState extends State<DoctorPatientsView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;
  bool _syncedTabWithViewModel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onPatientTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedTabWithViewModel) return;
    _syncedTabWithViewModel = true;
    final vm = Provider.of<DoctorPatientsViewModel>(context, listen: false);
    final idx = vm.selectedFilterIndex.clamp(0, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tabController.index != idx) {
        _tabController.index = idx;
      }
    });
  }

  void _onPatientTabChanged() {
    if (_tabController.indexIsChanging) return;
    final vm = Provider.of<DoctorPatientsViewModel>(context, listen: false);
    if (vm.selectedFilterIndex != _tabController.index) {
      vm.setFilterIndex(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onPatientTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DoctorPatientsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          appBar: CustomAppBar(
            title: "My Patients",
            automaticallyImplyLeading: widget.showBackButton,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.9),
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: viewModel.filters[0]),
                    Tab(text: viewModel.filters[1]),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildSearchBar(viewModel),
              ),

              // Patient List
              Expanded(
                child: viewModel.isLoading
                    ? const DoctorPatientListShimmer()
                    : viewModel.patients.isEmpty
                        ? const Stack(
                            children: [
                              Align(
                                alignment: Alignment(0, -0.25),
                                child: NoDataWidget(
                                  title: "No patients found.",
                                  subTitle:
                                      "You don't have any patients in this category yet.",
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 0, bottom: 100),
                            itemCount: viewModel.patients.length,
                            itemBuilder: (context, index) {
                              final patient = viewModel.patients[index];
                              return _buildPatientCard(patient);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(DoctorPatientsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // Removed color from container
      ),
      child: TextField(
        controller: _searchController,
        onChanged: viewModel.setSearchQuery,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "Search patients...",
          hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.grey[400], size: 18),
                  onPressed: () {
                    _searchController.clear();
                    viewModel.setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> data) {
    final patient = data['user'] as UserModel;
    final sessions = data['sessions'] as int;
    final nextSession = data['nextSession'] as String?;
    final isCurrent = data['isCurrent'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => DoctorPatientDashboardViewModel(patient)
                    ..fetchPatientProfile(),
                  child: const PatientDashboardView(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Row: Avatar & Basic Info & Actions
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.08),
                        image: (patient.profileImage != null &&
                                patient.profileImage!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(patient.profileImage!),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: (patient.profileImage == null ||
                              patient.profileImage!.isEmpty)
                          ? Center(
                              child: Text(
                                patient.name.isNotEmpty
                                    ? patient.name.substring(0, 2).toUpperCase()
                                    : "??",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 16),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    // Names & Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                patient.name ?? "Unknown",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  "${patient.age} yrs",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "$sessions Sessions",
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppColors.primary),
                              ),
                              if (isCurrent && nextSession != null) ...[
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  width: 1,
                                  height: 12,
                                  color: Colors.grey[300],
                                ),
                                Icon(Icons.calendar_today_rounded,
                                    size: 10, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    nextSession,
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showPatientOptions(context, patient),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.more_vert, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPatientOptions(BuildContext context, UserModel patient) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    "Contact ${patient.name}",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    final userVM =
                        Provider.of<UserViewModel>(context, listen: false);
                    final uId = userVM.loginSession?.data?.user?.id?.toString();
                    final dId = userVM.doctor?.id;
                    final currentUserId = (uId != null && uId.isNotEmpty)
                        ? uId
                        : (dId != null && dId.isNotEmpty)
                            ? dId
                            : "0";
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatView(
                                recipientName: patient.name ?? "Patient",
                                profileImage: patient.profileImage ?? "",
                                appointmentId: patient.lastAppointmentId ?? "0",
                                doctorId: currentUserId.toString(),
                                patientId: patient.id.toString(),
                                )),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset("assets/Icons/chat.png",
                              width: 16, height: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Send a Message",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Start a chat conversation",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WaitingRoomView(
                                callTargetName: patient.name,
                                isDoctor: true,
                                appointmentId: patient.lastAppointmentId,
                              )),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset("assets/Icons/video.png",
                              width: 22, height: 22, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Start Video Call",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Connect via video call",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
