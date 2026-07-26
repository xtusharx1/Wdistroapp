import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductImagePlaceholder extends StatelessWidget {
  final String label;
  final double height;
  final double? width;
  final String? imageUrl;

  const ProductImagePlaceholder({
    super.key,
    required this.label,
    required this.height,
    this.width,
    this.imageUrl,
  });

  void _openImageViewer(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            InteractiveViewer(
              maxScale: 4.0,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) => _buildLargePlaceholder(),
                    )
                  : _buildLargePlaceholder(),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargePlaceholder() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image, size: 64, color: Color(0xFFB5A68A)),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB5A68A),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openImageViewer(context),
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Decode and cache the image at 2x the display size to keep it perfectly sharp
      // while saving up to 90% of memory compared to full-resolution decoding.
      final int? targetCacheHeight = height > 0 ? (height * 2).round() : null;
      final int? targetCacheWidth = (width != null && width! > 0) ? (width! * 2).round() : null;

      return Image.network(
        imageUrl!,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.contain,
        cacheHeight: targetCacheHeight,
        cacheWidth: targetCacheWidth,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: height,
            width: width ?? double.infinity,
            color: const Color(0xFFF5F0E8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB5A68A)),
              ),
            ),
          );
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: const Color(0xFFF5F0E8),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: height > 80 ? 13 : 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB5A68A),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
