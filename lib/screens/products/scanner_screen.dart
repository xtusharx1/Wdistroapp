import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/cart_state.dart';
import '../../core/models/product.dart';
import '../../core/services/product_service.dart';
import '../../core/services/api_client.dart';
import 'product_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  final CartState cart;
  const ScannerScreen({super.key, required this.cart});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _controller;
  bool _processing = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Camera detection ──────────────────────────────────────────────────────

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() { _processing = true; _errorMsg = null; });
    await _controller.stop(); // pause immediately; resumes only via "Scan Again"

    try {
      final product = await ProductService.instance.scanProduct(code);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product, cart: widget.cart),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _processing = false; _errorMsg = _errorMessage(e); });
    }
  }

  // ── Manual entry ──────────────────────────────────────────────────────────

  void _showManualEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualEntrySheet(
        onProductFound: (product) {
          Navigator.pop(context); // close sheet
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product, cart: widget.cart),
            ),
          );
        },
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  static String _errorMessage(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 404) return 'No product found for this barcode.';
      if (e.statusCode == 403) {
        return 'Your shop doesn\'t have the required license for this product.';
      }
      return e.message;
    }
    return 'Network error. Please check your connection and try again.';
  }

  Future<void> _scanAgain() async {
    setState(() { _errorMsg = null; _processing = false; });
    await _controller.start();
  }

  Future<void> _toggleFlash() async {
    await _controller.toggleTorch();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scan Barcode',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          // Manual barcode entry
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white),
            tooltip: 'Enter barcode manually',
            onPressed: _showManualEntry,
          ),
          // Torch toggle — hidden automatically when device has no torch
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (_, state, __) {
              final torchState = state.torchState;
              if (torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: _toggleFlash,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _buildCameraError(error),
          ),

          // Dark overlay with transparent viewfinder hole
          SizedBox.expand(
            child: CustomPaint(painter: _OverlayPainter()),
          ),

          // Coloured corner brackets
          SizedBox.expand(
            child: CustomPaint(painter: _FramePainter(AppColors.primary)),
          ),

          // Instruction label
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.28,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode or QR code within the frame',
                style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // Loading overlay (shown while API is in-flight)
          if (_processing) _buildLoadingOverlay(),

          // Error card with retry
          if (_errorMsg != null)
            Positioned(
              bottom: 64,
              left: 24,
              right: 24,
              child: _buildErrorCard(_errorMsg!),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Looking up product…',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, color: AppColors.red, size: 36),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Scan Again',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final msg = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Camera permission denied.\nPlease enable camera access in Settings to scan barcodes.'
        : 'Unable to access camera.\nPlease restart the app and try again.';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 20),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: Text('Go Back',
                  style: GoogleFonts.inter(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Manual Entry Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ManualEntrySheet extends StatefulWidget {
  final void Function(Product product) onProductFound;
  const _ManualEntrySheet({required this.onProductFound});

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _errorMessage(Object e) {
    if (e is ApiException) {
      if (e.statusCode == 404) return 'No product found for this barcode or SKU.';
      if (e.statusCode == 403) {
        return 'Your shop doesn\'t have the required license for this product.';
      }
      return e.message;
    }
    return 'Network error. Please check your connection and try again.';
  }

  Future<void> _submit() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    try {
      final product = await ProductService.instance.scanProduct(code);
      if (mounted) widget.onProductFound(product);
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = _errorMessage(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Shift sheet up when keyboard appears
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter Barcode Manually',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Type or paste a barcode number or SKU.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              onChanged: (_) => setState(() {}), // refreshes clear button
              style: GoogleFonts.inter(
                  fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 012345678901',
                hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded,
                            size: 18, color: AppColors.textTertiary),
                        onPressed: () => setState(() => _ctrl.clear()),
                      )
                    : null,
              ),
            ),

            // Inline error
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.error_outline,
                        color: AppColors.red, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.red),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Look Up Product',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

// Semi-transparent dark overlay with a rectangular cutout for the viewfinder
class _OverlayPainter extends CustomPainter {
  static const double _frameSize = 260;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: _frameSize, height: _frameSize),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter _) => false;
}

// Coloured L-shaped corner brackets that outline the viewfinder frame
class _FramePainter extends CustomPainter {
  final Color color;
  const _FramePainter(this.color);

  static const double _frameSize = 260;
  static const double _cornerLen = 28;
  static const double _stroke = 3.5;
  static const double _radius = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final l = cx - _frameSize / 2;
    final t = cy - _frameSize / 2;
    final r = cx + _frameSize / 2;
    final b = cy + _frameSize / 2;

    // Top-left
    canvas.drawLine(Offset(l + _radius, t), Offset(l + _cornerLen, t), paint);
    canvas.drawLine(Offset(l, t + _radius), Offset(l, t + _cornerLen), paint);
    // Top-right
    canvas.drawLine(Offset(r - _cornerLen, t), Offset(r - _radius, t), paint);
    canvas.drawLine(Offset(r, t + _radius), Offset(r, t + _cornerLen), paint);
    // Bottom-left
    canvas.drawLine(Offset(l + _radius, b), Offset(l + _cornerLen, b), paint);
    canvas.drawLine(Offset(l, b - _cornerLen), Offset(l, b - _radius), paint);
    // Bottom-right
    canvas.drawLine(Offset(r - _cornerLen, b), Offset(r - _radius, b), paint);
    canvas.drawLine(Offset(r, b - _cornerLen), Offset(r, b - _radius), paint);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}
