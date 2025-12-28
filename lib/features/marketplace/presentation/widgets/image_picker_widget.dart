// Image Picker Widget
// =====================================================
// lib/features/marketplace/presentation/widgets/image_picker_widget.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // <-- Add this import


class ImagePickerWidget extends StatefulWidget {
  final List<XFile> images; // initial images
  final Function(List<XFile>) onImagesSelected;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.images = const [],
    this.maxImages = 5,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  late List<XFile> _images;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = List<XFile>.from(widget.images);
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(
          pickedFiles.take(widget.maxImages - _images.length),
        );
      });
      widget.onImagesSelected(_images);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesSelected(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images (${_images.length}/${widget.maxImages})'),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (_images.length < widget.maxImages)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40),
                        SizedBox(height: 8),
                        Text('Add Photos'),
                      ],
                    ),
                  ),
                ),
              ..._images.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: Image.file(
                            File(entry.value.path),
                          ).image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(entry.key),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
