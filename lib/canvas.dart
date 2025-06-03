// File: canvas.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Required for ui.Image

// A custom class to hold image data and its properties on the canvas
class CanvasImage {
  ui.Image image; // The actual image data
  Offset position; // Current position on the canvas
  double scale; // Current scale of the image
  double rotation; // Current rotation of the image (for future use if needed)

  CanvasImage({
    required this.image,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

// CanvasScreen class that displays a fixed-size canvas and handles images.
class CanvasScreen extends StatefulWidget {
  final double canvasWidth;
  final double canvasHeight;

  const CanvasScreen({
    super.key,
    this.canvasWidth = 1280, // Default width for YouTube thumbnail
    this.canvasHeight = 720, // Default height for YouTube thumbnail
  });

  @override
  State<CanvasScreen> createState() => CanvasScreenState(); // Changed to CanvasScreenState
}

class CanvasScreenState extends State<CanvasScreen> { // Removed underscore
  final List<CanvasImage> _images = []; // List to hold all images on the canvas
  int? _selectedImageIndex; // Index of the currently selected image

  // Method to add an image to the canvas
  void addImage(ui.Image image) {
    setState(() {
      // Add the new image to the center of the canvas initially
      _images.add(CanvasImage(
        image: image,
        position: Offset(
          (widget.canvasWidth / 2) - (image.width / 2),
          (widget.canvasHeight / 2) - (image.height / 2),
        ),
      ));
      // Select the newly added image
      _selectedImageIndex = _images.length - 1;
    });
  }

  // Handle drag gestures for moving images
  void _onPanUpdate(DragUpdateDetails details, int index) {
    setState(() {
      _images[index].position += details.delta;
    });
  }

  // Handle scale gestures for resizing images
  void _onScaleUpdate(ScaleUpdateDetails details, int index) {
    setState(() {
      _images[index].scale = (details.scale * _images[index].scale).clamp(0.1, 5.0); // Clamp scale to prevent too small/large images
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.canvasWidth,
      height: widget.canvasHeight,
      decoration: BoxDecoration(
        color: Colors.white, // Background color of the canvas
        border: Border.all(color: Colors.black, width: 2), // Border on the canvas
        borderRadius: BorderRadius.circular(8), // Rounded corners of the canvas
      ),
      child: Stack(
        children: [
          // Placeholder text for the canvas
          Center(
            child: Text(
              'Canvas (${widget.canvasWidth.toInt()}x${widget.canvasHeight.toInt()})', // Display canvas dimensions
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          // Iterate through all images and display them on the canvas
          ..._images.asMap().entries.map((entry) {
            int index = entry.key;
            CanvasImage canvasImage = entry.value;

            return Positioned(
              left: canvasImage.position.dx,
              top: canvasImage.position.dy,
              child: GestureDetector(
                // Detect tap to select the image
                onTap: () {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                // Detect pan for moving the image
                onPanUpdate: (details) => _onPanUpdate(details, index),
                // Detect scale for resizing the image
                onScaleUpdate: (details) => _onScaleUpdate(details, index),
                child: Transform.scale(
                  scale: canvasImage.scale,
                  // Use a Container with a border to indicate selection
                  child: Container(
                    decoration: BoxDecoration(
                      border: _selectedImageIndex == index
                          ? Border.all(color: Colors.blue, width: 2) // Blue border when selected
                          : null,
                      borderRadius: BorderRadius.circular(4), // Slightly rounded corners for the border
                    ),
                    child: RawImage(
                      image: canvasImage.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
