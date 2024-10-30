import 'package:flutter/material.dart';
import 'styles.dart'; // Pastikan styles.dart diimport

class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPressed;
  final String tooltip;
  final String label;
  final bool isSelected;
  final TextStyle? labelTextStyle;
  final Color?
      backgroundColor; // Menambahkan parameter opsional untuk warna latar belakang

  CustomActionButton({
    required this.icon,
    this.iconColor = AppColors.iconColor,
    this.onPressed,
    required this.tooltip,
    required this.label,
    this.isSelected = false,
    this.labelTextStyle,
    this.backgroundColor, // Parameter opsional
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          color: backgroundColor ??
              (isSelected ? AppColors.selectedCardColor : AppColors.cardColor),
          elevation: isSelected ? 6 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: labelTextStyle ??
              AppStyles.captionTextStyle.copyWith(
                color: isSelected
                    ? AppColors.selectedCaptionColor
                    : AppColors.captionColor,
              ),
        ),
      ],
    );
  }
}
