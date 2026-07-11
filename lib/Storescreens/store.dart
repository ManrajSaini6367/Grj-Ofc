import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/drawer/app_end_drawer.dart';
import 'package:grjoffice_apps/drawer/drawer.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';
import 'package:grjoffice_apps/Itemsscreen/item_history_screen.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/item_model.dart';
import 'package:grjoffice_apps/navigation/app_navigation.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';
import 'package:grjoffice_apps/widgets/item_thumbnail.dart';

enum _StockFilter { all, inStock, lowStock }

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const _lowStockThreshold = 5.0;
  static const _goodColor = Color(0xFF059669);
  static const _goodBg = Color(0xFFECFDF5);
  static const _lowColor = Color(0xFFD97706);
  static const _lowBg = Color(0xFFFFFBEB);
  static const _emptyColor = Color(0xFFDC2626);
  static const _emptyBg = Color(0xFFFEF2F2);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _StockFilter _stockFilter = _StockFilter.all;
  List<InventoryItem> _storeItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    final apiItems = await itemsApi(context, perPage: 50, status: 'published');
    if (!mounted) return;
    setState(() {
      _storeItems = apiItems?.map(_toInventoryItem).toList() ?? [];
      _isLoading = false;
    });
  }

  InventoryItem _toInventoryItem(ItemModel model) {
    return InventoryItem(
      id: model.id.toString(),
      name: model.displayName,
      sku: model.sku ?? '-',
      unit: model.unit,
      status: model.status == 'published'
          ? ItemStatus.published
          : ItemStatus.unpublished,
      directPurchase: model.purchase == 1,
      dayReport: model.dayReport == 1,
      consumable: model.consumable == 1,
      balance: int.tryParse(model.balance ?? '') ?? 0,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  double _balance(InventoryItem item) => item.balance.toDouble();

  bool _isLowStock(double balance) => balance > 0 && balance <= _lowStockThreshold;

  _StockLevel _stockLevel(double balance) {
    if (balance <= 0) return _StockLevel.outOfStock;
    if (balance <= _lowStockThreshold) return _StockLevel.low;
    return _StockLevel.good;
  }

  List<InventoryItem> get _filteredItems {
    return _storeItems.where((item) {
      final balance = _balance(item);
      if (_stockFilter == _StockFilter.inStock && balance <= 0) return false;
      if (_stockFilter == _StockFilter.lowStock && !_isLowStock(balance)) return false;

      if (_searchQuery.isNotEmpty) {
        final haystack = '${item.name} ${item.sku} ${item.unit}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => _balance(b).compareTo(_balance(a)));
  }

  int get _inStockCount => _storeItems.where((i) => _balance(i) > 0).length;

  int get _lowStockCount => _storeItems.where((i) => _isLowStock(_balance(i))).length;

  double get _totalUnits => _storeItems.fold(0.0, (sum, i) => sum + _balance(i));

  void _openHistory(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemHistoryScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final items = _filteredItems;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundGray,
      drawer: AppDrawer(selectedIndex: DrawerIndex.store, onItemTap: _onDrawerItemTap),
      endDrawer: const AppEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.tab(
              title: 'Store',
              scaffoldKey: _scaffoldKey,
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryRed),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () => _loadItems(showLoader: false),
                      child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildToolbar(),
                          const SizedBox(height: 12),
                          _buildFilterChips(),
                          const SizedBox(height: 16),
                          _buildSectionHeader(items.length),
                        ],
                      ),
                    ),
                  ),
                  if (items.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.crossAxisExtent >= 600 ? 3 : 2;
                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildStoreCard(items[index]),
                              childCount: items.length,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Total Items',
            value: '${_storeItems.length}',
            icon: Icons.category_outlined,
            color: AppColors.primaryRed,
            bg: AppColors.primaryRed.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: 'In Stock',
            value: '$_inStockCount',
            icon: Icons.check_circle_outline,
            color: _goodColor,
            bg: _goodBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            label: 'Low Stock',
            value: '$_lowStockCount',
            icon: Icons.warning_amber_rounded,
            color: _lowColor,
            bg: _lowBg,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, SKU or unit...',
          hintStyle: GoogleFonts.poppins(color: AppColors.inputHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          filled: true,
          fillColor: AppColors.operationsCardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All Items', _StockFilter.all),
          const SizedBox(width: 8),
          _filterChip('In Stock', _StockFilter.inStock),
          const SizedBox(width: 8),
          _filterChip('Low Stock', _StockFilter.lowStock),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _StockFilter value) {
    final selected = _stockFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primaryRed : AppColors.textDark,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _stockFilter = value),
      selectedColor: AppColors.primaryRed.withValues(alpha: 0.12),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: AppColors.cardWhite,
      side: BorderSide(
        color: selected ? AppColors.primaryRed.withValues(alpha: 0.4) : AppColors.borderGray.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          'Store Items',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.headingBlack),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
          ),
        ),
        const Spacer(),
        Text(
          '${formatStoreQty(_totalUnits)} total units',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStoreCard(InventoryItem item) {
    final balance = _balance(item);
    final level = _stockLevel(balance);
    final accent = switch (level) {
      _StockLevel.good => _goodColor,
      _StockLevel.low => _lowColor,
      _StockLevel.outOfStock => _emptyColor,
    };
    final accentBg = switch (level) {
      _StockLevel.good => _goodBg,
      _StockLevel.low => _lowBg,
      _StockLevel.outOfStock => _emptyBg,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openHistory(item),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.5)]),
                  ),
                ),
                ItemThumbnail(item: item, height: 78),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stockBadge(level, accent, accentBg),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formatStoreQty(balance),
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.headingBlack,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accentBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  formatStoreUnit(item.unit),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              item.name.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.sku,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: TextButton(
                            onPressed: () => _openHistory(item),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                              foregroundColor: AppColors.primaryRed,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View history',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stockBadge(_StockLevel level, Color color, Color bg) {
    final label = switch (level) {
      _StockLevel.good => 'In Stock',
      _StockLevel.low => 'Low Stock',
      _StockLevel.outOfStock => 'Out of Stock',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppColors.operationsCardBg, shape: BoxShape.circle),
            child: Icon(Icons.storefront_outlined, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.headingBlack),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or filter',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _onDrawerItemTap(int index) {
    navigateFromDrawer(context, index);
  }
}

enum _StockLevel { good, low, outOfStock }
