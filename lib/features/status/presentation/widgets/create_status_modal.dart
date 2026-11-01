import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/status_controller.dart';

/// Modal untuk membuat status baru (Teks atau Foto)
class CreateStatusModal {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CreateStatusSheet(ref: ref),
    );
  }
}

class _CreateStatusSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateStatusSheet({required this.ref});

  @override
  State<_CreateStatusSheet> createState() => _CreateStatusSheetState();
}

class _CreateStatusSheetState extends State<_CreateStatusSheet> {
  final TextEditingController _textController = TextEditingController();
  final List<int> _colorPresets = [
    0xFF6C5CE7, // Ungu RAYA
    0xFF00B894, // Hijau Toska
    0xFF0984E3, // Biru Elektrik
    0xFFE17055, // Oranye Hangat
    0xFFD63031, // Merah Ruby
    0xFF2D3436, // Gelap Minimalis
  ];
  late int _selectedColor;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedColor = _colorPresets[0];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 50,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final base64Img = base64Encode(bytes);
        await widget.ref.read(statusControllerProvider.notifier).postImageStatus(
              base64Img,
              text.isNotEmpty ? text : null,
            );
      } else {
        await widget.ref.read(statusControllerProvider.notifier).postTextStatus(
              text,
              _selectedColor,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil dibagikan!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan status: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.screenMarginHorizontal,
        right: AppSpacing.screenMarginHorizontal,
        top: AppSpacing.s20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Buat Status Baru',
                style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.s16),

              // Pratinjau Teks atau Gambar
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedImage != null ? Colors.black : Color(_selectedColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          Center(
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => setState(() => _selectedImage = null),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: TextField(
                          controller: _textController,
                          maxLines: 4,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ketik apa yang Anda pikirkan...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // Pilihan Warna Background (jika bukan foto)
              if (_selectedImage == null) ...[
                const Text(
                  'Warna Latar Belakang:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _colorPresets.map((c) {
                    final isSel = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.s16),
              ],

              // Tombol Tambah Foto dari Galeri / Kamera & Kirim
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGlow),
                    tooltip: 'Pilih dari Galeri',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGlow),
                    tooltip: 'Ambil Foto Langsung',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Mengunggah...' : 'Bagikan'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ),
    );
  }
}

