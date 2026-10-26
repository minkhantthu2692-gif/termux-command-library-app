// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_dao.dart';

// ignore_for_file: type=lint
mixin _$CommandDaoMixin on DatabaseAccessor<AppDatabase> {
  $CommandsTable get commands => attachedDatabase.commands;
  $CommandStepsTable get commandSteps => attachedDatabase.commandSteps;
  $FavoritesTable get favorites => attachedDatabase.favorites;
  $PinsTable get pins => attachedDatabase.pins;
  CommandDaoManager get managers => CommandDaoManager(this);
}

class CommandDaoManager {
  final _$CommandDaoMixin _db;
  CommandDaoManager(this._db);
  $$CommandsTableTableManager get commands =>
      $$CommandsTableTableManager(_db.attachedDatabase, _db.commands);
  $$CommandStepsTableTableManager get commandSteps =>
      $$CommandStepsTableTableManager(_db.attachedDatabase, _db.commandSteps);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db.attachedDatabase, _db.favorites);
  $$PinsTableTableManager get pins =>
      $$PinsTableTableManager(_db.attachedDatabase, _db.pins);
}
