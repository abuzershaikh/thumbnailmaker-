import 'dart:io';
import 'dart:math' as math;
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:flutter/material.dart';
import 'package:thumbnail_maker/src/models/element_model.dart';
import 'package:uuid/uuid.dart';


class _CanvasStateSnapshot {
  final List<CanvasElement> elements;
  final Color backgroundColor;

  _CanvasStateSnapshot(this.elements, this.backgroundColor);

  factory _CanvasStateSnapshot.deepCopy(List<CanvasElement> elements, Color backgroundColor) {
    List<CanvasElement> copiedElements = elements.map((e) {
      return CanvasProvider.elementFromJson(e.toJson());
    }).toList();
    return _CanvasStateSnapshot(copiedElements, backgroundColor);
  }
}


class CanvasProvider with ChangeNotifier {
  List<CanvasElement> _elements = [];
  Color _backgroundColor = Colors.white;
  double _zoomLevel = 1.0;
  final Uuid _uuid = const Uuid();

  CanvasElement? _selectedElement;

  Offset? _lastFocalPoint; // Not strictly used in current simplified gesture model
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  List<_CanvasStateSnapshot> _undoStack = [];
  List<_CanvasStateSnapshot> _redoStack = [];
  static const int _maxHistoryStack = 30;

  Color get backgroundColor => _backgroundColor;
  double get zoomLevel => _zoomLevel;
  List<CanvasElement> get elements => List.unmodifiable(_elements);
  CanvasElement? get selectedElement => _selectedElement;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  static CanvasElement elementFromJson(Map<String, dynamic> json) {
    ElementType type = ElementType.values.firstWhere((e) => e.name == json['type'], orElse: () => throw Exception('Unknown element type: ${json['type']}'));
    switch (type) {
      case ElementType.image:
        return ImageElement.fromJson(json);
      case ElementType.text:
        return TextElement.fromJson(json);
      case ElementType.rectangle:
        return RectangleElement.fromJson(json);
      case ElementType.circle:
        return CircleElement.fromJson(json);
      default:
        throw Exception('Unsupported element type for deserialization: $type');
    }
  }

  void _saveStateForUndo() {
    if (_undoStack.length >= _maxHistoryStack && _undoStack.isNotEmpty) {
      _undoStack.removeAt(0);
    }
    _undoStack.add(_CanvasStateSnapshot.deepCopy(_elements, _backgroundColor));
    _redoStack.clear();
    // notifyListeners(); // Called by the public method that invoked _saveStateForUndo or at the end of an action
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_CanvasStateSnapshot.deepCopy(List.from(_elements), _backgroundColor));
    final lastState = _undoStack.removeLast();
    _elements = List.from(lastState.elements);
    _backgroundColor = lastState.backgroundColor;
    _selectedElement = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_CanvasStateSnapshot.deepCopy(List.from(_elements), _backgroundColor));
    final nextState = _redoStack.removeLast();
    _elements = List.from(nextState.elements);
    _backgroundColor = nextState.backgroundColor;
    _selectedElement = null;
    notifyListeners();
  }

  Future<void> saveProject(String filePath) async {
    try {
      final projectData = {
        'backgroundColor': _backgroundColor.value,
        'elements': _elements.map((e) => e.toJson()).toList(),
      };
      final String jsonString = jsonEncode(projectData);
      await File(filePath).writeAsString(jsonString);
    } catch (e) {
      print('Error saving project: $e');
      rethrow;
    }
  }

  Future<void> loadProject(String filePath) async {
    try {
      final String jsonString = await File(filePath).readAsString();
      final Map<String, dynamic> projectData = jsonDecode(jsonString);

      // Save current state *before* loading, so loading itself is undoable
      _saveStateForUndo();

      _backgroundColor = Color(projectData['backgroundColor'] as int);
      final List<dynamic> elementListJson = projectData['elements'] as List<dynamic>;
      _elements = elementListJson.map((json) => elementFromJson(json as Map<String, dynamic>)).toList();

      _selectedElement = null;
      // _undoStack is managed by _saveStateForUndo
      // _redoStack is cleared by _saveStateForUndo
      notifyListeners();
    } catch (e) {
      print('Error loading project: $e');
      rethrow;
    }
  }

  void changeBackgroundColor(Color newColor) {
    if (_backgroundColor == newColor) return;
    _saveStateForUndo();
    _backgroundColor = newColor;
    notifyListeners();
  }

  void setZoomLevel(double newZoom) {
    double clampedZoom = newZoom.clamp(0.05, 10.0);
    if ((_zoomLevel - clampedZoom).abs() > 0.01) {
      _zoomLevel = clampedZoom;
      notifyListeners();
    }
  }

  Size _calculateTextSize(String text, TextStyle style, {double maxWidth = 1280 * 0.8}) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(minWidth: 0, maxWidth: maxWidth);
    return textPainter.size;
  }

  void addImageElement(String imagePath, Size imageSize) {
    _saveStateForUndo();
    const Offset defaultPosition = Offset(100, 100);
    final newElement = ImageElement(id: _uuid.v4(), imagePath: imagePath, position: defaultPosition, size: imageSize);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void addTextElement(String text, TextStyle initialStyle, Offset position) {
    _saveStateForUndo();
    final Size calculatedSize = _calculateTextSize(text, initialStyle);
    final newElement = TextElement(id: _uuid.v4(), text: text, position: position, style: initialStyle, size: calculatedSize);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void addRectangleElement() {
    _saveStateForUndo();
    const defaultSize = Size(200, 100);
    const defaultPosition = Offset(150, 150);
    final newElement = RectangleElement(id: _uuid.v4(), position: defaultPosition, size: defaultSize, color: Colors.blueAccent);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void addCircleElement() {
    _saveStateForUndo();
    const defaultRadius = 50.0;
    const defaultPosition = Offset(200, 200);
    final newElement = CircleElement(id: _uuid.v4(), position: defaultPosition, radius: defaultRadius, color: Colors.greenAccent);
    _elements.add(newElement);
    selectElement(newElement);
  }

  void updateElement(CanvasElement updatedElementFromToolbar) {
    final index = _elements.indexWhere((e) => e.id == updatedElementFromToolbar.id);
    if (index == -1) return;

    final currentElementInList = _elements[index];
    if (currentElementInList.isLocked) {
      // Optional: Provide feedback that element is locked (e.g., via a status message provider)
      // For now, silently ignore or print debug message.
      print("Element ${currentElementInList.id} is locked. Update from toolbar ignored.");
      return;
    }

    _saveStateForUndo();

    CanvasElement elementToUpdate = updatedElementFromToolbar; // It's already a new instance from copyWith in RightToolbar
    if (updatedElementFromToolbar is TextElement) {
      // Size recalculation if text or style that affects size has changed
      final oldElement = currentElementInList as TextElement;
      if (updatedElementFromToolbar.text != oldElement.text ||
          updatedElementFromToolbar.style.fontSize != oldElement.style.fontSize ||
          updatedElementFromToolbar.style.fontWeight != oldElement.style.fontWeight ||
          updatedElementFromToolbar.style.fontFamily != oldElement.style.fontFamily) {
         elementToUpdate = updatedElementFromToolbar.copyWith(size: _calculateTextSize(updatedElementFromToolbar.text, updatedElementFromToolbar.style));
      }
    }

    _elements[index] = elementToUpdate;
    _selectedElement = elementToUpdate;
    notifyListeners();
  }

  void selectElement(CanvasElement? element) {
    if (_selectedElement != element) {
      _selectedElement = element;
      notifyListeners();
    }
  }

  void toggleElementLock() {
    if (_selectedElement == null) return;
    _saveStateForUndo();

    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1) {
      final currentElement = _elements[index];
      // Use dynamic dispatch for copyWith to call the correct subclass implementation
      CanvasElement updatedElement = (currentElement as dynamic).copyWith(isLocked: !currentElement.isLocked);

      _elements[index] = updatedElement;
      _selectedElement = updatedElement; // Update selected element to the new instance
      notifyListeners();
    }
  }

  void bringToFront() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return; // Cannot reorder locked element
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1 && index < _elements.length - 1) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.add(element);
      notifyListeners();
    }
  }

  void sendToBack() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index > 0) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.insert(0, element);
      notifyListeners();
    }
  }

  void bringForward() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index != -1 && index < _elements.length - 1) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.insert(index + 1, element);
      notifyListeners();
    }
  }

  void sendBackward() {
    if (_selectedElement == null || _elements.length < 2) return;
    if (_selectedElement!.isLocked) return;
    final index = _elements.indexWhere((e) => e.id == _selectedElement!.id);
    if (index > 0) {
      _saveStateForUndo();
      final element = _elements.removeAt(index);
      _elements.insert(index - 1, element);
      notifyListeners();
    }
  }

  _CanvasStateSnapshot? _preGestureState;

  void onElementGestureStart(CanvasElement element) {
    if (element.isLocked) return; // Do not initiate gesture if element is locked

    if (_selectedElement != element) {
      selectElement(element);
    }
     _preGestureState = _CanvasStateSnapshot.deepCopy(List.from(_elements), _backgroundColor);
    _initialScale = element.scale;
    _initialRotation = element.rotation;
  }

  void panElement(CanvasElement element, Offset delta) {
    if (element.isLocked || element.id != _selectedElement?.id) return;

    final currentElement = _selectedElement!;
    currentElement.position += delta;
    notifyListeners();
  }

  void scaleAndRotateElement(ScaleUpdateDetails details) {
    if (_selectedElement == null || _selectedElement!.isLocked) return;
    final currentElement = _selectedElement!;
    double newScale = _initialScale * details.scale;
    currentElement.scale = newScale;
    currentElement.rotation = _initialRotation + details.rotation;
    notifyListeners();
  }

  void onElementGestureEnd() {
    if (_preGestureState == null) return; // Gesture was not started on a non-locked element or was on a locked one

    // Check if state actually changed to avoid empty undo states.
    // This simple check compares references of selected element and its properties.
    // A more robust check would compare all elements or use a hash.
    bool stateChanged = false;
    if (_selectedElement != null && _preGestureState!.elements.any((e) => e.id == _selectedElement!.id)) {
        final originalStateOfSelectedElement = _preGestureState!.elements.firstWhere((e) => e.id == _selectedElement!.id);
        if (originalStateOfSelectedElement.position != _selectedElement!.position ||
            originalStateOfSelectedElement.scale != _selectedElement!.scale ||
            originalStateOfSelectedElement.rotation != _selectedElement!.rotation) {
            stateChanged = true;
        }
    }


    if (stateChanged) {
       if (_undoStack.length >= _maxHistoryStack && _undoStack.isNotEmpty) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(_preGestureState!);
      _redoStack.clear();
    }
    _preGestureState = null;
    notifyListeners();
  }
}
