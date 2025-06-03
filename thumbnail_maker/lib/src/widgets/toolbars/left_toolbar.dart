import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';

class LeftToolbar extends StatelessWidget {
  const LeftToolbar({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final imageFile = File(filePath);

        var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
        Size imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

        canvasProvider.addImageElement(filePath, imageSize);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _showAddTextDialog(BuildContext context) async {
    final canvasProvider = Provider.of<CanvasProvider>(context, listen: false);
    final TextEditingController textController = TextEditingController();

    // Position in roughly the center of a 1280x720 canvas
    const Offset defaultTextPosition = Offset(580, 330);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Text Element'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter your text"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  const TextStyle defaultTextStyle = TextStyle(
                    fontSize: 50,
                    color: Colors.black,
                  );
                  canvasProvider.addTextElement(
                    textController.text,
                    defaultTextStyle,
                    defaultTextPosition,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasProviderNoListen = Provider.of<CanvasProvider>(context, listen: false);

    return Container(
      width: 200,
      color: Colors.blueGrey[100],
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView( // Added to prevent overflow if many buttons
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Elements',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Add Image'),
              onPressed: () => _pickImage(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.text_fields),
              label: const Text('Add Text'),
              onPressed: () => _showAddTextDialog(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.crop_square), // Icon for rectangle
              label: const Text('Add Rectangle'),
              onPressed: () {
                canvasProviderNoListen.addRectangleElement();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.circle_outlined), // Icon for circle
              label: const Text('Add Circle'),
              onPressed: () {
                canvasProviderNoListen.addCircleElement();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.greenAccent[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
