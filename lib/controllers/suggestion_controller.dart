import 'package:flutter/foundation.dart';

class SuggestionController<T> extends ChangeNotifier {
  T? _selectedItem;
  String Function(T? data) itemAsString;
  String? _text;

  SuggestionController({T? selectedItem, required this.itemAsString}) : _selectedItem = selectedItem;

  void onChangeSelection(T? value) {
    _selectedItem = value;
    _text = itemAsString(_selectedItem);
    notifyListeners();
  }

  T? get selectedItem => _selectedItem;
  String? get text => _text;
}
