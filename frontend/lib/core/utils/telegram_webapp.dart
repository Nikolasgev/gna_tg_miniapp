// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

/// Utility class for interacting with Telegram WebApp API
class TelegramWebApp {
  static bool get isAvailable {
    try {
      return js.context.hasProperty('Telegram') &&
          js.context['Telegram'] != null &&
          js.context['Telegram']['WebApp'] != null;
    } catch (e) {
      return false;
    }
  }

  static dynamic get webApp {
    if (!isAvailable) return null;
    return js.context['Telegram']['WebApp'];
  }

  /// Get init_data from Telegram WebApp
  static String? getInitData() {
    if (!isAvailable) return null;
    try {
      return webApp['initData'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Get init_data_unsafe (parsed data) from Telegram WebApp
  static Map<String, dynamic>? getInitDataUnsafe() {
    if (!isAvailable) return null;
    try {
      final unsafe = webApp['initDataUnsafe'];
      if (unsafe != null) {
        return Map<String, dynamic>.from(unsafe as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get theme parameters from Telegram
  static Map<String, dynamic>? getThemeParams() {
    if (!isAvailable) return null;
    try {
      final themeParams = webApp['themeParams'];
      if (themeParams != null) {
        return Map<String, dynamic>.from(themeParams as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get viewport height
  static double? getViewportHeight() {
    if (!isAvailable) return null;
    try {
      return (webApp['viewportHeight'] as num?)?.toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Get viewport stable height
  static double? getViewportStableHeight() {
    if (!isAvailable) return null;
    try {
      return (webApp['viewportStableHeight'] as num?)?.toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Expand the WebApp
  static void expand() {
    if (!isAvailable) return;
    try {
      webApp.callMethod('expand');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Close the WebApp
  static void close() {
    if (!isAvailable) return;
    try {
      webApp.callMethod('close');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Open a link externally
  static void openLink(String url) {
    if (!isAvailable) return;
    try {
      webApp.callMethod('openLink', [url]);
    } catch (e) {
      // Fallback to window.open
      js.context.callMethod('open', [url, '_blank']);
    }
  }

  /// Show alert
  static void showAlert(String message) {
    if (!isAvailable) return;
    try {
      webApp.callMethod('showAlert', [message]);
    } catch (e) {
      // Fallback
      js.context.callMethod('alert', [message]);
    }
  }

  /// Show confirm dialog
  static void showConfirm(String message, Function(bool) callback) {
    if (!isAvailable) {
      final result = js.context.callMethod('confirm', [message]) as bool;
      callback(result);
      return;
    }
    try {
      webApp.callMethod('showConfirm', [
        message,
        js.allowInterop((confirmed) {
          callback(confirmed as bool);
        })
      ]);
    } catch (e) {
      final result = js.context.callMethod('confirm', [message]) as bool;
      callback(result);
    }
  }

  /// Enable closing confirmation
  static void enableClosingConfirmation() {
    if (!isAvailable) return;
    try {
      webApp.callMethod('enableClosingConfirmation');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Disable closing confirmation
  static void disableClosingConfirmation() {
    if (!isAvailable) return;
    try {
      webApp.callMethod('disableClosingConfirmation');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Set header color
  static void setHeaderColor(String color) {
    if (!isAvailable) return;
    try {
      webApp.callMethod('setHeaderColor', [color]);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Set background color
  static void setBackgroundColor(String color) {
    if (!isAvailable) return;
    try {
      webApp.callMethod('setBackgroundColor', [color]);
    } catch (e) {
      // Ignore errors
    }
  }
}

