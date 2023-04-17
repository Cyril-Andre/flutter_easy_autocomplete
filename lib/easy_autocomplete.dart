// Copyright 2021 4inka

// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.

// 2. Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.

// 3. Neither the name of the copyright holder nor the names of its contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

library easy_autocomplete;

import 'dart:async';

import 'package:easy_autocomplete/widgets/filterable_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/suggestion_controller.dart';

class EasyAutocomplete<T> extends StatefulWidget {
  /// The list of suggestions to be displayed
  final List<T>? suggestions;

  /// If true, only suggestions starting with the types characters will be displayed, otherwise all suggestions containing the charaacters are displayed
  final bool suggestionsStartWith;

  /// Fetches list of suggestions from a Future
  final Future<List<T>> Function(String searchValue)? asyncSuggestions;

  /// Text editing controller
  final SuggestionController<T>? controller;

  /// Can be used to decorate the input
  final InputDecoration decoration;

  /// Function that handles the changes to the input
  //final Function(String)? onChanged;

  /// Function that handles the submission of the input
  final Function(T?)? onChangeSelection;

  /// Can be used to set custom inputFormatters to field
  final List<TextInputFormatter> inputFormatter;

  /// Can be used to set the textfield initial value
  final T? initialValue;

  /// Can be used to set the text capitalization type
  final TextCapitalization textCapitalization;

  /// Determines if should gain focus on screen open
  final bool autofocus;

  /// Can be used to set different keyboardTypes to your field
  final TextInputType keyboardType;

  /// Can be used to manage TextField focus
  final FocusNode? focusNode;

  /// Can be used to set a custom color to the input cursor
  final Color? cursorColor;

  /// Can be used to set custom style to the suggestions textfield
  final TextStyle inputTextStyle;

  /// Can be used to set custom style to the suggestions list text
  final TextStyle suggestionTextStyle;

  /// Can be used to set custom background color to suggestions list
  final Color? suggestionBackgroundColor;

  /// Used to set the debounce time for async data fetch
  final Duration debounceDuration;

  /// Can be used to customize suggestion items
  final Widget Function(T data)? suggestionBuilder;

  /// Can be used to display custom progress idnicator
  final Widget? progressIndicatorBuilder;

  /// Can be used to validate field value
  final String? Function(T?)? validator;

  final String Function(T?) itemAsString;

  final bool Function(T?, T?) compareFn;

  /// Creates a autocomplete widget to help you manage your suggestions
  const EasyAutocomplete(
      {this.suggestions,
      this.suggestionsStartWith = false,
      this.asyncSuggestions,
      this.suggestionBuilder,
      this.progressIndicatorBuilder,
      this.controller,
      this.decoration = const InputDecoration(),
      this.onChangeSelection,
      this.inputFormatter = const [],
      this.initialValue,
      this.autofocus = false,
      this.textCapitalization = TextCapitalization.sentences,
      this.keyboardType = TextInputType.text,
      this.focusNode,
      this.cursorColor,
      this.inputTextStyle = const TextStyle(),
      this.suggestionTextStyle = const TextStyle(),
      this.suggestionBackgroundColor,
      this.debounceDuration = const Duration(milliseconds: 400),
      this.validator,
      required this.itemAsString,
      required this.compareFn})
      : //assert(onChanged != null || controller != null, 'onChanged and controller parameters cannot be both null at the same time'),
        assert(!(controller != null && initialValue != null), 'controller and initialValue cannot be used at the same time'),
        assert(suggestions != null && asyncSuggestions == null || suggestions == null && asyncSuggestions != null,
            'suggestions and asyncSuggestions cannot be both null or have values at the same time');

  @override
  State<EasyAutocomplete<T>> createState() => _EasyAutocompleteState<T>();
}

class _EasyAutocompleteState<T> extends State<EasyAutocomplete<T>> {
  final LayerLink _layerLink = LayerLink();
  late TextEditingController _textFieldController;
  T? selectedItem;
  bool _hasOpenedOverlay = false;
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  List<T> _suggestions = [];
  Timer? _debounce;
  String _previousAsyncSearchText = '';
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      selectedItem = widget.initialValue;
    } else if (widget.controller != null) {
      selectedItem = widget.controller!.selectedItem;
    }
    _focusNode = widget.focusNode ?? FocusNode();
    _textFieldController = TextEditingController(text: widget.itemAsString(selectedItem));
    _textFieldController.addListener(() => updateSuggestions(_textFieldController.text));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus)
        openOverlay();
      // Workaround for Web to prevent overlay close before item could be tapped
      else if (kIsWeb)
        Future.delayed(const Duration(milliseconds: 150)).then((_) {
          closeOverlay();
        });
      else {
        closeOverlay();
      }
    });
  }

  void verifySelection() {
    if (selectedItem == null) {
      _textFieldController.text = '';
    } else {
      _textFieldController.text = widget.itemAsString(selectedItem);
    }
  }

  void openOverlay() {
    if (_overlayEntry == null) {
      RenderBox renderBox = context.findRenderObject() as RenderBox;
      var size = renderBox.size;
      var offset = renderBox.localToGlobal(Offset.zero);

      _overlayEntry ??= OverlayEntry(
          builder: (context) => Positioned(
              left: offset.dx,
              top: offset.dy + size.height + 5.0,
              width: size.width,
              child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0.0, size.height + 5.0),
                  child: FilterableList<T>(
                      searchString: _textFieldController.text,
                      loading: _isLoading,
                      suggestionBuilder: widget.suggestionBuilder,
                      progressIndicatorBuilder: widget.progressIndicatorBuilder,
                      items: _suggestions,
                      itemAsString: widget.itemAsString,
                      suggestionTextStyle: widget.suggestionTextStyle,
                      suggestionBackgroundColor: widget.suggestionBackgroundColor,
                      onItemTapped: (value) {
                        var _text = widget.itemAsString(value);
                        _textFieldController..value = TextEditingValue(text: _text, selection: TextSelection.collapsed(offset: _text.length));
                        widget.onChangeSelection?.call(value);
                        selectedItem = value;
                        if (widget.controller != null) {
                          widget.controller!.onChangeSelection(value);
                        }
                        closeOverlay();
                        _focusNode.unfocus();
                      }))));
    }
    if (!_hasOpenedOverlay) {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _hasOpenedOverlay = true);
    }
  }

  void closeOverlay() {
    if (_hasOpenedOverlay) {
      _overlayEntry!.remove();
      _hasOpenedOverlay = false;
      setState(() {
        //_previousAsyncSearchText = '';
        _hasOpenedOverlay = false;
//    verifySelection();
      });
    }
  }

  Future<void> updateSuggestions(String input) async {
    rebuildOverlay();
    if (widget.suggestions != null) {
      _suggestions = widget.suggestions!.where((element) {
        if (widget.suggestionsStartWith) {
          return widget.itemAsString(element).toLowerCase().startsWith(input.toLowerCase());
        } else {
          return widget.itemAsString(element).toLowerCase().contains(input.toLowerCase());
        }
      }).toList();
      rebuildOverlay();
    } else if (widget.asyncSuggestions != null) {
      if (_previousAsyncSearchText == input && input.isNotEmpty) return;

      if (_debounce != null && _debounce!.isActive) _debounce!.cancel();

      setState(() {
        _isLoading = true;
        _previousAsyncSearchText = input;
      });

      _debounce = Timer(widget.debounceDuration, () async {
        _suggestions = await widget.asyncSuggestions!(input);
        setState(() => _isLoading = false);
        rebuildOverlay();
      });
    }
  }

  void rebuildOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextFormField(
              textInputAction: TextInputAction.next,
              decoration: widget.decoration,
              controller: _textFieldController,
              inputFormatters: widget.inputFormatter,
              autofocus: widget.autofocus,
              focusNode: _focusNode,
              textCapitalization: widget.textCapitalization,
              keyboardType: widget.keyboardType,
              cursorColor: widget.cursorColor ?? Colors.blue,
              style: widget.inputTextStyle,
              onChanged: (value) {
                if (value == '') {
                  selectedItem = null;
                  if (widget.controller != null && widget.controller!.selectedItem != null) {
                    widget.controller!.onChangeSelection.call(null);
                  }
                  //widget.onChangeSelection?.call(selectedItem);
                }
                setState(() {
                  if (!_hasOpenedOverlay) {
                    openOverlay();
                  }
                });
              },
              onFieldSubmitted: (value) {
                String typedString = _textFieldController.text;
                Iterable<T> selected;
                if (widget.suggestionsStartWith) {
                  selected = (_suggestions.where((element) => widget.itemAsString(element).toLowerCase().startsWith(typedString.toLowerCase())));
                } else {
                  selected = (_suggestions.where((element) => widget.itemAsString(element).toLowerCase().contains(typedString.toLowerCase())));
                }
                if (selected.isEmpty) {
                  selectedItem = null;
                } else {
                  selectedItem = selected.first;
                }

                _textFieldController.text = widget.itemAsString(selectedItem);
                _textFieldController.selection = TextSelection.fromPosition(TextPosition(offset: _textFieldController.text.length));
                closeOverlay();
                _focusNode.nextFocus();

                widget.onChangeSelection?.call(selectedItem);
                if (widget.controller != null) {
                  widget.controller!.onChangeSelection(selectedItem);
                }

              },
              onEditingComplete: () => closeOverlay(),
              validator: widget.validator != null ? (value) => widget.validator!(selectedItem) : null // (value) {}
              )
        ]));
  }

  @override
  void dispose() {
    if (_overlayEntry != null) {
      _overlayEntry!.dispose();
    }
    /*
    if (widget.controller == null) {
    */
    _textFieldController.removeListener(() => updateSuggestions(_textFieldController.text));
    _textFieldController.dispose();
    /*
    }
    */
    if (_debounce != null) _debounce?.cancel();
    if (widget.focusNode == null) {
      _focusNode.removeListener(() {
        if (_focusNode.hasFocus)
          openOverlay();
        // Workaround for Web to prevent overlay close before item could be tapped
        else if (kIsWeb)
          Future.delayed(const Duration(milliseconds: 150)).then((_) {
            closeOverlay();
          });
        else
          closeOverlay();
      });
      _focusNode.dispose();
    }
    super.dispose();
  }
}
