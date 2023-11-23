import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const Duration _kDropdownMenuDuration = Duration(milliseconds: 300);
const double _kMenuItemHeight = kMinInteractiveDimension;
const double _kDenseButtonHeight = 24.0;
const EdgeInsets _kMenuItemPadding = EdgeInsets.symmetric(horizontal: 16.0);
const EdgeInsetsGeometry _kAlignedButtonPadding =
    EdgeInsetsDirectional.only(start: 16.0, end: 4.0);
const EdgeInsets _kUnalignedButtonPadding = EdgeInsets.zero;
const EdgeInsets _kAlignedMenuMargin = EdgeInsets.zero;
const EdgeInsetsGeometry _kUnalignedMenuMargin =
    EdgeInsetsDirectional.only(start: 16.0, end: 24.0);

typedef DropdownButtonBuilder = List<Widget> Function(BuildContext context);

class _DropdownMenuPainter extends CustomPainter {
  _DropdownMenuPainter({
    this.color,
    this.elevation,
    this.selectedIndex,
    this.borderRadius,
    required this.resize,
    required this.getSelectedItemOffset,
  })  : _painter = BoxDecoration(
          color: color,
          borderRadius:
              borderRadius ?? const BorderRadius.all(Radius.circular(2.0)),
          boxShadow: kElevationToShadow[elevation],
        ).createBoxPainter(),
        super(repaint: resize);

  final Color? color;
  final int? elevation;
  final int? selectedIndex;
  final BorderRadius? borderRadius;
  final Animation<double> resize;
  final ValueGetter<double> getSelectedItemOffset;
  final BoxPainter _painter;

  @override
  void paint(Canvas canvas, Size size) {
    // final double selectedItemOffset = getSelectedItemOffset();
    // final Tween<double> top = Tween<double>(
    //   begin: clampDouble(selectedItemOffset, 0.0,
    //       math.max(size.height - _kMenuItemHeight, 0.0)),
    //   end: 0.0,
    // );

    // final Tween<double> bottom = Tween<double>(
    //   begin: clampDouble(top.begin! + _kMenuItemHeight,
    //       math.min(_kMenuItemHeight, size.height), size.height),
    //   end: size.height,
    // );
    const Rect rect = Rect.fromLTRB(
      7,
      7.11,
      164,
      136 + 15,
    );

    _painter.paint(
      canvas,
      rect.topLeft,
      ImageConfiguration(size: rect.size),
    );
  }

  @override
  bool shouldRepaint(_DropdownMenuPainter oldPainter) {
    return oldPainter.color != color ||
        oldPainter.elevation != elevation ||
        oldPainter.selectedIndex != selectedIndex ||
        oldPainter.borderRadius != borderRadius ||
        oldPainter.resize != resize;
  }
}

class _DropdownMenuItemButton<T> extends StatefulWidget {
  const _DropdownMenuItemButton({
    super.key,
    this.padding,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    required this.itemIndex,
    required this.enableFeedback,
  });

  final _DropdownRoute<T> route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final int itemIndex;
  final bool enableFeedback;

  @override
  _DropdownMenuItemButtonState<T> createState() =>
      _DropdownMenuItemButtonState<T>();
}

class _DropdownMenuItemButtonState<T>
    extends State<_DropdownMenuItemButton<T>> {
  void _handleFocusChange(bool focused) {
    final bool inTraditionalMode;
    switch (FocusManager.instance.highlightMode) {
      case FocusHighlightMode.touch:
        inTraditionalMode = false;
      case FocusHighlightMode.traditional:
        inTraditionalMode = true;
    }

    if (focused && inTraditionalMode) {
      final _MenuLimits menuLimits = widget.route.getMenuLimits(
        widget.buttonRect,
        widget.constraints.maxHeight,
        widget.itemIndex,
      );
      widget.route.scrollController!.animateTo(
        menuLimits.scrollOffset,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 100),
      );
    }
  }

  void _handleOnTap() {
    final CustomDropdownMenuItem<T> dropdownMenuItem =
        widget.route.items[widget.itemIndex].item!;

    dropdownMenuItem.onTap?.call();

    Navigator.pop(
      context,
      _DropdownRouteResult<T>(dropdownMenuItem.value),
    );
  }

  static const Map<ShortcutActivator, Intent> _webShortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowDown):
        DirectionalFocusIntent(TraversalDirection.down),
    SingleActivator(LogicalKeyboardKey.arrowUp):
        DirectionalFocusIntent(TraversalDirection.up),
  };

  @override
  Widget build(BuildContext context) {
    final CustomDropdownMenuItem<T> dropdownMenuItem =
        widget.route.items[widget.itemIndex].item!;
    final CurvedAnimation opacity;
    final double unit = 0.5 / (widget.route.items.length + 1.5);
    if (widget.itemIndex == widget.route.selectedIndex) {
      opacity = CurvedAnimation(
          parent: widget.route.animation!, curve: const Threshold(0.0));
    } else {
      final double start =
          clampDouble(0.5 + (widget.itemIndex + 1) * unit, 0.0, 1.0);
      final double end = clampDouble(start + 1.5 * unit, 0.0, 1.0);
      opacity = CurvedAnimation(
          parent: widget.route.animation!, curve: Interval(start, end));
    }
    Widget child = Container(
      padding: widget.padding,
      height: widget.route.itemHeight,
      child: widget.route.items[widget.itemIndex],
    );
    if (dropdownMenuItem.enabled) {
      child = InkWell(
        autofocus: widget.itemIndex == widget.route.selectedIndex,
        enableFeedback: widget.enableFeedback,
        onTap: _handleOnTap,
        onFocusChange: _handleFocusChange,
        child: child,
      );
    }
    child = FadeTransition(opacity: opacity, child: child);
    if (kIsWeb && dropdownMenuItem.enabled) {
      child = Shortcuts(
        shortcuts: _webShortcuts,
        child: child,
      );
    }
    return child;
  }
}

class _DropdownMenu<T> extends StatefulWidget {
  const _DropdownMenu({
    super.key,
    this.padding,
    required this.route,
    required this.buttonRect,
    required this.constraints,
    this.dropdownColor,
    required this.enableFeedback,
    this.borderRadius,
  });

  final _DropdownRoute<T> route;
  final EdgeInsets? padding;
  final Rect buttonRect;
  final BoxConstraints constraints;
  final Color? dropdownColor;
  final bool enableFeedback;
  final BorderRadius? borderRadius;

  @override
  _DropdownMenuState<T> createState() => _DropdownMenuState<T>();
}

class _DropdownMenuState<T> extends State<_DropdownMenu<T>> {
  late CurvedAnimation _fadeOpacity;
  late CurvedAnimation _resize;

  @override
  void initState() {
    super.initState();
    _fadeOpacity = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.0, 0.25),
      reverseCurve: const Interval(0.75, 1.0),
    );
    _resize = CurvedAnimation(
      parent: widget.route.animation!,
      curve: const Interval(0.25, 0.5),
      reverseCurve: const Threshold(0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final _DropdownRoute<T> route = widget.route;
    final List<Widget> children = <Widget>[
      for (int itemIndex = 0; itemIndex < route.items.length; ++itemIndex)
        _DropdownMenuItemButton<T>(
          route: widget.route,
          padding: widget.padding,
          buttonRect: widget.buttonRect,
          constraints: widget.constraints,
          itemIndex: itemIndex,
          enableFeedback: widget.enableFeedback,
        ),
    ];

    return FadeTransition(
      opacity: _fadeOpacity,
      child: CustomPaint(
        painter: _DropdownMenuPainter(
          color: widget.dropdownColor ?? Theme.of(context).canvasColor,
          elevation: route.elevation,
          selectedIndex: route.selectedIndex,
          resize: _resize,
          borderRadius: widget.borderRadius,
          getSelectedItemOffset: () => route.getItemOffset(route.selectedIndex),
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: localizations.popupMenuLabel,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            clipBehavior:
                widget.borderRadius != null ? Clip.antiAlias : Clip.none,
            child: Material(
              type: MaterialType.transparency,
              textStyle: route.style,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                  overscroll: false,
                  physics: const ClampingScrollPhysics(),
                  platform: Theme.of(context).platform,
                ),
                child: PrimaryScrollController(
                  controller: widget.route.scrollController!,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView(
                      primary: true,
                      padding: kMaterialListPadding,
                      shrinkWrap: true,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuRouteLayout<T> extends SingleChildLayoutDelegate {
  _DropdownMenuRouteLayout({
    required this.buttonRect,
    required this.route,
    required this.textDirection,
  });

  final Rect buttonRect;
  final _DropdownRoute<T> route;
  final TextDirection? textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight =
        math.max(0.0, constraints.maxHeight - 2 * _kMenuItemHeight);
    if (route.menuMaxHeight != null && route.menuMaxHeight! <= maxHeight) {
      maxHeight = route.menuMaxHeight!;
    }

    final double width = math.min(constraints.maxWidth, buttonRect.width);
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final _MenuLimits menuLimits =
        route.getMenuLimits(buttonRect, size.height, route.selectedIndex);

    assert(() {
      final Rect container = Offset.zero & size;
      if (container.intersect(buttonRect) == buttonRect) {
        assert(menuLimits.top >= 0.0);
        assert(menuLimits.top + menuLimits.height <= size.height);
      }
      return true;
    }());
    assert(textDirection != null);
    final double left;
    switch (textDirection!) {
      case TextDirection.rtl:
        left = clampDouble(buttonRect.right, 0.0, size.width) - childSize.width;
      case TextDirection.ltr:
        left = clampDouble(buttonRect.left, 0.0, size.width - childSize.width);
    }

    return Offset(left, menuLimits.top);
  }

  @override
  bool shouldRelayout(_DropdownMenuRouteLayout<T> oldDelegate) {
    return buttonRect != oldDelegate.buttonRect ||
        textDirection != oldDelegate.textDirection;
  }
}

@immutable
class _DropdownRouteResult<T> {
  const _DropdownRouteResult(this.result);

  final T? result;

  @override
  bool operator ==(Object other) {
    return other is _DropdownRouteResult<T> && other.result == result;
  }

  @override
  int get hashCode => result.hashCode;
}

class _MenuLimits {
  const _MenuLimits(this.top, this.bottom, this.height, this.scrollOffset);
  final double top;
  final double bottom;
  final double height;
  final double scrollOffset;
}

class _DropdownRoute<T> extends PopupRoute<_DropdownRouteResult<T>> {
  _DropdownRoute({
    required this.items,
    required this.padding,
    required this.buttonRect,
    required this.selectedIndex,
    this.elevation = 8,
    required this.capturedThemes,
    required this.style,
    this.barrierLabel,
    this.itemHeight,
    this.dropdownColor,
    this.menuMaxHeight,
    required this.enableFeedback,
    this.borderRadius,
  }) : itemHeights = List<double>.filled(
            items.length, itemHeight ?? kMinInteractiveDimension);

  final List<_MenuItem<T>> items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final int selectedIndex;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle style;
  final double? itemHeight;
  final Color? dropdownColor;
  final double? menuMaxHeight;
  final bool enableFeedback;
  final BorderRadius? borderRadius;

  final List<double> itemHeights;
  ScrollController? scrollController;

  @override
  Duration get transitionDuration => _kDropdownMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  @override
  final String? barrierLabel;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return _DropdownRoutePage<T>(
          route: this,
          constraints: constraints,
          items: items,
          padding: padding,
          buttonRect: buttonRect,
          selectedIndex: selectedIndex,
          elevation: elevation,
          capturedThemes: capturedThemes,
          style: style,
          dropdownColor: dropdownColor,
          enableFeedback: enableFeedback,
          borderRadius: borderRadius,
        );
      },
    );
  }

  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }

  double getItemOffset(int index) {
    double offset = kMaterialListPadding.top;
    if (items.isNotEmpty && index > 0) {
      assert(items.length == itemHeights.length);
      offset += itemHeights
          .sublist(0, index)
          .reduce((double total, double height) => total + height);
    }
    return offset;
  }

  _MenuLimits getMenuLimits(
      Rect buttonRect, double availableHeight, int index) {
    double computedMaxHeight = availableHeight - 2.0 * _kMenuItemHeight;
    if (menuMaxHeight != null) {
      computedMaxHeight = math.min(computedMaxHeight, menuMaxHeight!);
    }
    final double buttonTop = buttonRect.top;
    final double buttonBottom = math.min(buttonRect.bottom, availableHeight);
    final double selectedItemOffset = getItemOffset(index);
    final double topLimit = math.min(_kMenuItemHeight, buttonTop);
    final double bottomLimit =
        math.max(availableHeight - _kMenuItemHeight, buttonBottom);

    double menuTop = (buttonTop - selectedItemOffset) -
        (itemHeights[selectedIndex] - buttonRect.height) / 2.0;
    double preferredMenuHeight = kMaterialListPadding.vertical;
    if (items.isNotEmpty) {
      preferredMenuHeight +=
          itemHeights.reduce((double total, double height) => total + height);
    }

    final double menuHeight = math.min(computedMaxHeight, preferredMenuHeight);
    double menuBottom = menuTop + menuHeight;

    if (menuTop < topLimit) {
      menuTop = math.min(buttonTop, topLimit);
      menuBottom = menuTop + menuHeight;
    }

    if (menuBottom > bottomLimit) {
      menuBottom = math.max(buttonBottom, bottomLimit);
      menuTop = menuBottom - menuHeight;
    }

    if (menuBottom - itemHeights[selectedIndex] / 2.0 <
        buttonBottom - buttonRect.height / 2.0) {
      menuBottom = buttonBottom -
          buttonRect.height / 2.0 +
          itemHeights[selectedIndex] / 2.0;
      menuTop = menuBottom - menuHeight;
    }

    double scrollOffset = 0;

    if (preferredMenuHeight > computedMaxHeight) {
      scrollOffset = math.max(0.0, selectedItemOffset - (buttonTop - menuTop));
      scrollOffset = math.min(scrollOffset, preferredMenuHeight - menuHeight);
    }

    assert((menuBottom - menuTop - menuHeight).abs() < precisionErrorTolerance);
    return _MenuLimits(menuTop, menuBottom, menuHeight, scrollOffset);
  }
}

class _DropdownRoutePage<T> extends StatelessWidget {
  const _DropdownRoutePage({
    super.key,
    required this.route,
    required this.constraints,
    this.items,
    required this.padding,
    required this.buttonRect,
    required this.selectedIndex,
    this.elevation = 8,
    required this.capturedThemes,
    this.style,
    required this.dropdownColor,
    required this.enableFeedback,
    this.borderRadius,
  });

  final _DropdownRoute<T> route;
  final BoxConstraints constraints;
  final List<_MenuItem<T>>? items;
  final EdgeInsetsGeometry padding;
  final Rect buttonRect;
  final int selectedIndex;
  final int elevation;
  final CapturedThemes capturedThemes;
  final TextStyle? style;
  final Color? dropdownColor;
  final bool enableFeedback;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));

    if (route.scrollController == null) {
      final _MenuLimits menuLimits =
          route.getMenuLimits(buttonRect, constraints.maxHeight, selectedIndex);
      route.scrollController =
          ScrollController(initialScrollOffset: menuLimits.scrollOffset);
    }

    final TextDirection? textDirection = Directionality.maybeOf(context);
    final Widget menu = _DropdownMenu<T>(
      route: route,
      padding: padding.resolve(textDirection),
      buttonRect: buttonRect,
      constraints: constraints,
      dropdownColor: dropdownColor,
      enableFeedback: enableFeedback,
      borderRadius: borderRadius,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (BuildContext context) {
          return CustomSingleChildLayout(
            delegate: _DropdownMenuRouteLayout<T>(
              buttonRect: buttonRect,
              route: route,
              textDirection: textDirection,
            ),
            child: capturedThemes.wrap(menu),
          );
        },
      ),
    );
  }
}

class _MenuItem<T> extends SingleChildRenderObjectWidget {
  const _MenuItem({
    super.key,
    required this.onLayout,
    required this.item,
  }) : super(child: item);

  final ValueChanged<Size> onLayout;
  final CustomDropdownMenuItem<T>? item;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMenuItem(onLayout);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMenuItem renderObject) {
    renderObject.onLayout = onLayout;
  }
}

class _RenderMenuItem extends RenderProxyBox {
  _RenderMenuItem(this.onLayout, [RenderBox? child]) : super(child);

  ValueChanged<Size> onLayout;

  @override
  void performLayout() {
    super.performLayout();
    onLayout(size);
  }
}

class _DropdownMenuItemContainer extends StatelessWidget {
  const _DropdownMenuItemContainer({
    super.key,
    this.alignment = AlignmentDirectional.centerStart,
    required this.child,
  });

  final Widget child;

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _kMenuItemHeight),
      alignment: alignment,
      child: child,
    );
  }
}

class CustomDropdownMenuItem<T> extends _DropdownMenuItemContainer {
  const CustomDropdownMenuItem({
    super.key,
    this.onTap,
    this.value,
    this.enabled = true,
    super.alignment,
    required super.child,
  });

  final VoidCallback? onTap;

  final T? value;

  final bool enabled;
}

class DropdownButtonHideUnderline extends InheritedWidget {
  const DropdownButtonHideUnderline({
    super.key,
    required super.child,
  });

  static bool at(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
            DropdownButtonHideUnderline>() !=
        null;
  }

  @override
  bool updateShouldNotify(DropdownButtonHideUnderline oldWidget) => false;
}

class CustomDropdownButton<T> extends StatefulWidget {
  CustomDropdownButton({
    required this.onChanged,
    required this.list,
    super.key,
    this.selectedItemBuilder,
    this.selectedValue,
    this.hint,
    this.disabledHint,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight = kMinInteractiveDimension,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
  })  : assert(
          list == null ||
              list.isEmpty ||
              selectedValue == null ||
              list.where((CustomDropdownMenuItem<T> item) {
                    return item.value == selectedValue;
                  }).length ==
                  1,
        ),
        assert(itemHeight == null || itemHeight >= kMinInteractiveDimension),
        _inputDecoration = null,
        _isEmpty = false,
        _isFocused = false;

  CustomDropdownButton._formField({
    super.key,
    required this.list,
    this.selectedItemBuilder,
    this.selectedValue,
    this.hint,
    this.disabledHint,
    required this.onChanged,
    this.onTap,
    this.elevation = 8,
    this.style,
    this.underline,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.isDense = false,
    this.isExpanded = false,
    this.itemHeight = kMinInteractiveDimension,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
    this.borderRadius,
    this.padding,
    required InputDecoration inputDecoration,
    required bool isEmpty,
    required bool isFocused,
  })  : assert(
          list == null ||
              list.isEmpty ||
              selectedValue == null ||
              list.where((CustomDropdownMenuItem<T> item) {
                    return item.value == selectedValue;
                  }).length ==
                  1,
        ),
        assert(itemHeight == null || itemHeight >= kMinInteractiveDimension),
        _inputDecoration = inputDecoration,
        _isEmpty = isEmpty,
        _isFocused = isFocused;

  final List<CustomDropdownMenuItem<T>>? list;

  final T? selectedValue;

  final Widget? hint;

  final Widget? disabledHint;

  final ValueChanged<T?>? onChanged;

  final VoidCallback? onTap;

  final DropdownButtonBuilder? selectedItemBuilder;

  final int elevation;

  final TextStyle? style;

  final Widget? underline;

  final Widget? icon;

  final Color? iconDisabledColor;

  final Color? iconEnabledColor;

  final double iconSize;

  final bool isDense;

  final bool isExpanded;

  final double? itemHeight;

  final Color? focusColor;

  final FocusNode? focusNode;

  final bool autofocus;

  final Color? dropdownColor;

  final EdgeInsetsGeometry? padding;

  final double? menuMaxHeight;

  final bool? enableFeedback;

  final AlignmentGeometry alignment;

  final BorderRadius? borderRadius;

  final InputDecoration? _inputDecoration;

  final bool _isEmpty;

  final bool _isFocused;

  @override
  State<CustomDropdownButton<T>> createState() =>
      _CustomDropdownButtonState<T>();
}

class _CustomDropdownButtonState<T> extends State<CustomDropdownButton<T>>
    with WidgetsBindingObserver {
  int? _selectedIndex;
  _DropdownRoute<T>? _dropdownRoute;
  Orientation? _lastOrientation;
  FocusNode? _internalNode;
  FocusNode? get focusNode => widget.focusNode ?? _internalNode;
  late Map<Type, Action<Intent>> _actionMap;

  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) => _handleTap(),
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) => _handleTap(),
      ),
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeDropdownRoute();
    _internalNode?.dispose();
    super.dispose();
  }

  void _removeDropdownRoute() {
    _dropdownRoute?._dismiss();
    _dropdownRoute = null;
    _lastOrientation = null;
  }

  @override
  void didUpdateWidget(CustomDropdownButton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    if (widget.list == null ||
        widget.list!.isEmpty ||
        (widget.selectedValue == null &&
            widget.list!
                .where((CustomDropdownMenuItem<T> item) =>
                    item.enabled && item.value == widget.selectedValue)
                .isEmpty)) {
      _selectedIndex = null;
      return;
    }

    assert(widget.list!
            .where((CustomDropdownMenuItem<T> item) =>
                item.value == widget.selectedValue)
            .length ==
        1);
    for (int itemIndex = 0; itemIndex < widget.list!.length; itemIndex++) {
      if (widget.list![itemIndex].value == widget.selectedValue) {
        _selectedIndex = itemIndex;
        return;
      }
    }
  }

  TextStyle? get _textStyle =>
      widget.style ?? Theme.of(context).textTheme.titleMedium;

  void _handleTap() {
    final TextDirection? textDirection = Directionality.maybeOf(context);
    final EdgeInsetsGeometry menuMargin =
        ButtonTheme.of(context).alignedDropdown
            ? _kAlignedMenuMargin
            : _kUnalignedMenuMargin;

    final List<_MenuItem<T>> menuItems = <_MenuItem<T>>[
      for (int index = 0; index < widget.list!.length; index += 1)
        _MenuItem<T>(
          item: widget.list![index],
          onLayout: (Size size) {
            if (_dropdownRoute == null) {
              return;
            }

            _dropdownRoute!.itemHeights[index] = size.height;
          },
        ),
    ];

    final NavigatorState navigator = Navigator.of(context);
    assert(_dropdownRoute == null);
    final RenderBox itemBox = context.findRenderObject()! as RenderBox;
    final Rect itemRect = itemBox.localToGlobal(Offset.zero,
            ancestor: navigator.context.findRenderObject()) &
        itemBox.size;
    _dropdownRoute = _DropdownRoute<T>(
      items: menuItems,
      buttonRect: menuMargin.resolve(textDirection).inflateRect(itemRect),
      padding: _kMenuItemPadding.resolve(textDirection),
      selectedIndex: _selectedIndex ?? 0,
      elevation: widget.elevation,
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      style: _textStyle!,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      itemHeight: widget.itemHeight,
      dropdownColor: widget.dropdownColor,
      menuMaxHeight: widget.menuMaxHeight,
      enableFeedback: widget.enableFeedback ?? true,
      borderRadius: widget.borderRadius,
    );

    focusNode?.requestFocus();
    navigator
        .push(_dropdownRoute!)
        .then<void>((_DropdownRouteResult<T>? newValue) {
      _removeDropdownRoute();
      if (!mounted || newValue == null) {
        return;
      }
      widget.onChanged?.call(newValue.result);
    });

    widget.onTap?.call();
  }

  double get _denseButtonHeight {
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    final double fontSize = _textStyle!.fontSize ??
        Theme.of(context).textTheme.titleMedium!.fontSize!;
    final double scaledFontSize = textScaleFactor * fontSize;
    return math.max(
        scaledFontSize, math.max(widget.iconSize, _kDenseButtonHeight));
  }

  Color get _iconColor {
    if (_enabled) {
      if (widget.iconEnabledColor != null) {
        return widget.iconEnabledColor!;
      }

      switch (Theme.of(context).brightness) {
        case Brightness.light:
          return Colors.grey.shade700;
        case Brightness.dark:
          return Colors.white70;
      }
    } else {
      if (widget.iconDisabledColor != null) {
        return widget.iconDisabledColor!;
      }

      switch (Theme.of(context).brightness) {
        case Brightness.light:
          return Colors.grey.shade400;
        case Brightness.dark:
          return Colors.white10;
      }
    }
  }

  bool get _enabled =>
      widget.list != null &&
      widget.list!.isNotEmpty &&
      widget.onChanged != null;

  Orientation _getOrientation(BuildContext context) {
    Orientation? result = MediaQuery.maybeOrientationOf(context);
    if (result == null) {
      final Size size = View.of(context).physicalSize;
      result = size.width > size.height
          ? Orientation.landscape
          : Orientation.portrait;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final Orientation newOrientation = _getOrientation(context);
    _lastOrientation ??= newOrientation;
    if (newOrientation != _lastOrientation) {
      _removeDropdownRoute();
      _lastOrientation = newOrientation;
    }

    final List<Widget> items = widget.selectedItemBuilder == null
        ? (widget.list != null ? List<Widget>.of(widget.list!) : <Widget>[])
        : List<Widget>.of(widget.selectedItemBuilder!(context));

    int? hintIndex;
    if (widget.hint != null || (!_enabled && widget.disabledHint != null)) {
      final Widget displayedHint =
          _enabled ? widget.hint! : widget.disabledHint ?? widget.hint!;

      hintIndex = items.length;
      items.add(DefaultTextStyle(
        style: _textStyle!.copyWith(color: Theme.of(context).hintColor),
        child: IgnorePointer(
          child: _DropdownMenuItemContainer(
            alignment: widget.alignment,
            child: displayedHint,
          ),
        ),
      ));
    }

    final EdgeInsetsGeometry padding = ButtonTheme.of(context).alignedDropdown
        ? _kAlignedButtonPadding
        : _kUnalignedButtonPadding;

    final Widget innerItemsWidget;
    if (items.isEmpty) {
      innerItemsWidget = const SizedBox.shrink();
    } else {
      innerItemsWidget = IndexedStack(
        index: _selectedIndex ?? hintIndex,
        alignment: widget.alignment,
        children: widget.isDense
            ? items
            : items.map((Widget item) {
                return widget.itemHeight != null
                    ? SizedBox(height: widget.itemHeight, child: item)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[item]);
              }).toList(),
      );
    }

    const Icon defaultIcon = Icon(Icons.arrow_drop_down);

    Widget result = DefaultTextStyle(
      style: _enabled
          ? _textStyle!
          : _textStyle!.copyWith(color: Theme.of(context).disabledColor),
      child: Container(
        padding: padding.resolve(Directionality.of(context)),
        height: widget.isDense ? _denseButtonHeight : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.isExpanded)
              Expanded(child: innerItemsWidget)
            else
              innerItemsWidget,
            IconTheme(
              data: IconThemeData(
                color: _iconColor,
                size: widget.iconSize,
              ),
              child: widget.icon ?? defaultIcon,
            ),
          ],
        ),
      ),
    );

    if (!DropdownButtonHideUnderline.at(context)) {
      final double bottom =
          (widget.isDense || widget.itemHeight == null) ? 0.0 : 8.0;
      result = Stack(
        children: <Widget>[
          result,
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: bottom,
            child: widget.underline ??
                Container(
                  height: 1.0,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFBDBDBD),
                        width: 0.0,
                      ),
                    ),
                  ),
                ),
          ),
        ],
      );
    }

    final MouseCursor effectiveMouseCursor =
        MaterialStateProperty.resolveAs<MouseCursor>(
      MaterialStateMouseCursor.clickable,
      <MaterialState>{
        if (!_enabled) MaterialState.disabled,
      },
    );

    if (widget._inputDecoration != null) {
      result = InputDecorator(
        decoration: widget._inputDecoration!,
        isEmpty: widget._isEmpty,
        isFocused: widget._isFocused,
        child: result,
      );
    }

    return Semantics(
      button: true,
      child: Actions(
        actions: _actionMap,
        child: InkWell(
          mouseCursor: effectiveMouseCursor,
          onTap: _enabled ? _handleTap : null,
          canRequestFocus: _enabled,
          borderRadius: widget.borderRadius,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          focusColor: widget.focusColor ?? Theme.of(context).focusColor,
          enableFeedback: false,
          child: widget.padding == null
              ? result
              : Padding(padding: widget.padding!, child: result),
        ),
      ),
    );
  }
}

class DropdownButtonFormField<T> extends FormField<T> {
  DropdownButtonFormField({
    super.key,
    required List<CustomDropdownMenuItem<T>>? items,
    DropdownButtonBuilder? selectedItemBuilder,
    T? value,
    Widget? hint,
    Widget? disabledHint,
    required this.onChanged,
    VoidCallback? onTap,
    int elevation = 8,
    TextStyle? style,
    Widget? icon,
    Color? iconDisabledColor,
    Color? iconEnabledColor,
    double iconSize = 24.0,
    bool isDense = true,
    bool isExpanded = false,
    double? itemHeight,
    Color? focusColor,
    FocusNode? focusNode,
    bool autofocus = false,
    Color? dropdownColor,
    InputDecoration? decoration,
    super.onSaved,
    super.validator,
    AutovalidateMode? autovalidateMode,
    double? menuMaxHeight,
    bool? enableFeedback,
    AlignmentGeometry alignment = AlignmentDirectional.centerStart,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  })  : assert(
          items == null ||
              items.isEmpty ||
              value == null ||
              items.where((CustomDropdownMenuItem<T> item) {
                    return item.value == value;
                  }).length ==
                  1,
          "There should be exactly one item with [DropdownButton]'s value: "
          '$value. \n'
          'Either zero or 2 or more [DropdownMenuItem]s were detected '
          'with the same value',
        ),
        assert(itemHeight == null || itemHeight >= kMinInteractiveDimension),
        decoration = decoration ?? InputDecoration(focusColor: focusColor),
        super(
          initialValue: value,
          autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
          builder: (FormFieldState<T> field) {
            final _DropdownButtonFormFieldState<T> state =
                field as _DropdownButtonFormFieldState<T>;
            final InputDecoration decorationArg =
                decoration ?? InputDecoration(focusColor: focusColor);
            final InputDecoration effectiveDecoration =
                decorationArg.applyDefaults(
              Theme.of(field.context).inputDecorationTheme,
            );

            final bool showSelectedItem = items != null &&
                items
                    .where((CustomDropdownMenuItem<T> item) =>
                        item.value == state.value)
                    .isNotEmpty;
            bool isHintOrDisabledHintAvailable() {
              final bool isDropdownDisabled =
                  onChanged == null || (items == null || items.isEmpty);
              if (isDropdownDisabled) {
                return hint != null || disabledHint != null;
              } else {
                return hint != null;
              }
            }

            final bool isEmpty =
                !showSelectedItem && !isHintOrDisabledHintAvailable();

            return Focus(
              canRequestFocus: false,
              skipTraversal: true,
              child: Builder(builder: (BuildContext context) {
                return DropdownButtonHideUnderline(
                  child: CustomDropdownButton<T>._formField(
                    list: items,
                    selectedItemBuilder: selectedItemBuilder,
                    selectedValue: state.value,
                    hint: hint,
                    disabledHint: disabledHint,
                    onChanged: onChanged == null ? null : state.didChange,
                    onTap: onTap,
                    elevation: elevation,
                    style: style,
                    icon: icon,
                    iconDisabledColor: iconDisabledColor,
                    iconEnabledColor: iconEnabledColor,
                    iconSize: iconSize,
                    isDense: isDense,
                    isExpanded: isExpanded,
                    itemHeight: itemHeight,
                    focusColor: focusColor,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    dropdownColor: dropdownColor,
                    menuMaxHeight: menuMaxHeight,
                    enableFeedback: enableFeedback,
                    alignment: alignment,
                    borderRadius: borderRadius,
                    inputDecoration: effectiveDecoration.copyWith(
                        errorText: field.errorText),
                    isEmpty: isEmpty,
                    isFocused: Focus.of(context).hasFocus,
                    padding: padding,
                  ),
                );
              }),
            );
          },
        );

  final ValueChanged<T?>? onChanged;

  final InputDecoration decoration;

  @override
  FormFieldState<T> createState() => _DropdownButtonFormFieldState<T>();
}

class _DropdownButtonFormFieldState<T> extends FormFieldState<T> {
  @override
  void didChange(T? value) {
    super.didChange(value);
    final DropdownButtonFormField<T> dropdownButtonFormField =
        widget as DropdownButtonFormField<T>;
    assert(dropdownButtonFormField.onChanged != null);
    dropdownButtonFormField.onChanged!(value);
  }

  @override
  void didUpdateWidget(DropdownButtonFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}
