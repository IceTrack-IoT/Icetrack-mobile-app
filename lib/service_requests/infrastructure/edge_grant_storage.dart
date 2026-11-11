import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the edge grant token returned once by `PUT /accept`.
/// It lets the technician operate the on-site gateway (maintenance mode,
/// buzzer, local status), so it lives in the secure store.
class EdgeGrantStorage {
  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _key(int serviceRequestId) => 'icetrack.edge_grant.$serviceRequestId';

  Future<void> save(int serviceRequestId, String token) => _secure.write(key: _key(serviceRequestId), value: token);

  Future<String?> read(int serviceRequestId) => _secure.read(key: _key(serviceRequestId));

  Future<void> delete(int serviceRequestId) => _secure.delete(key: _key(serviceRequestId));
}
