import 'package:flutter/widgets.dart';
import 'bug_report_log_service.dart';

/// Tracks the active route/tab name and records sanitized navigation breadcrumbs.
///
/// Internal `/bug_report/*` routes are intentionally ignored so opening the
/// reporter preserves the underlying screen name where the issue occurred.
class BugReportRouteObserver extends NavigatorObserver {
  BugReportRouteObserver._internal();
  static final BugReportRouteObserver instance =
      BugReportRouteObserver._internal();

  static const String internalRoutePrefix = '/bug_report/';

  String _activeTab = 'main_shell/home';
  String? _topRouteName;

  /// Human-readable route identifier of the active screen before bug reporting.
  String get currentRouteName {
    final top = _topRouteName;
    if (top != null && top.isNotEmpty && top != '/') {
      return top;
    }
    return _activeTab;
  }

  void setActiveTab(String tabRouteName) {
    final clean = BugReportLogService.stripQueryString(tabRouteName);
    if (clean.isEmpty || clean == _activeTab) return;
    _activeTab = clean;
    BugReportLogService.instance.recordNavigation('tab', clean);
  }

  void reset() {
    _activeTab = 'main_shell/home';
    _topRouteName = null;
  }

  bool _isInternal(Route<dynamic>? route) {
    final name = route?.settings.name;
    return name != null && name.startsWith(internalRoutePrefix);
  }

  String _describeRoute(Route<dynamic>? route) {
    final name = route?.settings.name?.trim();
    if (name != null && name.isNotEmpty) {
      return BugReportLogService.stripQueryString(name);
    }
    if (route is ModalRoute) {
      return route is PopupRoute ? '$_activeTab/modal' : _activeTab;
    }
    return _activeTab;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_isInternal(route)) return;
    final name = _describeRoute(route);
    _topRouteName = name;
    BugReportLogService.instance.recordNavigation('push', name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_isInternal(route)) return;
    final prev = _isInternal(previousRoute) ? _topRouteName : _describeRoute(previousRoute);
    _topRouteName = prev;
    if (prev != null) {
      BugReportLogService.instance.recordNavigation('pop_to', prev);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_isInternal(newRoute)) return;
    final name = _describeRoute(newRoute);
    _topRouteName = name;
    BugReportLogService.instance.recordNavigation('replace', name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (_isInternal(route)) return;
    if (previousRoute != null && !_isInternal(previousRoute)) {
      _topRouteName = _describeRoute(previousRoute);
    }
  }
}
