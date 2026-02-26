
import 'package:usp_protocol_common/usp_protocol_common.dart';

abstract class Notification {}

class ValueChangeNotification implements Notification {
  final UspPath path;
  final UspValue oldValue;
  final UspValue newValue;

  ValueChangeNotification({
    required this.path,
    required this.oldValue,
    required this.newValue,
  });
}

class ObjectCreationNotification implements Notification {
  final UspPath path;

  ObjectCreationNotification({required this.path});
}

class ObjectDeletionNotification implements Notification {
  final UspPath path;

  ObjectDeletionNotification({required this.path});
}
