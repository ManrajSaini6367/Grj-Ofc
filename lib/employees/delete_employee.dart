import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/employees/employee.dart';
import 'package:grjoffice_apps/services/api_auth.dart';

Future<bool> deleteEmployeeWithDialog(
  BuildContext context,
  Employee employee,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Delete Employee',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: AppColors.headingBlack,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${employee.name}"?',
        style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Delete',
            style: GoogleFonts.poppins(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  if (!context.mounted) return false;

  final employeeId = employee.employeeId;
  if (employeeId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid employee id.')),
    );
    return false;
  }

  return deleteEmployeeApi(context, employeeId);
}
