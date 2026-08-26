import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/InwardOutward/inward_outward_store.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/models/site_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:intl/intl.dart';

class InwardOutwardScreen extends StatefulWidget {
  const InwardOutwardScreen({super.key});

  @override
  State<InwardOutwardScreen> createState() => _InwardOutwardScreenState();
}

enum _EntryType { inward, outward }

enum _ListTab { inward, outward }

class _InwardOutwardScreenState extends State<InwardOutwardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _remarkController = TextEditingController();

  List<ItemModel> _items = [];
  List<_ContractorOption> _contractors = [];
  List<SiteModel> _sites = [];
  late List<String> _units;

  _EntryType? _entryType;
  _ListTab _listTab = _ListTab.inward;
  List<InwardOutwardRecord> _inwardRecords = [];
  List<InwardOutwardRecord> _outwardRecords = [];
  bool _loadingRecords = true;

  ItemModel? _selectedItem;
  String? _selectedContractorKey;
  int? _selectedSiteId;
  /// Outward only: `same` = issue to contractor, `different` = transfer to site.
  String _outwardDestType = 'same';
  String? _unit;
  bool _loadingLookups = false;
  bool _lookupsLoaded = false;
  bool _isSubmitting = false;

  String get _entryLabel =>
      _entryType == _EntryType.outward ? 'Outward' : 'Inward';

  bool get _showToField =>
      _entryType == _EntryType.inward ||
      (_entryType == _EntryType.outward && _outwardDestType == 'same');

  bool get _showSiteField =>
      _entryType == _EntryType.outward && _outwardDestType == 'different';

  List<SiteModel> get _outwardSites {
    final currentSiteId = selectedSiteId();
    if (currentSiteId == null) return _sites;
    return _sites.where((site) => site.id != currentSiteId).toList();
  }

  @override
  void initState() {
    super.initState();
    _units = List<String>.from(kAvailableUnits);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
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

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    final inbound = await inboundOutboundListApi(context, direction: 'inbound');
    if (!mounted) return;
    final outbound =
        await inboundOutboundListApi(context, direction: 'outbound');
    if (!mounted) return;
    setState(() {
      _inwardRecords = inbound ?? const [];
      _outwardRecords = outbound ?? const [];
      _loadingRecords = false;
    });
  }

  Future<void> _loadLookups() async {
    setState(() => _loadingLookups = true);

    final itemsResult = await itemsApi(
      context,
      perPage: 15,
      fetchAllPages: true,
      status: 'published',
      purchase: '',
      consumable: '',
    );

    final contractors = <_ContractorOption>[];
    final original = await getOriginalContractorsApi(context, perPage: 100);
    for (final c in original?.data?.items ?? const []) {
      if (c.id == null) continue;
      contractors.add(
        _ContractorOption(
          key: 'original-${c.id}',
          name: (c.name?.trim().isNotEmpty == true)
              ? c.name!.trim()
              : 'Contractor #${c.id}',
        ),
      );
    }
    final labour = await getContractorListApi(context, perPage: 100);
    for (final c in labour?.data?.items ?? const []) {
      if (c.id == null) continue;
      contractors.add(
        _ContractorOption(
          key: 'labour-${c.id}',
          name: (c.name?.trim().isNotEmpty == true)
              ? c.name!.trim()
              : 'Contractor #${c.id}',
        ),
      );
    }

    final sitesResult = await sitesApi(context, perPage: 100);

    if (!mounted) return;
    setState(() {
      _items = itemsResult ?? const [];
      _contractors = contractors;
      _sites = sitesResult ?? cachedSites() ?? const [];
      _loadingLookups = false;
      _lookupsLoaded = true;
    });
  }

  Future<void> _selectEntryType(_EntryType type) async {
    setState(() {
      _entryType = type;
      _listTab =
          type == _EntryType.outward ? _ListTab.outward : _ListTab.inward;
      if (!_lookupsLoaded) _loadingLookups = true;
    });
    if (_lookupsLoaded) return;
    await _loadLookups();
  }

  void _backToChoice() {
    _formKey.currentState?.reset();
    _qtyController.clear();
    _remarkController.clear();
    setState(() {
      _entryType = null;
      _selectedItem = null;
      _selectedContractorKey = null;
      _selectedSiteId = null;
      _outwardDestType = 'same';
      _unit = null;
    });
  }

  void _onItemChanged(ItemModel? item) {
    setState(() {
      _selectedItem = item;
      final itemUnit = item?.unit.trim() ?? '';
      if (itemUnit.isNotEmpty) {
        if (!_units.contains(itemUnit)) {
          _units = [itemUnit, ..._units];
        }
        _unit = itemUnit;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_entryType == null || _selectedItem == null || _unit == null) return;

    setState(() => _isSubmitting = true);

    try {
      final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
      final isOutward = _entryType == _EntryType.outward;
      final entryLabel = _entryLabel;
      final wasSiteTransfer = isOutward && _outwardDestType == 'different';

      final saved = await createInboundOutboundApi(
        context,
        direction: isOutward ? 'outbound' : 'inbound',
        itemId: _selectedItem!.id,
        qty: qty,
        unit: _unit!,
        contractorKey: isOutward
            ? (_outwardDestType == 'same' ? _selectedContractorKey : null)
            : _selectedContractorKey,
        remark: _remarkController.text.trim(),
        destinationType: isOutward ? _outwardDestType : null,
        toSiteId: wasSiteTransfer ? _selectedSiteId : null,
      );

      if (!mounted) return;

      if (saved == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      _formKey.currentState?.reset();
      _qtyController.clear();
      _remarkController.clear();

      setState(() {
        if (isOutward) {
          _outwardRecords = [saved, ..._outwardRecords];
          _listTab = _ListTab.outward;
        } else {
          _inwardRecords = [saved, ..._inwardRecords];
          _listTab = _ListTab.inward;
        }
        _selectedItem = null;
        _selectedContractorKey = null;
        _selectedSiteId = null;
        _outwardDestType = 'same';
        _unit = null;
        _entryType = null;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSiteTransfer
                ? 'Outbound site request submitted.'
                : '$entryLabel submitted.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[InwardOutward] save error: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save. Please try again.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 760;

    return PopScope(
      canPop: _entryType == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToChoice();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.backgroundGray,
        drawer: AppDrawer(
          selectedIndex: DrawerIndex.inwardOutward,
          onItemTap: (index) => navigateFromDrawer(context, index),
        ),
        endDrawer: const AppEndDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              _entryType == null
                  ? AppTopBar.shell(
                      title: 'Inward / Outward',
                      scaffoldKey: _scaffoldKey,
                      horizontalPadding: hPad,
                    )
                  : AppTopBar.page(
                      title: _entryLabel,
                      onBack: _backToChoice,
                      showProfile: true,
                      scaffoldKey: _scaffoldKey,
                      horizontalPadding: hPad,
                    ),
              Expanded(
                child: _entryType == null
                    ? _buildHome()
                    : _loadingLookups
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
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 960),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardWhite,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.borderGray
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              _entryLabel,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.headingBlack,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            if (isWide) ...[
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                      child: _buildItemField()),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                      child: _buildQtyField()),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              if (_entryType ==
                                                  _EntryType.outward) ...[
                                                _buildDestinationField(),
                                                const SizedBox(height: 16),
                                              ],
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (_showToField) ...[
                                                    Expanded(
                                                        child: _buildToField()),
                                                    const SizedBox(width: 12),
                                                  ],
                                                  Expanded(
                                                      child: _buildUnitField()),
                                                  if (_showSiteField) ...[
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                        child:
                                                            _buildSiteField()),
                                                  ],
                                                ],
                                              ),
                                            ] else ...[
                                              _buildItemField(),
                                              const SizedBox(height: 16),
                                              _buildQtyField(),
                                              if (_entryType ==
                                                  _EntryType.outward) ...[
                                                const SizedBox(height: 16),
                                                _buildDestinationField(),
                                              ],
                                              if (_showToField) ...[
                                                const SizedBox(height: 16),
                                                _buildToField(),
                                              ],
                                              const SizedBox(height: 16),
                                              _buildUnitField(),
                                              if (_showSiteField) ...[
                                                const SizedBox(height: 16),
                                                _buildSiteField(),
                                              ],
                                            ],
                                            const SizedBox(height: 16),
                                            _buildRemarkField(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _buildSubmitButton(),
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
      ),
    );
  }

  Widget _buildHome() {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final hPad = _hPad(context);
    final records =
        _listTab == _ListTab.outward ? _outwardRecords : _inwardRecords;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select type',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.headingBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose Inward or Outward to continue.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _typeCard(
                          title: 'Inward',
                          subtitle: 'Receive',
                          icon: Icons.south_west_rounded,
                          compact: compact,
                          onTap: () => _selectEntryType(_EntryType.inward),
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 12),
                      Expanded(
                        child: _typeCard(
                          title: 'Outward',
                          subtitle: 'Issue',
                          icon: Icons.north_east_rounded,
                          compact: compact,
                          onTap: () => _selectEntryType(_EntryType.outward),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildListTabs(compact: compact),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _loadingRecords
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                )
              : records.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Text(
                          _listTab == _ListTab.outward
                              ? 'No outward records yet.\nTap Outward above to add one.'
                              : 'No inward records yet.\nTap Inward above to add one.',
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
                      onRefresh: _loadRecords,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _listTab == _ListTab.outward
                              ? _OutwardRecordCard(record: record)
                              : _InwardRecordCard(record: record);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildListTabs({required bool compact}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _listTabButton(
              label: 'Inward',
              selected: _listTab == _ListTab.inward,
              count: _inwardRecords.length,
              compact: compact,
              onTap: () => setState(() => _listTab = _ListTab.inward),
            ),
          ),
          Expanded(
            child: _listTabButton(
              label: 'Outward',
              selected: _listTab == _ListTab.outward,
              count: _outwardRecords.length,
              compact: compact,
              onTap: () => setState(() => _listTab = _ListTab.outward),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTabButton({
    required String label,
    required bool selected,
    required int count,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.primaryRed.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primaryRed
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryRed
                      : AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 16 : 20,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryRed,
                  size: compact ? 20 : 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.headingBlack,
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemField() {
    return _labeledField(
      label: 'Item',
      child: DropdownButtonFormField<int>(
        value: _selectedItem?.id,
        isExpanded: true,
        menuMaxHeight: 320,
        decoration: _inputDecoration('Select item'),
        items: _items
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14),
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
          _onItemChanged(next);
        },
        validator: (value) => value == null ? 'Item is required' : null,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildQtyField() {
    return _labeledField(
      label: 'Qty',
      child: TextFormField(
        controller: _qtyController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: _inputDecoration('Enter qty'),
        validator: (value) {
          final qty = double.tryParse(value?.trim() ?? '');
          if (qty == null || qty <= 0) return 'Enter a valid qty';
          return null;
        },
      ),
    );
  }

  Widget _buildDestinationField() {
    return _labeledField(
      label: 'Destination',
      child: DropdownButtonFormField<String>(
        value: _outwardDestType,
        isExpanded: true,
        decoration: _inputDecoration('Select destination'),
        items: const [
          DropdownMenuItem(value: 'same', child: Text('Same site')),
          DropdownMenuItem(value: 'different', child: Text('Different site')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _outwardDestType = value;
            if (value == 'same') {
              _selectedSiteId = null;
            } else {
              _selectedContractorKey = null;
            }
          });
        },
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildToField() {
    final currentValue = _contractors.any((c) => c.key == _selectedContractorKey)
        ? _selectedContractorKey
        : null;

    return _labeledField(
      label: 'To',
      child: DropdownButtonFormField<String>(
        value: currentValue,
        isExpanded: true,
        menuMaxHeight: 320,
        decoration: _inputDecoration('Select contractor'),
        items: _contractors
            .map(
              (contractor) => DropdownMenuItem<String>(
                value: contractor.key,
                child: Text(
                  contractor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedContractorKey = value),
        validator: (value) =>
            _showToField && (value == null || value.isEmpty)
                ? 'Contractor is required'
                : null,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildUnitField() {
    return _labeledField(
      label: 'Unit',
      child: DropdownButtonFormField<String>(
        value: _unit,
        isExpanded: true,
        decoration: _inputDecoration('Select unit'),
        items: _units
            .map(
              (unit) => DropdownMenuItem<String>(
                value: unit,
                child: Text(unit, style: GoogleFonts.poppins(fontSize: 14)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _unit = value);
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Unit is required' : null,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildSiteField() {
    final options = _outwardSites;
    final currentValue = options.any((site) => site.id == _selectedSiteId)
        ? _selectedSiteId
        : null;

    return _labeledField(
      label: 'Site',
      child: DropdownButtonFormField<int>(
        value: currentValue,
        isExpanded: true,
        menuMaxHeight: 320,
        decoration: _inputDecoration('Select site'),
        items: options
            .map(
              (site) => DropdownMenuItem<int>(
                value: site.id,
                child: Text(
                  site.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedSiteId = value),
        validator: (value) =>
            _showSiteField && value == null ? 'Site is required' : null,
        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildRemarkField() {
    return _labeledField(
      label: 'Remark',
      child: TextFormField(
        controller: _remarkController,
        minLines: 2,
        maxLines: 4,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: _inputDecoration('Enter remark'),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                'Submit',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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

  InputDecoration _inputDecoration(String hint) {
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
}

class _ContractorOption {
  const _ContractorOption({required this.key, required this.name});

  final String key;
  final String name;
}

class _InwardRecordCard extends StatelessWidget {
  const _InwardRecordCard({required this.record});

  final InwardOutwardRecord record;

  @override
  Widget build(BuildContext context) {
    final qtyText = record.qty == record.qty.roundToDouble()
        ? '${record.qty.toInt()}'
        : record.qty.toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(record.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _metaRow(Icons.inventory_2_outlined, 'Qty', '$qtyText ${record.unit}'),
          const SizedBox(height: 6),
          _metaRow(Icons.person_outline, 'To', record.contractorName),
          if (record.remark.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _metaRow(Icons.notes_outlined, 'Remark', record.remark),
          ],
        ],
      ),
    );
  }
}

class _OutwardRecordCard extends StatelessWidget {
  const _OutwardRecordCard({required this.record});

  final InwardOutwardRecord record;

  @override
  Widget build(BuildContext context) {
    final qtyText = record.qty == record.qty.roundToDouble()
        ? '${record.qty.toInt()}'
        : record.qty.toString();
    final toName = record.contractorName.trim();
    final siteName = (record.siteName ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headingBlack,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(record.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _metaRow(Icons.inventory_2_outlined, 'Qty', '$qtyText ${record.unit}'),
          if (toName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _metaRow(Icons.person_outline, 'To', toName),
          ],
          if (siteName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _metaRow(Icons.place_outlined, 'Site', siteName),
          ],
          if (record.remark.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _metaRow(Icons.notes_outlined, 'Remark', record.remark),
          ],
        ],
      ),
    );
  }
}

Widget _metaRow(IconData icon, String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
