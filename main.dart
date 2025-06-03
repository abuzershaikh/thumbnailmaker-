import 'package:flutter/material.dart';

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
        primarySwatch: Colors.blue, // Primary color scheme of the application
        // For 'Inter' font, you would need to add it to pubspec.yaml
        // and then use it here. For example:
        // fontFamily: 'Inter',
      ),
      home: const ThumbnailMakerScreen(), // Home screen of the application
    );
  }
}

// ThumbnailMakerScreen class that handles the main UI
class ThumbnailMakerScreen extends StatefulWidget {
  const ThumbnailMakerScreen({super.key});

  @override
  State<ThumbnailMakerScreen> createState() => _ThumbnailMakerScreenState();
}

// _ThumbnailMakerScreenState class that handles the state for ThumbnailMakerScreen
class _ThumbnailMakerScreenState extends State<ThumbnailMakerScreen> {
  // State of the left panel (open or closed)
  bool _isLeftPanelOpen = true;
  // State of the right panel (open or closed)
  bool _isRightPanelOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Thumbnail Maker'), // Title of the app bar
        leading: IconButton(
          icon: const Icon(Icons.menu), // Icon to toggle the left panel
          onPressed: () {
            setState(() {
              _isLeftPanelOpen = !_isLeftPanelOpen; // Toggle the state of the left panel
            });
          },
          tooltip: 'Toggle left panel', // Tooltip text
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), // Icon to toggle the right panel
            onPressed: () {
              setState(() {
                _isRightPanelOpen = !_isRightPanelOpen; // Toggle the state of the right panel
              });
            },
            tooltip: 'Toggle right panel', // Tooltip text
          ),
        ],
      ),
      body: Row(
        children: [
          // Left panel (toolbar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Duration of the animation
            width: _isLeftPanelOpen ? 250 : 0, // 250px wide if open, otherwise 0px
            color: Colors.grey[200], // Background color of the panel
            child: _isLeftPanelOpen
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0), // Padding
                        child: Text(
                          'Left Toolbar',
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
                            'Tools and options here',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      // Example for a rounded corner button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Button action
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Rounded corners
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('New Project'),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(), // Hide content when closed
          ),
          // Main content area (canvas)
          Expanded(
            child: Center(
              child: Container(
                width: 1280, // Fixed width of the canvas
                height: 720, // Fixed height of the canvas
                decoration: BoxDecoration(
                  color: Colors.white, // Background color of the canvas
                  border: Border.all(color: Colors.black, width: 2), // Border on the canvas
                  borderRadius: BorderRadius.circular(8), // Rounded corners of the canvas
                ),
                child: const Center(
                  child: Text(
                    'Canvas (1280x780)',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Right panel (toolbar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Duration of the animation
            width: _isRightPanelOpen ? 250 : 0, // 250px wide if open, otherwise 0px
            color: Colors.grey[200], // Background color of the panel
            child: _isRightPanelOpen
                ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0), // Padding
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
                      // Example for a rounded corner button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            // Button action
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Rounded corners
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(), // Hide content when closed
          ),
        ],
      ),
    );
  }
}
