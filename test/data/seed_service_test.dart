import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termux_command_library/core/errors/app_exception.dart';
import 'package:termux_command_library/data/local/database/app_database.dart';
import 'package:termux_command_library/data/services/seed_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  SeedService service(Future<String> Function() loader) => SeedService(
    commandDao: db.commandDao,
    syncDao: db.syncDao,
    loadAsset: loader,
  );

  test('installs the catalogue once and records its version', () async {
    final seedService = service(
      () => File('assets/data/seed_commands.json').readAsString(),
    );

    expect(await seedService.ensureSeeded(), isTrue);
    expect(await db.commandDao.countCommands(), 52);
    expect(await db.syncDao.readState('seedVersion'), '3');

    expect(await seedService.ensureSeeded(), isFalse);
    expect(await db.commandDao.countCommands(), 52);

    final first = await db.commandDao.getCommand('update-all-packages');
    expect(first, isNotNull);
    expect(first!.isSeed, isTrue);
    expect(first.steps.single.command, 'pkg update && pkg upgrade -y');
  });

  test('a newer seed version is installed over the old catalogue', () async {
    var version = 2;
    final seedService = service(() async {
      version = 3;
      return File('assets/data/seed_commands.json').readAsString();
    });
    await db.syncDao.writeState('seedVersion', '2');

    expect(await seedService.ensureSeeded(), isTrue);
    expect(version, 3);
    expect(await db.syncDao.readState('seedVersion'), '3');
  });

  test('missing assets are reported as a database failure', () async {
    final seedService = service(
      () => throw const FileSystemException('missing'),
    );

    await expectLater(
      seedService.ensureSeeded(),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.database,
        ),
      ),
    );
    expect(await db.commandDao.countCommands(), 0);
  });

  test('malformed JSON never partially seeds the database', () async {
    final seedService = service(() async => '{"not":"a list"}');

    await expectLater(
      seedService.ensureSeeded(),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.database,
        ),
      ),
    );
    expect(await db.commandDao.countCommands(), 0);
    expect(await db.syncDao.readState('seedVersion'), isNull);
  });

  test('individual malformed guides are skipped safely', () async {
    final seedService = service(
      () async => '''
      [
        {"id":"valid","name":"Valid guide","description":"Works","steps":[{"command":"echo ok"}]},
        {"name":"Missing id","description":"Should be skipped"},
        {"id":"also-valid","name":"Another","description":"Works too","steps":[]}
      ]
      ''',
    );

    expect(await seedService.ensureSeeded(), isTrue);
    expect(await db.commandDao.countCommands(), 2);
    expect(await db.commandDao.getCommand('valid'), isNotNull);
  });
}
