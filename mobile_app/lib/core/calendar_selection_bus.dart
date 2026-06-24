import 'package:flutter/foundation.dart';

class CalendarSelectionBus {
  CalendarSelectionBus._();

  static final ValueNotifier<DateTime?> selectedDate =
      ValueNotifier<DateTime?>(null);
}
