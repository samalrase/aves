import 'dart:math';

import 'package:aves/app_mode.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/widgets/collection/collection_page.dart';
import 'package:aves/widgets/common/bars/floating_bar.dart';
import 'package:aves/widgets/common/basic/draggable_scrollbar/notifications.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/extensions/media_query.dart';
import 'package:aves/widgets/navigation/nav_bar/floating.dart';
import 'package:aves/widgets/navigation/nav_item.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class const AppBottomNavBar({
  super.key,
  required final Stream<DraggableScrollbarEvent> events,
  // collection loaded in the `CollectionPage`, if any
  final CollectionLens? currentCollection,
}) extends StatefulWidget {
  // taller than the default to make room for the labels below the icons
  static const double barHeight = 64;
  static const double labelFontSize = 11.5;

  static EdgeInsets getMargin(double safeBottomPadding) {
    // keep the bar close to the bottom edge of the screen
    return EdgeInsets.only(left: 8, top: 8, right: 8, bottom: max(4, safeBottomPadding - 10));
  }

  static double getHeightWithMargin(double safeBottomPadding) {
    return barHeight + getMargin(safeBottomPadding).vertical;
  }

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    _registerWidget(widget);
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    super.dispose();
  }

  void _registerWidget(AppBottomNavBar widget) {
    widget.currentCollection?.filterChangeNotifier.addListener(_onCollectionFilterChanged);
  }

  void _unregisterWidget(AppBottomNavBar widget) {
    widget.currentCollection?.filterChangeNotifier.removeListener(_onCollectionFilterChanged);
  }

  @override
  Widget build(BuildContext context) {
    final items = context.select<Settings, List<AvesNavItem>>((v) => v.bottomNavigationActions);
    if (items.length < 2) return const SizedBox();

    final safeBottomPadding = context.select<MediaQueryData, double>((mq) => mq.safeBottomPadding);
    final margin = AppBottomNavBar.getMargin(safeBottomPadding);
    final totalHeight = AppBottomNavBar.getHeightWithMargin(safeBottomPadding);
    final barBottomStop = ((margin.top + AppBottomNavBar.barHeight) / totalHeight).clamp(0.0, 1.0);
    final barMiddleStop = ((margin.top + AppBottomNavBar.barHeight / 2) / totalHeight).clamp(0.0, 1.0);

    final bar = SafeArea(
      bottom: false,
      child: MediaQuery.removePadding(
        context: context,
        // `bottom` is computed beforehand and used in multiple places,
        // so we remove it from context to prevent additional padding
        removeBottom: true,
        child: AvesFloatingBar(
          margin: margin,
          builder: (context, backgroundColor, child) => SizedBox(
            height: AppBottomNavBar.barHeight,
            child: BottomNavigationBar(
              items: items.map((item) {
                final label = item.getText(context);
                return BottomNavigationBarItem(
                  icon: item.getIcon(context),
                  label: label,
                  tooltip: label,
                );
              }).toList(),
              onTap: (index) => _goTo(context, items, index),
              currentIndex: _getCurrentIndex(context, items),
              type: BottomNavigationBarType.fixed,
              backgroundColor: backgroundColor,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: AppBottomNavBar.labelFontSize,
              unselectedFontSize: AppBottomNavBar.labelFontSize,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, letterSpacing: .2),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, letterSpacing: .2),
            ),
          ),
        ),
      ),
    );

    Widget child = FloatingNavBar(
      scrollController: PrimaryScrollController.of(context),
      events: widget.events,
      childHeight: totalHeight,
      child: Stack(
        children: [
          // black shadow fading in below the bar, so that nothing of the page is visible beneath it
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: .6),
                      Colors.black,
                    ],
                    stops: [0, barMiddleStop, barBottomStop],
                  ),
                ),
              ),
            ),
          ),
          bar,
        ],
      ),
    );

    final animate = context.select<Settings, bool>((v) => v.animate);
    if (animate) {
      child = Hero(
        tag: 'nav-bar',
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          return MediaQuery.removeViewInsets(
            context: context,
            removeBottom: true,
            child: toHeroContext.widget,
          );
        },
        child: child,
      );
    }

    return child;
  }

  void _onCollectionFilterChanged() => setState(() {});

  int _getCurrentIndex(BuildContext context, List<AvesNavItem> items) {
    // current route may be null during navigation
    final currentRoute = context.currentRouteName ?? _lastRoute;
    _lastRoute = currentRoute;

    final currentItem = items.firstWhereOrNull((item) {
      final itemRoute = item.route;
      if (currentRoute != itemRoute) return false;

      switch (itemRoute) {
        case CollectionPage.routeName:
          final currentFilters = widget.currentCollection?.filters ?? {};
          return const SetEquality().equals(currentFilters, item.filters ?? {});
        default:
          return true;
      }
    });
    final currentIndex = currentItem != null ? items.indexOf(currentItem) : 0;
    return currentIndex;
  }

  void _goTo(BuildContext context, List<AvesNavItem> items, int index) {
    final item = items[index];
    item.goTo(context, topLevel: null);
  }
}

class const NavBarPaddingSliver({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final canNavigate = context.select<ValueNotifier<AppMode>, bool>((v) => v.value.canNavigate);
    final enableBottomNavigationBar = context.select<Settings, bool>((v) => v.enableBottomNavigationBar);
    final safeBottomPadding = context.select<MediaQueryData, double>((mq) => mq.safeBottomPadding);
    final showBottomNavigationBar = canNavigate && enableBottomNavigationBar;
    final height = showBottomNavigationBar ? AppBottomNavBar.getHeightWithMargin(safeBottomPadding) : safeBottomPadding;
    return SliverToBoxAdapter(
      child: SizedBox(height: height),
    );
  }
}
