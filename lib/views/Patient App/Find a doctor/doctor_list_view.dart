import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/views/Patient%20App/prescription/doctor_viewmodel.dart';
import 'package:medlink/views/Patient%20App/Find%20a%20doctor/doctor_list_view_model.dart'; // Import local VM
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/views/doctor/Doctor%20profile/doctor_profile_view.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/widgets/shimmer_widgets.dart';
import 'package:medlink/widgets/doctor_card.dart';
import 'package:medlink/widgets/no_data_widget.dart';
import 'package:provider/provider.dart';

class DoctorListView extends StatelessWidget {
  final String? initialCategory;
  final int? categoryId;

  const DoctorListView({super.key, this.initialCategory, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = DoctorListViewModel();
        if (initialCategory != null) {
          // Map "General" to "General Practitioner" if needed, or other fuzzy matches
          String cat = initialCategory!;
          if(cat == "General") cat = "General Practitioner";
          vm.setSelectedSpecialty(cat);
        }
        // Fetch according to category or all doctors via the new logic
        if (categoryId != null) {
          vm.loadDoctorsBySpecialty(categoryId!);
        } else {
          vm.loadAllDoctors();
        }
        return vm;
      },
      child: const _DoctorListViewContent(),
    );
  }
}

class _DoctorListViewContent extends StatelessWidget {
  const _DoctorListViewContent();

  @override
  Widget build(BuildContext context) {
    final localVM = Provider.of<DoctorListViewModel>(context); // Local UI Logic & Data

    final filteredDoctors = localVM.localDoctors.where((doctor) {
      bool matchesSearch = localVM.searchQuery.isEmpty || 
          doctor.name.toLowerCase().contains(localVM.searchQuery.toLowerCase());
      bool matchesSpecialty = localVM.selectedSpecialty == null || 
          doctor.specialty == localVM.selectedSpecialty;
      bool matchesLocation = localVM.selectedLocation == null || 
          doctor.location == localVM.selectedLocation;
      return matchesSearch && matchesSpecialty && matchesLocation;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: "Find a Doctor"),

      body: Stack(
        children: [
          // 1. Content Layer
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: TextField(
                    onChanged: (value) {
                       localVM.setSearchQuery(value);
                    },
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search doctor name...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          _showMainFilterSheet(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Light grey
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.tune_rounded, color: Colors.black87, size: 18),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Headers and List
              if (!localVM.isLoadingDoctors && filteredDoctors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      localVM.selectedSpecialty != null ? "${localVM.selectedSpecialty} Doctors" : "All Doctors",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: localVM.isLoadingDoctors
                    ? const DoctorListShimmer()
                    : filteredDoctors.isEmpty 
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filteredDoctors.length, 
                            itemBuilder: (context, index) {
                              return DoctorCard(
                                doctor: filteredDoctors[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DoctorProfileView(doctor: filteredDoctors[index]),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),

          // 2. Empty State Overlay (Slightly above center)
          if (!localVM.isLoadingDoctors && filteredDoctors.isEmpty)
            Align(
              alignment: const Alignment(0, -0.2), // Moves it 10% up from center
              child: NoDataWidget(
                title: localVM.selectedSpecialty != null 
                    ? "No ${localVM.selectedSpecialty} Doctors Found" 
                    : (localVM.searchQuery.isNotEmpty 
                        ? "No \"${localVM.searchQuery}\" Found"
                        : "No Doctors Found"),
                subTitle: "Try adjusting your search or filters to find more doctors.",
              ),
            ),
        ],
      ),
    );
  }

  void _showMainFilterSheet(BuildContext context) {
    final localVM = Provider.of<DoctorListViewModel>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: localVM,
          child: Consumer<DoctorListViewModel>(
            builder: (context, vm, child) {
              // Inject Dynamic Categories from DoctorViewModel
              final doctorVM = Provider.of<DoctorViewModel>(context, listen: true);
              if (doctorVM.categories.isNotEmpty) {
                  // Only set if different to avoid infinite loop or unnecessary rebuilds
                  // In a real scenario, compare lists. For now, we trust the VM handling.
                  // Better: pass it directly to the UI components below instead of setting it in the VM during build.
                  // However, to keep existing structure:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                     vm.setSpecialtyOptions(doctorVM.categories);
                  });
              }

              return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 60),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Reset
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Filter Doctors",
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    vm.setSelectedSpecialty(null);
                                    vm.setSelectedLocation(null);
                                    Navigator.pop(sheetContext);
                                  },
                                  child: Text(
                                    "Reset",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Options
                            _buildFilterOptionTile(
                              context,
                              "Specialty",
                              "Select Specialist",
                              Icons.medical_services_outlined,
                              vm.selectedSpecialty,
                              () {
                                // Stack the sheet on top -> Remove pop
                                _showFilterOptions(context, "Specialty", vm.specialtyOptions);
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildFilterOptionTile(
                              context,
                              "Location",
                              "Select Location",
                              Icons.location_on_outlined,
                              vm.selectedLocation,
                              () {
                                 // Stack the sheet on top -> Remove pop
                                 _showFilterOptions(context, "Location", vm.locationOptions);
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Show Results Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text("Show Results", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Floating Close Button
                Positioned(
                  right: 16,
                  top: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: const Icon(Icons.close, size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            );
          }
        ));
      },
    );
  }

  // Refined Helper
  Widget _buildFilterOptionTile(
      BuildContext context, 
      String title, 
      String subtitle,
      IconData icon, 
      String? selectedValue, 
      VoidCallback onTap) {
        
    final isSelected = selectedValue != null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Reduced radius
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Reduced padding
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), // Reduced Icon padding
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                 boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : Colors.black87, size: 18), // Reduced icon size
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14, // Reduced font
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                     selectedValue ?? subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12, 
                      color: isSelected ? AppColors.primary : Colors.grey[500], 
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400
                    ),
                  )
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }



  void _showFilterOptions(BuildContext context, String title, List<String> options) {
    final vm = Provider.of<DoctorListViewModel>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _FilterSheetContent(title: title, options: options, scrollController: controller),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterSheetContent extends StatefulWidget {
  final String title;
  final List<String> options;
  final ScrollController scrollController;

  const _FilterSheetContent({required this.title, required this.options, required this.scrollController});

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  // We keep the filter UI state internal to this widget as it is ephemeral UI state (filtering the list in the sheet)
  // But we use logic from ViewModel where possible, or keep it strict if desired. 
  // For this sheet, it's UI logic mostly.
  late List<String> _filteredOptions;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
  }
  
  void _filterOptions(String query) {
     // We can use the VM helper if we pass VM down or use Provider, 
     // but since this is a separate state class, we'd need to access Provider.
     // For simplicity and to obey "logic in VM", this simple list filter stays here as UI helper OR we call VM.
     setState(() {
        _filteredOptions = widget.options
           .where((element) => element.toLowerCase().contains(query.toLowerCase()))
           .toList();
     });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8), // Reduced margins
            width: 36, // Smaller handle
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            "Select ${widget.title}",
            style: GoogleFonts.inter(
              fontSize: 17, // Smaller font
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 42, // Explicit compact height
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOptions,
              textAlignVertical: TextAlignVertical.center, // Center text vertically
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: "Search ${widget.title.toLowerCase()}...",
                hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13), // Smaller hint
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12), // Compact padding
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        // List
        Expanded(
          child: _filteredOptions.isEmpty 
          ? Center(child: Text("No ${widget.title.toLowerCase()} found", style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)))
          : ListView.separated(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _filteredOptions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF8FAFC)), // Lighter separator
            itemBuilder: (context, index) {
              final option = _filteredOptions[index];
              return InkWell(
                onTap: () {
                   // Update local VM via Provider (dirty way since we are in a separate state class)
                   // Ideally callback. But we can just use Provider here since it's inside the widget tree.
                   final localVM = Provider.of<DoctorListViewModel>(context, listen: false);
                   if (widget.title == "Specialty") {
                     localVM.setSelectedSpecialty(option);
                   } else {
                     localVM.setSelectedLocation(option);
                   }
                   Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Compact list item
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontSize: 14, // Smaller font
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]), // Smaller arrow
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

