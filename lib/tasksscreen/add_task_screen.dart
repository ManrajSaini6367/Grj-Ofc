import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/task_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedEmployee;
  String _status = 'Start'; // Maps to pending
  String _level = 'Low'; // Maps to low priority
  bool _isSaving = false;

  // List of loaded employees
  List<String> _employees = [];

  // Static fallback list of employees
  final List<String> _fallbackEmployees = [
    'Amit Kumar',
    'Sumit Singh',
    'Nehal Sharma',
    'Rahul Verma',
    'Pooja Gupta',
    'Raj Patel',
    'Arjun Mehta',
    'Vikram Malhotra',
    'Simran Kaur',
    'Priya Sen',
    'Karan Johar',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await getEmployeesApi(context);
      if (response != null && response.data != null && response.data!.items != null) {
        final List<String> fetched = [];
        for (final item in response.data!.items!) {
          final displayName = (item.name?.trim().isNotEmpty == true)
              ? item.name!.trim()
              : '${item.firstName ?? ''} ${item.lastName ?? ''}'.trim();
          if (displayName.isNotEmpty) {
            fetched.add(displayName);
          }
        }
        if (mounted) {
          setState(() {
            _employees = fetched.isNotEmpty ? fetched : _fallbackEmployees;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[AddTaskScreen] failed to load employees: $e');
    }
    if (mounted) {
      setState(() {
        _employees = _fallbackEmployees;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _formatFormDate(DateTime? date) {
    if (date == null) return 'mm / dd / yyyy';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year;
    return '$mm / $dd / $yyyy';
  }

  TaskStatus _mapStatus(String statusStr) {
    switch (statusStr) {
      case 'On Progress':
        return TaskStatus.onProgress;
      case 'In Pending':
        return TaskStatus.inPending;
      case 'Completed':
        return TaskStatus.completed;
      case 'Start':
      default:
        return TaskStatus.start;
    }
  }

  TaskPriority _mapPriority(String levelStr) {
    switch (levelStr) {
      case 'High':
        return TaskPriority.high;
      case 'Medium':
        return TaskPriority.medium;
      case 'Low':
      default:
        return TaskPriority.low;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a Start Date.', style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an End Date.', style: GoogleFonts.poppins())),
      );
      return;
    }

    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an Employee.', style: GoogleFonts.poppins())),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a task title.', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final String randomId = DateTime.now().millisecondsSinceEpoch.toString();
    final String assigneeName = _selectedEmployee!;
    final String firstName = assigneeName.split(' ').first;
    final String avatarUrl = 'https://images.unsplash.com/photo-${1500000000000 + (assigneeName.hashCode % 1000000)}?w=100&h=100&fit=crop';

    final task = Task(
      id: randomId,
      title: title,
      projectName: 'Web App Redesign', // Default project
      dueDate: _endDate!,
      priority: _mapPriority(_level),
      status: _mapStatus(_status),
      assigneeName: firstName,
      assigneeAvatarUrl: avatarUrl,
      customColor: _mapStatus(_status) == TaskStatus.inPending ? const Color(0xFF6366F1) : null,
      startDate: _startDate,
      description: _descriptionController.text.trim(),
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Add Task',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            // Scrollable Form Container
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderGray.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Information Task',
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 16),
                                
                                // Fields layout
                                if (isWide) ...[
                                  // Row 1: Start Date, End Date, Employee
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildStartDateField()),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildEndDateField()),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildEmployeeField()),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Row 2: Status, Level, Title
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildStatusField()),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildLevelField()),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTitleField()),
                                    ],
                                  ),
                                ] else ...[
                                  // Narrow Stacking layout
                                  _buildStartDateField(),
                                  const SizedBox(height: 16),
                                  _buildEndDateField(),
                                  const SizedBox(height: 16),
                                  _buildEmployeeField(),
                                  const SizedBox(height: 16),
                                  _buildStatusField(),
                                  const SizedBox(height: 16),
                                  _buildLevelField(),
                                  const SizedBox(height: 16),
                                  _buildTitleField(),
                                ],
                                const SizedBox(height: 16),
                                
                                // Row 3 / Full Width: Description
                                _buildDescriptionField(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Save Action Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _submit,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined, size: 18),
                                label: Text(
                                  'Save',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryRed,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 22),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartDateField() {
    return _labeledField(
      label: 'Start Date',
      child: InkWell(
        onTap: _pickStartDate,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: _fieldDecoration(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.inputHint)),
          child: Text(
            _formatFormDate(_startDate),
            style: GoogleFonts.poppins(
              fontSize: 13, 
              color: _startDate != null ? AppColors.textDark : AppColors.inputHint
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndDateField() {
    return _labeledField(
      label: 'End Date',
      child: InkWell(
        onTap: _pickEndDate,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: _fieldDecoration(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.inputHint)),
          child: Text(
            _formatFormDate(_endDate),
            style: GoogleFonts.poppins(
              fontSize: 13, 
              color: _endDate != null ? AppColors.textDark : AppColors.inputHint
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeField() {
    return _labeledField(
      label: 'Employee',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DropdownMenu<String>(
            width: constraints.maxWidth,
            initialSelection: _selectedEmployee,
            enableFilter: true,
            requestFocusOnTap: true,
            hintText: 'Search Employee',
            textStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.headingBlack),
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.operationsCardBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppColors.primaryRed.withOpacity(0.5), width: 1.5),
              ),
            ),
            onSelected: (String? value) {
              setState(() {
                _selectedEmployee = value;
              });
            },
            dropdownMenuEntries: _employees.map<DropdownMenuEntry<String>>((String emp) {
              return DropdownMenuEntry<String>(
                value: emp,
                label: emp,
                style: MenuItemButton.styleFrom(
                  textStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.headingBlack),
                ),
              );
            }).toList(),
          );
        }
      ),
    );
  }

  Widget _buildStatusField() {
    return _labeledField(
      label: 'Status',
      child: DropdownButtonFormField<String>(
        value: _status,
        decoration: _fieldDecoration(),
        items: const [
          DropdownMenuItem(value: 'Start', child: Text('Start')),
          DropdownMenuItem(value: 'On Progress', child: Text('On Progress')),
          DropdownMenuItem(value: 'In Pending', child: Text('In Pending')),
          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _status = value);
        },
      ),
    );
  }

  Widget _buildLevelField() {
    return _labeledField(
      label: 'Level',
      child: DropdownButtonFormField<String>(
        value: _level,
        decoration: _fieldDecoration(),
        items: const [
          DropdownMenuItem(value: 'Low', child: Text('Low')),
          DropdownMenuItem(value: 'Medium', child: Text('Medium')),
          DropdownMenuItem(value: 'High', child: Text('High')),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _level = value);
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return _labeledField(
      label: 'Title',
      child: TextFormField(
        controller: _titleController,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'title'),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return _labeledField(
      label: 'Description',
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _fieldDecoration(hint: 'Enter task description...'),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.headingBlack)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _fieldDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.borderGray.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: AppColors.primaryRed.withOpacity(0.5), width: 1.5),
      ),
    );
  }

  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 18;
    return 20;
  }
}
