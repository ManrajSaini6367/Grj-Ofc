import 'package:flutter/material.dart';

enum ActivityType {
  employee,
  supplier,
  contractor,
  item,
  store,
  purchase,
  attendance,
  expense,
  system,
}

class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.performedBy,
    required this.type,
    required this.dateTime,
    this.site,
  });

  final String id;
  final String title;
  final String description;
  final String performedBy;
  final ActivityType type;
  final DateTime dateTime;
  final String? site;
}

final kMockActivities = [
  ActivityEntry(
    id: 'ACT-001',
    title: 'Item stock updated',
    description: '10 Bag OPC Cement credited to store inventory.',
    performedBy: 'Store Keeper',
    type: ActivityType.store,
    dateTime: DateTime(2026, 6, 17, 12, 52),
    site: 'River Crossing',
  ),
  ActivityEntry(
    id: 'ACT-002',
    title: 'Employee punched in',
    description: 'Rajesh Kumar punched in at Site A.',
    performedBy: 'Rajesh Kumar',
    type: ActivityType.attendance,
    dateTime: DateTime(2026, 6, 17, 9, 15),
    site: 'River Crossing',
  ),
  ActivityEntry(
    id: 'ACT-003',
    title: 'New contractor added',
    description: 'Rajesh Labour Contractors published with mason rate ₹850/day.',
    performedBy: 'Admin User',
    type: ActivityType.contractor,
    dateTime: DateTime(2026, 6, 17, 8, 40),
    site: 'Skyline Towers',
  ),
  ActivityEntry(
    id: 'ACT-004',
    title: 'Supplier updated',
    description: 'Sharma Building Supplies materials list updated.',
    performedBy: 'Site Manager',
    type: ActivityType.supplier,
    dateTime: DateTime(2026, 6, 16, 17, 20),
    site: 'River Crossing',
  ),
  ActivityEntry(
    id: 'ACT-005',
    title: 'Item issued from store',
    description: '5 Nos RASSI BUNDLE debited — Issue To: Used, Remark: Site work.',
    performedBy: 'Store Keeper',
    type: ActivityType.store,
    dateTime: DateTime(2026, 6, 16, 14, 30),
    site: 'River Crossing',
  ),
  ActivityEntry(
    id: 'ACT-006',
    title: 'New employee created',
    description: 'Priya Sharma added as Site Engineer at River Crossing.',
    performedBy: 'HR Admin',
    type: ActivityType.employee,
    dateTime: DateTime(2026, 6, 16, 11, 0),
    site: 'River Crossing',
  ),
  ActivityEntry(
    id: 'ACT-007',
    title: 'Purchase order raised',
    description: 'PO #PO-2406 for 50 Bag cement from Sharma Building Supplies.',
    performedBy: 'Purchase Officer',
    type: ActivityType.purchase,
    dateTime: DateTime(2026, 6, 15, 16, 45),
    site: 'Skyline Towers',
  ),
  ActivityEntry(
    id: 'ACT-008',
    title: 'Item published',
    description: 'TMT Steel 12mm marked as published in item master.',
    performedBy: 'Admin User',
    type: ActivityType.item,
    dateTime: DateTime(2026, 6, 15, 10, 10),
    site: 'All Sites',
  ),
  ActivityEntry(
    id: 'ACT-009',
    title: 'Expense recorded',
    description: 'Transport expense ₹2,400 logged under site logistics.',
    performedBy: 'Accounts Team',
    type: ActivityType.expense,
    dateTime: DateTime(2026, 6, 14, 18, 5),
    site: 'River Crossing',
  ),
  ActivityEntry(
    id: 'ACT-010',
    title: 'Day end report submitted',
    description: 'Daily progress and labour report submitted for review.',
    performedBy: 'Site Manager',
    type: ActivityType.system,
    dateTime: DateTime(2026, 6, 14, 19, 30),
    site: 'River Crossing',
  ),
];

String activityTypeLabel(ActivityType type) {
  return switch (type) {
    ActivityType.employee => 'Employee',
    ActivityType.supplier => 'Supplier',
    ActivityType.contractor => 'Contractor',
    ActivityType.item => 'Item',
    ActivityType.store => 'Store',
    ActivityType.purchase => 'Purchase',
    ActivityType.attendance => 'Attendance',
    ActivityType.expense => 'Expense',
    ActivityType.system => 'System',
  };
}

IconData activityTypeIcon(ActivityType type) {
  return switch (type) {
    ActivityType.employee => Icons.badge_outlined,
    ActivityType.supplier => Icons.inventory_2_outlined,
    ActivityType.contractor => Icons.groups_outlined,
    ActivityType.item => Icons.category_outlined,
    ActivityType.store => Icons.storefront_outlined,
    ActivityType.purchase => Icons.shopping_cart_outlined,
    ActivityType.attendance => Icons.how_to_reg_outlined,
    ActivityType.expense => Icons.account_balance_wallet_outlined,
    ActivityType.system => Icons.assessment_outlined,
  };
}

Color activityTypeColor(ActivityType type) {
  return switch (type) {
    ActivityType.employee => const Color(0xFF2563EB),
    ActivityType.supplier => const Color(0xFF7C3AED),
    ActivityType.contractor => const Color(0xFF0891B2),
    ActivityType.item => const Color(0xFF059669),
    ActivityType.store => const Color(0xFF8B1D1D),
    ActivityType.purchase => const Color(0xFFD97706),
    ActivityType.attendance => const Color(0xFF16A34A),
    ActivityType.expense => const Color(0xFFDC2626),
    ActivityType.system => const Color(0xFF64748B),
  };
}
