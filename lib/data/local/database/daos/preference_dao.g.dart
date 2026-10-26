// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_dao.dart';

// ignore_for_file: type=lint
mixin _$PreferenceDaoMixin on DatabaseAccessor<AppDatabase> {
  $FavoritesTable get favorites => attachedDatabase.favorites;
  $PinsTable get pins => attachedDatabase.pins;
  PreferenceDaoManager get managers => PreferenceDaoManager(this);
}

class PreferenceDaoManager {
  final _$PreferenceDaoMixin _db;
  PreferenceDaoManager(this._db);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db.attachedDatabase, _db.favorites);
  $$PinsTableTableManager get pins =>
      $$PinsTableTableManager(_db.attachedDatabase, _db.pins);
}
