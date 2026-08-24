import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grjoffice_apps/Contractorscreen/original_contractor.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/models/getcontractorlist.dart';
import 'package:grjoffice_apps/services/api_auth.dart';
import 'package:grjoffice_apps/widgets/app_top_bar.dart';

class OriginalContractorViewScreen extends StatefulWidget {
  const OriginalContractorViewScreen({super.key, required this.contractor});

  final OriginalContractor contractor;

  @override
  State<OriginalContractorViewScreen> createState() =>
      _OriginalContractorViewScreenState();
}

class _OriginalContractorViewScreenState
    extends State<OriginalContractorViewScreen> {
  bool _isLoading = true;
  GetcclistData? _detail;

  double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 14;
    if (width < 600) return 18;
    return 20;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final contractorId = int.tryParse(widget.contractor.id);
    if (contractorId == null || contractorId <= 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final response = await getOriginalContractorApi(
      context,
      originalContractorId: contractorId,
    );
    if (!mounted) return;
    setState(() {
      _detail = response?.data;
      _isLoading = false;
    });
  }

  String get _name {
    final fromApi = _detail?.name?.trim();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return widget.contractor.name;
  }

  bool get _isPublished {
    final status = _detail?.status ??
        (widget.contractor.isPublished ? 'published' : 'unpublished');
    return status.toLowerCase() == 'published';
  }

  List<_WorkRow> get _works {
    final apiWorks = _detail?.works;
    if (apiWorks != null && apiWorks.isNotEmpty) {
      return apiWorks
          .map(
            (item) => _WorkRow(
              work: item.work?.trim().isNotEmpty == true ? item.work!.trim() : 'Work',
              rate: item.rate ?? 0,
            ),
          )
          .toList();
    }
    return widget.contractor.works
        .map((item) => _WorkRow(work: item.work, rate: item.rate.toDouble()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = _hPad(context);
    final siteName = _detail?.site?.name?.trim();
    final works = _works;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar.page(
              title: 'Contractor Details',
              onBack: () => Navigator.pop(context),
              horizontalPadding: hPad,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryRed,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryRed,
                      onRefresh: () async {
                        setState(() => _isLoading = true);
                        await _load();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.borderGray
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.headingBlack,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryRed
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _isPublished
                                              ? 'PUBLISHED'
                                              : 'UNPUBLISHED',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.primaryRed,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (siteName != null && siteName.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      siteName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  Text(
                                    'Work according to rate',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.headingBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (works.isEmpty)
                                    Text(
                                      'No work rates added',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    )
                                  else
                                    ...works.map(
                                      (work) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.operationsCardBg,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${work.work}  ·  ₹${work.rate % 1 == 0 ? work.rate.toInt() : work.rate}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: AppColors.textDark,
                                            ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkRow {
  const _WorkRow({required this.work, required this.rate});

  final String work;
  final double rate;
}
