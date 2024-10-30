import 'package:flutter/material.dart';
import 'styles.dart'; // Pastikan styles.dart diimport

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  CustomAppBar({
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppStyles.titleTextStyle.copyWith(color: Colors.white),
      ),
      backgroundColor: AppColors.iconColor,
      iconTheme: IconThemeData(color: Colors.white),
      actions: actions,
      elevation: 10, // Adjust as needed
      toolbarHeight: kToolbarHeight, // Set height explicitly if needed
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
