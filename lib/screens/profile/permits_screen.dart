import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../core/models/shop_permit.dart';
import '../../core/services/permit_service.dart';

class PermitsScreen extends StatefulWidget {
  const PermitsScreen({super.key});

  @override
  State<PermitsScreen> createState() => _PermitsScreenState();
}

class _PermitsScreenState extends State<PermitsScreen> {
  List<ShopPermit> _permits = [];
  bool _loading = true;
  String? _error;

  static const _permitTypes = [
    {'label': 'Seller Permit', 'slug': 'seller_permit', 'icon': Icons.badge_outlined},
    {'label': 'Tobacco License', 'slug': 'tobacco_license', 'icon': Icons.article_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final shopId = AppState.instance.shop?.id;
    if (shopId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final permits = await PermitService.instance.getShopPermits(shopId);
      if (mounted) setState(() { _permits = permits; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickAndUpload(String permitTypeSlug, String permitLabel, bool isReplace) async {
    final shopId = AppState.instance.shop?.id;
    if (shopId == null) return;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
        withReadStream: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e'), backgroundColor: AppColors.red),
        );
      }
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File path unavailable. Please try again.'), backgroundColor: AppColors.red),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final uploaded = await PermitService.instance.uploadPermit(
        shopId: shopId,
        permitTypeSlug: permitTypeSlug,
        filePath: file.path!,
        fileName: file.name,
      );
      if (mounted) {
        Navigator.pop(context); // dismiss loader
        setState(() {
          final idx = _permits.indexWhere((p) => p.permitType == uploaded.permitType);
          if (idx >= 0) {
            _permits[idx] = uploaded;
          } else {
            _permits = [..._permits, uploaded];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$permitLabel ${isReplace ? 'replaced' : 'uploaded'} successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _viewDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document.'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Permits', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Upload your permit documents below. Each document will be reviewed by an admin.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ..._permitTypes.map((type) => _buildPermitCard(
                            label: type['label'] as String,
                            slug: type['slug'] as String,
                            icon: type['icon'] as IconData,
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildPermitCard({required String label, required String slug, required IconData icon}) {
    final permit = _permits.firstWhere(
      (p) => p.permitType == label,
      orElse: () => ShopPermit(
        id: -1,
        shopId: -1,
        permitType: label,
        documentUrl: '',
        originalFileName: '',
        uploadedBy: -1,
        uploadedAt: DateTime.now(),
        status: '',
        createdAt: DateTime.now(),
      ),
    );
    final exists = permit.id != -1;
    final isReplace = exists;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                if (exists) _statusBadge(permit.status),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: exists
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('File', permit.originalFileName),
                      const SizedBox(height: 4),
                      _infoRow('Uploaded', _fmtDate(permit.uploadedAt)),
                      if (permit.remarks != null && permit.remarks!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.red.withOpacity(0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 14, color: AppColors.red),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(permit.remarks!,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.red)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _viewDocument(permit.documentUrl),
                              icon: const Icon(Icons.open_in_new, size: 15),
                              label: const Text('View'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickAndUpload(slug, label, true),
                              icon: const Icon(Icons.upload_file, size: 15),
                              label: const Text('Replace'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No document uploaded yet.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndUpload(slug, label, false),
                          icon: const Icon(Icons.upload_file, size: 15),
                          label: Text('Upload $label'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg, fg;
    switch (status) {
      case 'Approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'Rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${_month(dt.month)} ${dt.day}, ${dt.year}';
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
