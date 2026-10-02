import 'package:drift/drift.dart';

import '../../../domain/models/app_notification.dart';
import '../converters/string_map_converter.dart';

@DataClassName('NotificationRow')
class Notifications extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get type => textEnum<AppNotificationType>()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payload =>
      text().map(const StringMapConverter()).withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
