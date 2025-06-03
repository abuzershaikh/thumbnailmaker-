import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';
import 'package:thumbnail_maker/src/widgets/toolbars/left_toolbar.dart';
import 'package:thumbnail_maker/src/widgets/toolbars/right_toolbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(() {
      final newZoom = _transformationController.value.getMaxScaleOnAxis();
      Provider.of<CanvasProvider>(context, listen: false).setZoomLevel(newZoom);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _exportCanvasAsPng() async {
    // ... (existing export code)
    try {
      if (!mounted || _canvasKey.currentContext == null) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Canvas not ready.')));
        return;
      }
      RenderRepaintBoundary boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Could not get image data.');
      Uint8List pngBytes = byteData.buffer.asUint8List();

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Thumbnail as PNG',
        fileName: 'thumbnail-${DateTime.now().millisecondsSinceEpoch}.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.png')) {
          outputFile += '.png';
        }
        File savedFile = File(outputFile);
        await savedFile.writeAsBytes(pngBytes);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to: ${savedFile.path}')));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save cancelled.')));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _saveProject() async {
    // ... (existing save project code)
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Project',
        fileName: 'project.thumbnailproj',
        type: FileType.custom,
        allowedExtensions: ['thumbnailproj'],
      );

      if (outputFile != null) {
        if (!outputFile.toLowerCase().endsWith('.thumbnailproj')) {
          outputFile += '.thumbnailproj';
        }
        await Provider.of<CanvasProvider>(context, listen: false).saveProject(outputFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project saved to: $outputFile')));
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save project cancelled.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving project: ${e.toString()}')));
    }
  }

  Future<void> _loadProject() async {
    // ... (existing load project code)
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Load Project',
        type: FileType.custom,
        allowedExtensions: ['thumbnailproj', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await Provider.of<CanvasProvider>(context, listen: false).loadProject(path);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project loaded from: $path')));
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Load project cancelled.')));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading project: ${e.toString()}')));
    }
  }


  Widget _buildElementWidget(CanvasElement element, CanvasProvider provider, double currentCanvasZoom) {
    Widget content;
    BoxDecoration? shapeDecoration;

    if (element is ImageElement) {
      content = Image.file(
        File(element.imagePath),
        width: element.size.width,
        height: element.size.height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.red[100], alignment: Alignment.center, padding: const EdgeInsets.all(4),
            child: Text('Error: ${element.imagePath.split('/').last}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.red)),
          );
        },
      );
    } else if (element is TextElement) {
      Widget fillText = Text(element.text, style: element.style, textAlign: element.textAlign);
      Widget? textContentWidget;

      if (element.outlineColor != null && element.outlineWidth > 0) {
        textContentWidget = Stack(
          alignment: Alignment.center,
          children: [
            Text(
              element.text,
              textAlign: element.textAlign,
              style: element.style.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = element.outlineWidth
                  ..color = element.outlineColor!,
              ),
            ),
            fillText,
          ],
        );
      } else {
        textContentWidget = fillText;
      }

      if (element.textBackgroundColor != null) {
        content = Container(
          // Size of this container should match the TextElement's calculated size for background to fit tightly.
          // The TextPainter's calculated size is stored in element.size.
          width: element.size.width,
          height: element.size.height,
          padding: EdgeInsets.all(4.0), // Consider if padding should scale: 4.0 * element.scale
          decoration: BoxDecoration(color: element.textBackgroundColor),
          child: textContentWidget,
        );
      } else {
        content = textContentWidget;
      }

    } else if (element is RectangleElement) {
      shapeDecoration = BoxDecoration(
        color: element.color,
        border: (element.outlineColor != null && element.outlineWidth > 0)
            ? Border.all(color: element.outlineColor!, width: element.outlineWidth)
            : null,
      );
      content = SizedBox(width: element.size.width, height: element.size.height);
    } else if (element is CircleElement) {
      shapeDecoration = BoxDecoration(
        color: element.color,
        shape: BoxShape.circle,
        border: (element.outlineColor != null && element.outlineWidth > 0)
            ? Border.all(color: element.outlineColor!, width: element.outlineWidth)
            : null,
      );
      content = SizedBox(width: element.size.width, height: element.size.height);
    } else {
      content = const SizedBox.shrink();
    }

    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.size.width,
      height: element.size.height,
      child: GestureDetector(
        onTap: () => provider.selectElement(element),
        onScaleStart: (details) {
          if (element.isLocked) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Element is locked."), duration: Duration(milliseconds: 1200)));
            return;
          }
          provider.onElementGestureStart(element);
        },
        onScaleUpdate: (details) {
          if (element.isLocked) return;
          if (details.pointerCount > 1 || (details.scale - 1.0).abs() > 0.01 || details.rotation.abs() > 0.01) {
            provider.scaleAndRotateElement(details);
          } else if (details.pointerCount == 1) {
            Offset panDelta = details.focalPointDelta / currentCanvasZoom;
            setState(() => element.position += panDelta);
          }
        },
        onScaleEnd: (details) {
          if (element.isLocked) return;
          provider.onElementGestureEnd();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(element.size.width / 2, element.size.height / 2)
                ..rotateZ(element.rotation)
                ..scale(element.scale)
                ..translate(-element.size.width / 2, -element.size.height / 2),
              child: Container(
                width: element.size.width,
                height: element.size.height,
                decoration: shapeDecoration, // Used for shapes
                // For non-shape elements, selection border is applied here if not locked
                // For shapes, their own decoration includes fill and outline. Selection border is handled below.
                child: (element is ImageElement || element is TextElement) ? content : null,
              ),
            ),
            if (element.isLocked)
              Positioned(
                top: 0, right: 0,
                child: Transform.scale(
                  scale: 1.0 / (element.scale * currentCanvasZoom),
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.all(2.0 / (element.scale * currentCanvasZoom)),
                    color: Colors.black.withOpacity(0.1),
                    child: Icon(Icons.lock, color: Colors.white.withOpacity(0.7), size: 16.0),
                  ),
                ),
              ),
            // Selection border: Common for all, drawn on top if selected and not locked
            if (provider.selectedElement?.id == element.id && !element.isLocked)
              Positioned.fill(
                child: Transform( // Apply same transform as the element for the border
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(element.size.width / 2, element.size.height / 2)
                    ..rotateZ(element.rotation)
                    ..scale(element.scale)
                    ..translate(-element.size.width / 2, -element.size.height / 2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: element is CircleElement ? BoxShape.circle : BoxShape.rectangle,
                      border: Border.all(
                        color: Colors.blueAccent,
                        width: 2.0 / (element.scale * currentCanvasZoom), // Make border width visually consistent
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


  @override
  Widget build(BuildContext context) {
    // ... (rest of build method is unchanged)
    final canvasProvider = Provider.of<CanvasProvider>(context);
    double currentCanvasZoom = canvasProvider.zoomLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Thumbnail Maker'),
        backgroundColor: Colors.redAccent,
        actions: [
          Consumer<CanvasProvider>(builder: (context, provider, child) => IconButton(icon: const Icon(Icons.undo), tooltip: 'Undo', onPressed: provider.canUndo ? provider.undo : null)),
          Consumer<CanvasProvider>(builder: (context, provider, child) => IconButton(icon: const Icon(Icons.redo), tooltip: 'Redo', onPressed: provider.canRedo ? provider.redo : null)),
          IconButton(icon: const Icon(Icons.folder_open), tooltip: 'Load Project', onPressed: _loadProject),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save Project', onPressed: _saveProject),
          IconButton(icon: const Icon(Icons.save_alt), tooltip: 'Export as PNG', onPressed: _exportCanvasAsPng),
          IconButton(icon: const Icon(Icons.zoom_out), tooltip: 'Zoom Out', onPressed: () {
              const double scaleFactor = 1.2;
              final currentZoomVal = _transformationController.value.getMaxScaleOnAxis();
              double newScale = (currentZoomVal / scaleFactor).clamp(0.05, 10.0);
              _transformationController.value = Matrix4.identity()..scale(newScale);
            },
          ),
          IconButton(icon: const Icon(Icons.zoom_in), tooltip: 'Zoom In', onPressed: () {
              const double scaleFactor = 1.2;
              final currentZoomVal = _transformationController.value.getMaxScaleOnAxis();
              double newScale = (currentZoomVal * scaleFactor).clamp(0.05, 10.0);
              _transformationController.value = Matrix4.identity()..scale(newScale);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          const LeftToolbar(),
          Expanded(
            child: Container(
              color: Colors.grey[800],
              child: InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.05,
                maxScale: 10.0,
                onInteractionEnd: (details) {
                   Provider.of<CanvasProvider>(context, listen: false).setZoomLevel(_transformationController.value.getMaxScaleOnAxis());
                },
                child: Center(
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Container(
                      width: 1280,
                      height: 720,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: canvasProvider.backgroundColor,
                        border: Border.all(color: Colors.black54, width: 1.0 / currentCanvasZoom),
                      ),
                      child: Consumer<CanvasProvider>(
                        builder: (context, provider, child) {
                          return Stack(
                            children: provider.elements.map((element) {
                              return _buildElementWidget(element, provider, currentCanvasZoom);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const RightToolbar(),
        ],
      ),
    );
  }
}
