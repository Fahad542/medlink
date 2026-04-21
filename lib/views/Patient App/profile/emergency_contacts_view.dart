import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:medlink/data/network/api_services.dart';
import 'package:medlink/utils/utils.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsView extends StatefulWidget {
  const EmergencyContactsView({super.key});

  @override
  State<EmergencyContactsView> createState() => _EmergencyContactsViewState();
}

class _EmergencyContactsViewState extends State<EmergencyContactsView> {
  final ApiServices _api = ApiServices();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getEmergencyContacts();
      if (res != null && res['success'] == true) {
        final data = res['data'];
        setState(() {
          _contacts = List<Map<String, dynamic>>.from(
            (data is List ? data : []).map((e) => Map<String, dynamic>.from(e)),
          );
        });
      }
    } catch (e) {
      if (mounted) Utils.toastMessage(context, 'Failed to load contacts', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showContactSheet({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['fullName'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final relationCtrl = TextEditingController(text: existing?['relation'] ?? '');
    bool isPrimary = existing?['isPrimary'] ?? false;
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    existing != null ? 'Edit Contact' : 'Add Emergency Contact',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 20),
                  _inputField(nameCtrl, 'Full Name', Icons.person_rounded),
                  const SizedBox(height: 12),
                  _inputField(phoneCtrl, 'Phone Number', Icons.phone_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _inputField(relationCtrl, 'Relation (e.g. Sister)', Icons.group_rounded),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Switch.adaptive(
                          value: isPrimary,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setSheetState(() => isPrimary = v),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('Set as primary contact', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              if (name.isEmpty || phone.isEmpty) {
                                Utils.toastMessage(ctx, 'Name and phone are required', isError: true);
                                return;
                              }
                              setSheetState(() => isSaving = true);
                              try {
                                dynamic res;
                                if (existing != null) {
                                  res = await _api.updateEmergencyContact(
                                    existing['id'].toString(),
                                    fullName: name,
                                    phone: phone,
                                    relation: relationCtrl.text.trim(),
                                    isPrimary: isPrimary,
                                  );
                                } else {
                                  res = await _api.createEmergencyContact(
                                    fullName: name,
                                    phone: phone,
                                    relation: relationCtrl.text.trim(),
                                    isPrimary: isPrimary,
                                  );
                                }
                                if (res != null && res['success'] == true) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    Utils.toastMessage(context, existing != null ? 'Contact updated' : 'Contact added');
                                    _fetchContacts();
                                  }
                                } else {
                                  Utils.toastMessage(ctx, 'Something went wrong', isError: true);
                                }
                              } catch (e) {
                                Utils.toastMessage(ctx, e.toString(), isError: true);
                              } finally {
                                setSheetState(() => isSaving = false);
                              }
                            },
                      child: isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              existing != null ? 'Save Changes' : 'Add Contact',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Contact', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Remove ${contact['fullName']} from your emergency contacts?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await _api.deleteEmergencyContact(contact['id'].toString());
      if (res != null && res['success'] == true) {
        Utils.toastMessage(context, 'Contact removed');
        _fetchContacts();
      }
    } catch (e) {
      Utils.toastMessage(context, 'Failed to remove contact', isError: true);
    }
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: const CustomAppBar(title: "Emergency Contacts"),
      body: RefreshIndicator(
        onRefresh: _fetchContacts,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_isLoading)
              _buildPageLoadingShimmer()
            else ...[
              // Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your emergency contacts will be notified immediately when you trigger the SOS alert.",
                        style: GoogleFonts.inter(color: Colors.red[800], fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Text("Quick Actions", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showContactSheet(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text("Add New Contact", style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Text(
                    "Saved Contacts (${_contacts.length})",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_contacts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.contact_emergency_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text("No emergency contacts saved", style: GoogleFonts.inter(color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text("Tap 'Add New Contact' to get started", style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                )
              else
                ..._contacts.map((contact) => _buildContactCard(contact)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageLoadingShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            height: 14,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Contact cards placeholder
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final name = contact['fullName'] ?? '';
    final phone = contact['phone'] ?? '';
    final relation = contact['relation'] ?? '';
    final isPrimary = contact['isPrimary'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF1E293B))),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text('Primary', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(phone, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                  if (relation.isNotEmpty)
                    Text(relation, style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
            // Call button
            IconButton(
              onPressed: () => _callContact(phone),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.call_rounded, color: Colors.green, size: 18),
              ),
            ),
            const SizedBox(width: 4),
            // Edit/delete popup
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'edit') _showContactSheet(existing: contact);
                if (v == 'delete') _deleteContact(contact);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Edit', style: GoogleFonts.inter(fontSize: 13)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Remove', style: GoogleFonts.inter(fontSize: 13, color: Colors.red)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
