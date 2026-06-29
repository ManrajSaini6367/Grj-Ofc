enum EmployeeStatus { active, inactive }

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.site,
    this.status = EmployeeStatus.active,
    this.employeeId,
    this.firstName,
    this.lastName,
    this.email,
    this.mobile,
    this.dateOfJoin,
    this.attendanceAllow = true,
  });

  final String id;
  final String name;
  final String role;
  final String site;
  final EmployeeStatus status;
  final int? employeeId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final DateTime? dateOfJoin;
  final bool attendanceAllow;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

const kMockEmployees = [
  Employee(
    id: 'EMP-4022',
    name: 'Arjun Singh',
    role: 'Site Engineer',
    site: 'Skyline B-4',
  ),
  Employee(
    id: 'EMP-3988',
    name: 'Meera Reddy',
    role: 'Project Architect',
    site: 'Skyline Main',
  ),
  Employee(
    id: 'EMP-4105',
    name: 'Rajesh Kumar',
    role: 'General Foreman',
    site: 'Skyline B-2',
  ),
  Employee(
    id: 'EMP-4050',
    name: 'Vikram Malhotra',
    role: 'Safety Compliance Officer',
    site: 'Skyline Towers',
  ),
  Employee(
    id: 'EMP-4211',
    name: 'Ananya Bose',
    role: 'Structural Specialist',
    site: 'Skyline Main',
  ),
];
