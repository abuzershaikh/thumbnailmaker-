import 'dart:io'; // For Platform.isWindows
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thumbnail_maker/src/providers/canvas_provider.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';
import 'dart:math' as math; // For pi

class RightToolbar extends StatefulWidget {
  const RightToolbar({super.key});

  @override
  State<RightToolbar> createState() => _RightToolbarState();
}

class _RightToolbarState extends State<RightToolbar> {
  final TextEditingController _textEditingController = TextEditingController();
  Key _textFormFieldKey = UniqueKey();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  String _formatDouble(double value, {int places = 2}) {
    return value.toStringAsFixed(places);
  }

  String _getFileName(String path) {
    try {
      return path.split(Platform.isWindows ? '\\' : '/').last;
    } catch (e) {
      return path.length > 20 ? '...${path.substring(path.length - 20)}' : path;
    }
  }

  void _updateTextElement(CanvasProvider provider, TextElement element, {
    String? text,
    double? fontSizeDelta,
    Color? color,
    Color? textBackgroundColor,
    bool clearTextBackgroundColor = false,
    Color? outlineColor,
    bool clearOutlineColor = false,
    double? outlineWidthDelta,
  }) {
    if (element.isLocked) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Element is locked."), duration: Duration(milliseconds: 1200)));
      return;
    }
    TextStyle newStyle = element.style;
    if (fontSizeDelta != null) {
      double newFontSize = (element.style.fontSize ?? 16) + fontSizeDelta;
      newStyle = element.style.copyWith(fontSize: newFontSize.clamp(8, 200));
    }
    if (color != null) {
      newStyle = element.style.copyWith(color: color);
    }

    double newOutlineWidth = element.outlineWidth;
    if (outlineWidthDelta != null) {
      newOutlineWidth = (element.outlineWidth + outlineWidthDelta).clamp(0.0, 20.0);
    }

    provider.updateElement(element.copyWith(
      text: text ?? element.text,
      style: newStyle,
      textBackgroundColorGetter: clearTextBackgroundColor ? () => null : null,
      textBackgroundColor: clearTextBackgroundColor ? null : (textBackgroundColor ?? element.textBackgroundColor),
      outlineColorGetter: clearOutlineColor ? () => null : null,
      outlineColor: clearOutlineColor ? null : (outlineColor ?? element.outlineColor),
      outlineWidth: newOutlineWidth,
    ));
  }

  void _updateShapeElement(CanvasProvider provider, CanvasElement element, {
    Color? fillColor,
    Color? outlineColor,
    bool clearOutlineColor = false,
    double? outlineWidthDelta,
    Size? newSize // Not used for MVP outline/fill, but kept for signature consistency
  }) {
    if (element.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Element is locked."), duration: Duration(milliseconds: 1200)));
      return;
    }

    double newOutlineWidth = 0.0;
    if (element is RectangleElement) newOutlineWidth = element.outlineWidth;
    if (element is CircleElement) newOutlineWidth = element.outlineWidth;

    if (outlineWidthDelta != null) {
      newOutlineWidth = (newOutlineWidth + outlineWidthDelta).clamp(0.0, 20.0);
    }

     if (element is RectangleElement) {
        provider.updateElement(element.copyWith(
          color: fillColor ?? element.color,
          outlineColorGetter: clearOutlineColor ? () => null : null,
          outlineColor: clearOutlineColor ? null : (outlineColor ?? element.outlineColor),
          outlineWidth: newOutlineWidth,
          size: newSize ?? element.size
        ));
     } else if (element is CircleElement) {
        provider.updateElement(element.copyWith(
          color: fillColor ?? element.color,
          outlineColorGetter: clearOutlineColor ? () => null : null,
          outlineColor: clearOutlineColor ? null : (outlineColor ?? element.outlineColor),
          outlineWidth: newOutlineWidth,
          radius: newSize != null ? newSize.width / 2 : element.radius // Keep radius update logic if newSize is passed
        ));
     }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<CanvasProvider>(
      builder: (context, canvasProvider, child) {
        final selectedElement = canvasProvider.selectedElement;
        final elements = canvasProvider.elements;
        final canvasProviderNoListen = Provider.of<CanvasProvider>(context, listen: false);

        int selectedElementIndex = -1;
        if (selectedElement != null) {
          selectedElementIndex = elements.indexWhere((e) => e.id == selectedElement.id);
        }

        bool isElementLocked = selectedElement?.isLocked ?? false;
        bool canSendBackward = selectedElement != null && selectedElementIndex > 0 && !isElementLocked;
        bool canBringForward = selectedElement != null && selectedElementIndex < elements.length - 1 && selectedElementIndex != -1 && !isElementLocked;

        if (selectedElement is TextElement && _textEditingController.text != selectedElement.text) {
          _textEditingController.text = selectedElement.text;
          _textFormFieldKey = UniqueKey();
        } else if (selectedElement == null || selectedElement is! TextElement) {
           _textEditingController.clear();
        }

        return Container(
          width: 230,
          color: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Canvas Tools', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildCanvasTools(context, canvasProviderNoListen),

                const Divider(height: 30, thickness: 1.5),

                Text('Selected Element', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (selectedElement == null)
                  const Center(child: Text('No element selected.', textAlign: TextAlign.center,))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('ID: ${selectedElement.id.substring(0,6)}...', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: Icon(selectedElement.isLocked ? Icons.lock : Icons.lock_open),
                        tooltip: selectedElement.isLocked ? 'Unlock Element' : 'Lock Element',
                        onPressed: () {
                          canvasProviderNoListen.toggleElementLock();
                        },
                        color: selectedElement.isLocked ? Colors.orangeAccent[700] : Colors.grey[700],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildLayerControls(context, canvasProviderNoListen, canBringForward, canSendBackward, isElementLocked),
                  const SizedBox(height: 10),
                  _buildPropertyRow('Type:', selectedElement.type.toString().split('.').last),
                  _buildPropertyRow('Scale:', _formatDouble(selectedElement.scale)),
                  _buildPropertyRow('Rotation:', '${_formatDouble(selectedElement.rotation * 180 / math.pi, places: 1)}°'),
                  _buildPropertyRow('X:', _formatDouble(selectedElement.position.dx, places: 1)),
                  _buildPropertyRow('Y:', _formatDouble(selectedElement.position.dy, places: 1)),

                  if (selectedElement is ImageElement) ..._buildImageSpecificProperties(selectedElement, isElementLocked),
                  if (selectedElement is TextElement) ..._buildTextSpecificProperties(context, canvasProviderNoListen, selectedElement, isElementLocked),
                  if (selectedElement is RectangleElement) ..._buildShapeProperties(context, canvasProviderNoListen, selectedElement, isElementLocked, isRect: true),
                  if (selectedElement is CircleElement) ..._buildShapeProperties(context, canvasProviderNoListen, selectedElement, isElementLocked, isRect: false),

                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => canvasProviderNoListen.selectElement(null),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
                      child: const Text('Deselect', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayerControls(BuildContext context, CanvasProvider provider, bool canBringForward, bool canSendBackward, bool isLocked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Layering:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.vertical_align_bottom), tooltip: 'Send to Back', onPressed: canSendBackward ? provider.sendToBack : null),
            IconButton(icon: const Icon(Icons.keyboard_arrow_down), tooltip: 'Send Backward', onPressed: canSendBackward ? provider.sendBackward : null),
            IconButton(icon: const Icon(Icons.keyboard_arrow_up), tooltip: 'Bring Forward', onPressed: canBringForward ? provider.bringForward : null),
            IconButton(icon: const Icon(Icons.vertical_align_top), tooltip: 'Bring to Front', onPressed: canBringForward ? provider.bringToFront : null),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildImageSpecificProperties(ImageElement element, bool isLocked) {
     return [
      _buildPropertyRow('File:', _getFileName(element.imagePath), overflow: TextOverflow.ellipsis),
      _buildPropertyRow('Orig. W:', '${_formatDouble(element.size.width, places: 0)}px'),
      _buildPropertyRow('Orig. H:', '${_formatDouble(element.size.height, places: 0)}px'),
      _buildPropertyRow('Disp. W:', '${_formatDouble(element.size.width * element.scale, places: 1)}px'),
      _buildPropertyRow('Disp. H:', '${_formatDouble(element.size.height * element.scale, places: 1)}px'),
    ];
  }

  List<Widget> _buildTextSpecificProperties(BuildContext context, CanvasProvider provider, TextElement element, bool isLocked) {
    return [
      const SizedBox(height: 8),
      TextFormField(
        key: _textFormFieldKey,
        initialValue: element.text,
        enabled: !isLocked,
        decoration: const InputDecoration(labelText: 'Text Content', border: OutlineInputBorder(), isDense: true),
        onChanged: (newText) {
           if(!isLocked) _updateTextElement(provider, element, text: newText);
        },
      ),
      const SizedBox(height: 10),
      _buildPropertyRow('Font Size:', _formatDouble(element.style.fontSize ?? 0, places: 0)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: isLocked ? null : () => _updateTextElement(provider, element, fontSizeDelta: -2)),
        IconButton(icon: const Icon(Icons.add), onPressed: isLocked ? null : () => _updateTextElement(provider, element, fontSizeDelta: 2)),
      ]),
      const SizedBox(height: 8),
      Text('Font Color:', style: Theme.of(context).textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.black, isTextFontColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.red, isTextFontColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.white, isTextFontColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.blue, isTextFontColor: true, isLocked: isLocked),
      ]),
      const SizedBox(height: 10),
      Text('Background Color:', style: Theme.of(context).textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.transparent, isTextBg: true, clearColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.yellowAccent, isTextBg: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.lightBlueAccent, isTextBg: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.grey[300]!, isTextBg: true, isLocked: isLocked),
      ]),
       const SizedBox(height: 10),
      Text('Outline Color:', style: Theme.of(context).textTheme.bodyMedium),
       Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.transparent, isOutline: true, clearColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.black, isOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.white, isOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.red, isOutline: true, isLocked: isLocked),
      ]),
      const SizedBox(height: 8),
      _buildPropertyRow('Outline Width:', _formatDouble(element.outlineWidth, places: 1)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: isLocked ? null : () => _updateTextElement(provider, element, outlineWidthDelta: -0.5)),
        IconButton(icon: const Icon(Icons.add), onPressed: isLocked ? null : () => _updateTextElement(provider, element, outlineWidthDelta: 0.5)),
      ]),
      _buildPropertyRow('Box W:', '${_formatDouble(element.size.width * element.scale, places: 1)}px'),
      _buildPropertyRow('Box H:', '${_formatDouble(element.size.height* element.scale, places: 1)}px'),
    ];
  }

  List<Widget> _buildShapeProperties(BuildContext context, CanvasProvider provider, CanvasElement element, bool isLocked, {required bool isRect}) {
    Color currentFillColor = Colors.transparent;
    Color? currentOutlineColor;
    double currentOutlineWidth = 0.0;

    if (element is RectangleElement) {
      currentFillColor = element.color;
      currentOutlineColor = element.outlineColor;
      currentOutlineWidth = element.outlineWidth;
    } else if (element is CircleElement) {
      currentFillColor = element.color;
      currentOutlineColor = element.outlineColor;
      currentOutlineWidth = element.outlineWidth;
    }

    return [
      const SizedBox(height: 8),
      Text('Fill Color:', style: Theme.of(context).textTheme.bodyMedium),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.blue, isLocked: isLocked, isShapeFill: true),
        _colorButton(context, provider, element, Colors.green, isLocked: isLocked, isShapeFill: true),
        _colorButton(context, provider, element, Colors.yellow, isLocked: isLocked, isShapeFill: true),
        _colorButton(context, provider, element, Colors.orange, isLocked: isLocked, isShapeFill: true),
      ]),
      const SizedBox(height: 10),
      Text('Outline Color:', style: Theme.of(context).textTheme.bodyMedium),
       Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _colorButton(context, provider, element, Colors.transparent, isShapeOutline: true, clearColor: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.black, isShapeOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.white, isShapeOutline: true, isLocked: isLocked),
        _colorButton(context, provider, element, Colors.red, isShapeOutline: true, isLocked: isLocked),
      ]),
      const SizedBox(height: 8),
      _buildPropertyRow('Outline Width:', _formatDouble(currentOutlineWidth, places: 1)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        IconButton(icon: const Icon(Icons.remove), onPressed: isLocked ? null : () => _updateShapeElement(provider, element, outlineWidthDelta: -0.5)),
        IconButton(icon: const Icon(Icons.add), onPressed: isLocked ? null : () => _updateShapeElement(provider, element, outlineWidthDelta: 0.5)),
      ]),
      if (isRect && element is RectangleElement) ...[
         _buildPropertyRow('Base W:', '${_formatDouble(element.size.width, places: 1)}px'),
         _buildPropertyRow('Base H:', '${_formatDouble(element.size.height, places: 1)}px'),
      ] else if (!isRect && element is CircleElement) ...[
        _buildPropertyRow('Radius:', '${_formatDouble(element.radius, places: 1)}px'),
      ]
    ];
  }

  Widget _buildPropertyRow(String label, String value, {TextOverflow overflow = TextOverflow.clip}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(width: 8),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: overflow)),
      ]),
    );
  }

  Widget _colorButton(BuildContext context, CanvasProvider provider, CanvasElement element, Color color, {
    bool isTextFontColor = false, bool isLocked = false,
    bool isTextBg = false, bool isOutline = false,
    bool isShapeFill = false, bool isShapeOutline = false,
    bool clearColor = false
  }) {
    bool isSelectedColor = false;
    Color? actualColorToCompare;

    if (isTextFontColor && element is TextElement) actualColorToCompare = element.style.color;
    else if (isTextBg && element is TextElement) actualColorToCompare = element.textBackgroundColor;
    else if (isOutline && element is TextElement) actualColorToCompare = element.outlineColor;
    else if (isShapeFill && element is RectangleElement) actualColorToCompare = element.color;
    else if (isShapeFill && element is CircleElement) actualColorToCompare = element.color;
    else if (isShapeOutline && element is RectangleElement) actualColorToCompare = element.outlineColor;
    else if (isShapeOutline && element is CircleElement) actualColorToCompare = element.outlineColor;

    isSelectedColor = clearColor ? actualColorToCompare == null : actualColorToCompare == color;

    return InkWell(
      onTap: isLocked ? null : () {
        if (element is TextElement) {
           _updateTextElement(provider, element,
            color: isTextFontColor ? color : null,
            textBackgroundColor: isTextBg && !clearColor ? color : null,
            clearTextBackgroundColor: isTextBg && clearColor,
            outlineColor: isOutline && !clearColor ? color : null,
            clearOutlineColor: isOutline && clearColor,
           );
        } else if (element is RectangleElement || element is CircleElement) {
          _updateShapeElement(provider, element,
            fillColor: isShapeFill ? color : null,
            outlineColor: isShapeOutline && !clearColor ? color : null,
            clearOutlineColor: isShapeOutline && clearColor
          );
        }
      },
      child: Opacity(
        opacity: isLocked && !isSelectedColor ? 0.5 : 1.0,
        child: Container(
          width: 28, height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: clearColor ? Colors.grey[300] : color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[400]!, width: (color == Colors.white || isSelectedColor) ? 2 : 0.5),
            boxShadow: isSelectedColor ? [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)] : [],
          ),
           child: clearColor && actualColorToCompare == null ? Icon(Icons.check, color: Colors.grey[700], size: 16)
                 : (isSelectedColor && !clearColor ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null),
        ),
      ),
    );
  }

   Widget _buildCanvasTools(BuildContext context, CanvasProvider canvasProviderNoListen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Background:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        ElevatedButton(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.white), child: const Text('White')),
        ElevatedButton(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.grey[300]!), child: const Text('Light Grey')),
        ElevatedButton(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.black), child: const Text('Black')),
        ElevatedButton(onPressed: () => canvasProviderNoListen.changeBackgroundColor(Colors.red[100]!), child: const Text('Light Red')),
        const SizedBox(height: 16),
        Text('Zoom Level:', style: Theme.of(context).textTheme.titleSmall),
        Consumer<CanvasProvider>(
            builder: (context, provider, child) {
            final String formattedZoom = provider.zoomLevel.toStringAsFixed(1);
            return Text('${formattedZoom}x', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge);
            }
        ),
      ],
    );
  }
}
