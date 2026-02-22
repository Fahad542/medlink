import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';

class PrescriptionBottomSheet extends StatefulWidget {
  const PrescriptionBottomSheet({super.key});

  @override
  State<PrescriptionBottomSheet> createState() => _PrescriptionBottomSheetState();
}

class _PrescriptionBottomSheetState extends State<PrescriptionBottomSheet> {
  // State for the list of items
  final List<Map<String, String>> _medicines = [];
  final List<String> _labTests = [];
  
  // View State (0: List, 1: Add Medicine, 2: Add Lab Test)
  int _currentView = 0; 

  // Consultation Controllers
  final TextEditingController _complaintCtrl = TextEditingController();
  final TextEditingController _diagnosisCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();
  
  // Vitals Controllers
  final TextEditingController _bpCtrl = TextEditingController();
  final TextEditingController _pulseCtrl = TextEditingController();
  final TextEditingController _tempCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();

  // Controllers for Medicine
  final TextEditingController _medNameCtrl = TextEditingController();
  final TextEditingController _medDosageCtrl = TextEditingController();
  final TextEditingController _medDurationCtrl = TextEditingController();
  final TextEditingController _medInstructionCtrl = TextEditingController();
  String _selectedFrequency = "Twice Daily";
  final List<String> _frequencies = ["Once Daily", "Twice Daily", "Thrice Daily", "SOS"];
  
  // Duration State
  String _durationUnit = "Days";
  int _durationValue = 3;
  final List<String> _durationUnits = ["Days", "Weeks", "Months"];

  // Controller for Lab Test
  final TextEditingController _testNameCtrl = TextEditingController();

  void _addMedicine() {
    if (_medNameCtrl.text.isNotEmpty) {
      setState(() {
        _medicines.add({
          "name": _medNameCtrl.text,
          "dosage": "${_medDosageCtrl.text} mg",
          "duration": "$_durationValue $_durationUnit",
          "frequency": _selectedFrequency,
          "instruction": _medInstructionCtrl.text,
        });
        _resetMedicineForm();
        _currentView = 0; // Go back to list
      });
    }
  }

  void _addLabTest() {
    if (_testNameCtrl.text.isNotEmpty) {
      setState(() {
        _labTests.add(_testNameCtrl.text);
        _testNameCtrl.clear();
        _currentView = 0; // Go back to list
      });
    }
  }

  void _resetMedicineForm() {
    _medNameCtrl.clear();
    _medDosageCtrl.clear();
    _medDurationCtrl.clear();
    _medInstructionCtrl.clear();
    _selectedFrequency = "Twice Daily";
    _durationUnit = "Days";
    _durationValue = 3;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA), // Premium off-white background
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)), // Slightly more rounded
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12,
        left: 0, // Zero padding for full width cards
        right: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Content NOTE: Moving padding inside
          Expanded(
             child: _currentView == 0 
                  ? Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildMainView())
                  : Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _currentView == 1 ? _buildAddMedicineView() : _buildAddLabTestView()),
          ),
        ],
      ),
    );
  }

  // --- Views ---

  Widget _buildMainView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Consultation", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text("Dr. Smith • ${DateTime.now().toString().split(' ')[0]}", style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                ]
              ),
              child: InkWell(
                onTap: () {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription Saved!")));
                },
                borderRadius: BorderRadius.circular(30),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text("Finalize", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Clinical Notes Card
                _buildCardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Clinical Assessment", Icons.assignment_ind_outlined),
                      const SizedBox(height: 12),
                      _buildTransparentField("Chief Complaint", _complaintCtrl),
                      const Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      _buildTransparentField("Provisional Diagnosis", _diagnosisCtrl),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Vitals Card
                _buildCardContainer(
                  child: Column(
                    children: [
                      _buildSectionHeader("Vitals", Icons.monitor_heart_outlined),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildVitalItem("BP", "mmHg", _bpCtrl)),
                          Container(width: 1, height: 30, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 12)),
                          Expanded(child: _buildVitalItem("Pulse", "bpm", _pulseCtrl)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildVitalItem("Temp", "°F", _tempCtrl)),
                          Container(width: 1, height: 30, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 12)),
                          Expanded(child: _buildVitalItem("Weight", "kg", _weightCtrl)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Medicines
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle("MEDICATIONS"),
                    InkWell(
                      onTap: () => setState(() => _currentView = 1),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: const [
                            Icon(Icons.add_circle_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text("ADD NEW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_medicines.isEmpty)
                  _buildEmptyState("No medicines prescribed yet")
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicines.length,
                    separatorBuilder: (_,__) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _buildMedicineCard(index),
                  ),
                
                const SizedBox(height: 24),

                // 4. Lab Tests
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle("LAB INVESTIGATIONS"),
                    InkWell(
                      onTap: () => setState(() => _currentView = 2),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: const [
                            Icon(Icons.add_circle_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text("ADD NEW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_labTests.isEmpty)
                   _buildEmptyState("No lab tests advised")
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _labTests.map((test) => Chip(
                      label: Text(test, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      deleteIcon: Icon(Icons.close, size: 14, color: Colors.grey[400]),
                      onDeleted: () => setState(() => _labTests.remove(test)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[200]!)
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    )).toList(),
                  ),

                const SizedBox(height: 24),

                // 5. Remarks
                _buildSectionTitle("REMARKS / INSTRUCTIONS"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)) 
                    ]
                  ),
                  child: TextField(
                    controller: _remarksCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: "Add any additional private notes...",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ... (Add views remain largely similar but using the new input style for consistency. 
  // For brevity in this edit, assuming _buildAddMedicineView and _buildAddLabTestView are updated similarly 
  // or I can update them in next chunk if needed, but let's try to fit or focus on main view first)
  // Re-implementing Add views with new style:

  Widget _buildAddMedicineView() {
    return Column(
      children: [
        _buildBackHeader("Add Medicine"),
        const SizedBox(height: 16),
        
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledField("Medicine Name", _medNameCtrl, Icons.medication_outlined),
                const SizedBox(height: 16),
                
                // Dosage & Duration Row
                Row(
                  children: [
                    // Dosage Input (Number + mg)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.scale_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _medDosageCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: const InputDecoration(
                                  hintText: "Dosage",
                                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(left: 12, top: 12, bottom: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12), // Added spacing
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                              child: const Text("mg", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Duration Input (Counter + Dropdown)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: SizedBox(
                          height: 44, // Match standard TextField height
                          child: Row(
                            children: [
                               // Counter (Styled Box)
                               Container(
                                 decoration: BoxDecoration(
                                   color: Colors.grey[50],
                                   borderRadius: BorderRadius.circular(8),
                                   border: Border.all(color: Colors.grey[200]!),
                                 ),
                                 padding: const EdgeInsets.symmetric(horizontal: 4),
                                 margin: const EdgeInsets.symmetric(vertical: 2),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     _buildCounterBtn(Icons.remove, () {
                                       if (_durationValue > 1) setState(() => _durationValue--);
                                     }),
                                     Container(
                                       constraints: const BoxConstraints(minWidth: 14),
                                       alignment: Alignment.center,
                                       child: Text(
                                         "$_durationValue", 
                                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                                       ),
                                     ),
                                     _buildCounterBtn(Icons.add, () => setState(() => _durationValue++)),
                                   ],
                                 ),
                               ),
                              
                              const SizedBox(width: 8),
                              
                              // Improved Dropdown
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _durationUnit,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    items: _durationUnits.map((String value) {
                                      return DropdownMenuItem<String>( value: value, child: Text(value) );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _durationUnit = val!),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text("Frequency", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _frequencies.map((freq) {
                      final isSelected = _selectedFrequency == freq;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedFrequency = freq),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey[300]!),
                            ),
                            child: Text(
                              freq, 
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey[700]
                              )
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                _buildStyledField("Special Instructions", _medInstructionCtrl, Icons.notes_outlined),
                const SizedBox(height: 200), // Extra space for keyboard
              ],
            ),
          ),
        ),
        
        // Add Button (Sticky at bottom of this view)
        Container(
          padding: const EdgeInsets.only(top: 10),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addMedicine,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
            child: const Text("Add to Prescription", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildAddLabTestView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBackHeader("Add Investigation"),
        const SizedBox(height: 24),
        _buildStyledField("Test Name (e.g. CBC)", _testNameCtrl, Icons.science_outlined),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addLabTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
               shadowColor: AppColors.primary.withOpacity(0.4),
            ),
            child: const Text("Add Investigation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // --- Components ---
  
  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title, 
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2),
    );
  }
  
  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Very light bg
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTransparentField(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(left: 12, top: 16, bottom: 16),
            border: InputBorder.none,
            hintText: "Enter $title",
            hintStyle: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVitalItem(String label, String unit, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
             Expanded(
               child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.only(left: 12),
                  border: InputBorder.none,
                  hintText: "--",
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
               keyboardType: TextInputType.number,
                       ),
             ),
             const SizedBox(width: 8),
             Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        )
      ],
    );
  }

  Widget _buildBackHeader(String title) {
    return Row(
      children: [
        InkWell(
          onTap: () => setState(() => _currentView = 0),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
          ),
        ),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildMedicineCard(int index) {
    final med = _medicines[index];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Very light grey (Slate 50 equivalent)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)), // Grey 200
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Medicine Icon (Small & Subtle)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.medication, size: 18, color: AppColors.primary.withOpacity(0.8)),
              ),
              const SizedBox(width: 12),
              
              // 2. Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Delete Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          med["name"]!, 
                          style: const TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.w600, 
                            color: Color(0xFF1F2937) // Grey 800
                          )
                        ),
                        InkWell(
                          onTap: () => setState(() => _medicines.removeAt(index)),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)), // Grey 400
                        )
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Single Line Details: Dosage • Frequency • Duration
                    Text(
                      "${med['dosage']}  •  ${med['frequency']}  •  ${med['duration']}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563), // Grey 600
                        fontWeight: FontWeight.w400
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 3. Instruction (Conditional)
          if (med["instruction"]!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 30), // Indent to align with text
              child: Text(
                "Note: ${med['instruction']}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280), // Grey 500
                  fontStyle: FontStyle.italic
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
  
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
    );
  }

  Widget _buildStyledField(String hint, TextEditingController controller, IconData icon, {bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: AppColors.primary),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
        ),
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4), // Reduced from 8
        child: Icon(icon, size: 18, color: Colors.grey[600]),
      ),
    );
  }
}
