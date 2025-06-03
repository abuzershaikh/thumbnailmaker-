// File: main.dart
import 'package:flutter/material.dart';
import 'package:thumbnailmaker/canvas.dart'; // Import canvas.dart to access CanvasScreen and CanvasScreenState
import 'package:file_picker/file_picker.dart'; // Required for picking files
import 'dart:typed_data'; // Required for Uint8List (raw image bytes)
import 'dart:ui' as ui; // Required for ui.Image (Flutter's image object)

// Main entry point of the application
void main() {
  runApp(const MyApp());
}

// MyApp class which is the root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Thumbnail Maker', // Title of the application
      theme: ThemeData(
        primarySwatch: Colors.blue, // Primary color scheme
      ),
      home: const ThumbnailMakerScreen(), // Home screen
    );
  }
}

// ThumbnailMakerScreen class that handles the main UI
class ThumbnailMakerScreen extends StatefulWidget {
  const ThumbnailMakerScreen({super.key});

  @override
  State<ThumbnailMakerScreen> createState() => _ThumbnailMakerScreenState();
}

class _ThumbnailMakerScreenState extends State<ThumbnailMakerScreen> {
  // GlobalKey to access the methods (like addImage) of the CanvasScreenState
  // We use GlobalKey<CanvasScreenState> because CanvasScreenState is now public.
  final GlobalKey<CanvasScreenState> _canvasKey = GlobalKey<CanvasScreenState>();

  // State of the right panel (open or closed)
  bool _isRightPanelOpen = true;

  // Function to handle image import from the file manager
  Future<void> _importImage() async {
    print('Attempting to import image...'); // Debugging: Started import process
    try {
      // 1. Open file picker dialog to select an image
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // Restrict selection to image files only
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'], // Specify common image extensions
        allowMultiple: false, // Allow only single file selection
      );

      // 2. Check if a file was actually selected and has data
      if (result != null && result.files.single.bytes != null) {
        // Get the raw bytes of the selected image
        Uint8List bytes = result.files.single.bytes!;
        print('File selected: ${result.files.single.name} (${bytes.lengthInBytes} bytes)'); // Debugging: File selected info

        // 3. Decode the raw bytes into a Flutter ui.Image object
        ui.Image image = await decodeImageFromList(bytes);
        print('Image decoded successfully.'); // Debugging: Image decoded

        // 4. Pass the ui.Image object to the CanvasScreen to add it to the canvas
        // Check if the canvas state is available before trying to call addImage
        if (_canvasKey.currentState != null) {
          _canvasKey.currentState?.addImage(image);
          print('Image successfully sent to canvas.'); // Debugging: Image added to canvas
        } else {
          print('Error: CanvasScreenState is not available via GlobalKey.'); // Debugging: Key issue
        }
      } else {
        // User canceled the picker or no file was selected (e.g., dialog closed)
        print('No image selected or canceled by user.'); // Debugging: No selection
      }
    } catch (e) {
      // Catch any errors during the picking or processing
      print('Error picking or processing image: $e'); // Debugging: General error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the actual dimensions for the YouTube thumbnail canvas
    const double canvasActualWidth = 1280.0;
    const double canvasActualHeight = 720.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Thumbnail Maker'),
        // Flutter automatically provides a menu icon when 'drawer' is used.
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _isRightPanelOpen = !_isRightPanelOpen; // Toggle right panel visibility
              });
            },
            tooltip: 'Toggle right panel',
          ),
        ],
      ),
      // The left toolbar (Drawer) contains the "Import Image" button
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Tools',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // The "Import Image" button within the Drawer
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Import Image'),
              onTap: () {
                _importImage(); // Call the image import function
                Navigator.pop(context); // Close the drawer after selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('Resize & Move (on canvas)'),
              onTap: () {
                // This option indicates interaction directly on the canvas.
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Main content area containing the scaled canvas
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double scale = 1.0;
                  final double widthScale = constraints.maxWidth / canvasActualWidth;
                  final double heightScale = constraints.maxHeight / canvasActualHeight;
                  scale = (widthScale < heightScale) ? widthScale : heightScale;

                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: canvasActualWidth,
                      height: canvasActualHeight,
                      child: CanvasScreen(
                        key: _canvasKey, // Assign the GlobalKey to CanvasScreen
                        canvasWidth: canvasActualWidth,
                        canvasHeight: canvasActualHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Right panel (toolbar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isRightPanelOpen ? 250 : 0,
            color: Colors.grey[200],
            child: _isRightPanelOpen
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Right Toolbar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Properties and layers here',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Save button action
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
