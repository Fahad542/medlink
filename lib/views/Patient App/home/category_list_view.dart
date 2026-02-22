import 'package:flutter/material.dart';
import 'package:medlink/core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/widgets/custom_app_bar_widget.dart';
import 'package:medlink/views/Patient%20App/Find%20a%20doctor/doctor_list_view.dart';
import 'package:medlink/models/home_ui_models.dart';

class CategoryListView extends StatelessWidget {
  final List<CategoryItem> categories;

  const CategoryListView({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Match Home View bg
      appBar: const CustomAppBar(
        title: "All Categories",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            crossAxisSpacing: 12, 
            mainAxisSpacing: 12,
            childAspectRatio: 0.85, 
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02), // Very Light shadow
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorListView(initialCategory: cat.name),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50, // Fixed size like Home View
                          height: 50,
                          padding: cat.name == 'Neurologist' 
                              ? const EdgeInsets.all(2) 
                              : const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cat.color, 
                            shape: BoxShape.circle,
                          ),
                          child: Transform.scale(
                            scale: cat.name == 'Neurologist' ? 1.2 : 1.0,
                            child: Image.asset(
                              cat.image,
                              color: cat.iconColor, // White Icons as requested
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12, 
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary, 
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
          },
        ),
      ),
    );
  }
}
