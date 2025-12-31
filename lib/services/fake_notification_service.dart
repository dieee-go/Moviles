class FakeNotificationService {
  static final List<String> _notifications = [];

  static List<String> getNotifications() => _notifications;

  static int count() => _notifications.length;

  static void add(String message) {
    _notifications.add(message);
  }
}