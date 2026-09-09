import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/InwardOutward/outward_request_store.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/field_label.dart';
import 'package:intl/intl.dart';

/// Sent outward requests list + create form.
class OutwardRequestScreen extends StatefulWidget {
  const OutwardRequestScreen({super.key});

  @override
  State<OutwardRequestScreen> createState() => _OutwardRequestScreenState();
}

class _OutwardRequestScreenState extends State<OutwardRequestScreen> {
  List<OutwardRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await OutwardRequestStore.loadSent(context);
    if (!mounted) return;
    setState(() {
      _requests = items;
      _loading = false;
    });
  }

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateOutwardRequestPage()),
    );
    if (created == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateForm,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Outward Request',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : _requests.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: Text(
                              'No outward requests yet.\nTap + to create one.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryRed,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 88),
                            itemCount: _requests.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _OutwardRequestCard(
                                request: _requests[index],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateOutwardRequestPage extends StatefulWidget {
  const CreateOutwardRequestPage({super.key});

  @override
  State<CreateOutwardRequestPage> createState() =>
      _CreateOutwardRequestPageState();
}

class _CreateOutwardRequestPageState extends State<CreateOutwardRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _remarkController = TextEditingController();

  List<ItemModel> _items = [];
  List<SiteModel> _sites = [];
  late List<String> _units;
  ItemModel? _selectedItem;
  int? _selectedSiteId;
  String? _unit;
  bool _loading = true;
  bool _saving = false;

  List<SiteModel> get _destinationSites {
    final currentSiteId = selectedSiteId();
    if (currentSiteId == null) return _sites;
    return _sites.where((site) => site.id != currentSiteId).toList();
  }

  @override
  void initState() {
    super.initState();
    _units = List<String>.from(kAvailableUnits);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLookups());
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    final items = await itemsApi(
      context,
      perPage: 15,
      fetchAllPages: true,
      status: 'published',
      purchase: '',
      consumable: '',
    );
    final sites = await sitesApi(context, perPage: 100);
    if (!mounted) return;
    setState(() {
      _items = items ?? const [];
      _sites = sites ?? cachedSites() ?? const [];
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null || _unit == null || _selectedSiteId == null) {
      return;
    }

    setState(() => _saving = true);

    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;

    try {
      final ok = await OutwardRequestStore.createSiteTransfer(
        context,
        itemId: _selectedItem!.id,
        qty: qty,
        unit: _unit!,
        toSiteId: _selectedSiteId!,
        remark: _remarkController.text.trim(),
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _saving = false);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Outward site request submitted.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('[OutwardRequest] create error: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save request.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 14),
      filled: true,
      fillColor: AppColors.operationsCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: AppColors.borderGray.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
      ),
    );
  }

  Widget _labeled(String label, Widget child, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabelText(
          label,
          isRequired: isRequired,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'New Outward Request',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        hPad,
                        16,
                        hPad,
                        24 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppColors.borderGray.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _labeled(
                                'Item',
                                DropdownButtonFormField<int>(
                                  value: _selectedItem?.id,
                                  isExpanded: true,
                                  decoration: _decoration('Select item'),
                                  items: _items
                                      .map(
                                        (item) => DropdownMenuItem<int>(
                                          value: item.id,
                                          child: Text(
                                            item.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    ItemModel? next;
                                    for (final item in _items) {
                                      if (item.id == id) {
                                        next = item;
                                        break;
                                      }
                                    }
                                    setState(() {
                                      _selectedItem = next;
                                      final u = next?.unit.trim() ?? '';
                                      if (u.isNotEmpty) {
                                        if (!_units.contains(u)) {
                                          _units = [u, ..._units];
                                        }
                                        _unit = u;
                                      }
                                    });
                                  },
                                  validator: (v) =>
                                      v == null ? 'Item is required' : null,
                                ),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              _labeled(
                                'Qty',
                                TextFormField(
                                  controller: _qtyController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  decoration: _decoration('Enter qty'),
                                  validator: (value) {
                                    final qty =
                                        double.tryParse(value?.trim() ?? '');
                                    if (qty == null || qty <= 0) {
                                      return 'Enter a valid qty';
                                    }
                                    return null;
                                  },
                                ),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              _labeled(
                                'Unit',
                                DropdownButtonFormField<String>(
                                  value: _unit,
                                  isExpanded: true,
                                  decoration: _decoration('Select unit'),
                                  items: _units
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(
                                            u,
                                            style:
                                                GoogleFonts.poppins(fontSize: 14),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _unit = v),
                                  validator: (v) =>
                                      v == null || v.isEmpty
                                          ? 'Unit is required'
                                          : null,
                                ),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              _labeled(
                                'Site',
                                DropdownButtonFormField<int>(
                                  value: _destinationSites
                                          .any((s) => s.id == _selectedSiteId)
                                      ? _selectedSiteId
                                      : null,
                                  isExpanded: true,
                                  decoration: _decoration('Select site'),
                                  items: _destinationSites
                                      .map(
                                        (site) => DropdownMenuItem<int>(
                                          value: site.id,
                                          child: Text(
                                            site.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedSiteId = v),
                                  validator: (v) =>
                                      v == null ? 'Site is required' : null,
                                ),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              _labeled(
                                'Remark',
                                TextFormField(
                                  controller: _remarkController,
                                  minLines: 2,
                                  maxLines: 4,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                  decoration: _decoration('Enter remark'),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: AppColors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : Text(
                                          'Submit Request',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}

class _OutwardRequestCard extends StatelessWidget {
  const _OutwardRequestCard({required this.request});

  final OutwardRequest request;

  Color get _statusColor => switch (request.status) {
        OutwardRequestStatus.pending => const Color(0xFFD97706),
        OutwardRequestStatus.approved => const Color(0xFF059669),
        OutwardRequestStatus.rejected => const Color(0xFFDC2626),
      };

  @override
  Widget build(BuildContext context) {
    final qtyText = request.qty == request.qty.roundToDouble()
        ? '${request.qty.toInt()}'
        : '${request.qty}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(request.createdAt),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _line('Qty', '$qtyText ${request.unit}'),
          if (request.siteName.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _line('To site', request.siteName),
          ],
          if (request.remark.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _line('Remark', request.remark),
          ],
          if (request.status == OutwardRequestStatus.rejected &&
              request.rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _line('Hindrance reason', request.rejectionReason),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Text(
      '$label: $value',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: AppColors.textDark,
      ),
    );
  }
}
