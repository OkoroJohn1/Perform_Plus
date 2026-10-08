// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slip_upload_dao.dart';

// ignore_for_file: type=lint
mixin _$SlipUploadDaoMixin on DatabaseAccessor<AppDatabase> {
  $SlipUploadsTable get slipUploads => attachedDatabase.slipUploads;
  SlipUploadDaoManager get managers => SlipUploadDaoManager(this);
}

class SlipUploadDaoManager {
  final _$SlipUploadDaoMixin _db;
  SlipUploadDaoManager(this._db);
  $$SlipUploadsTableTableManager get slipUploads =>
      $$SlipUploadsTableTableManager(_db.attachedDatabase, _db.slipUploads);
}
