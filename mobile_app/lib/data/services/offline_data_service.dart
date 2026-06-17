import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/encaminhamento_model.dart';
import '../models/dashboard_model.dart';
import '../models/propriedade_model.dart';
import '../models/usuario_model.dart';
import '../models/visita_detalhe_model.dart';
import '../models/visita_model.dart';

class SyncQueueItem {
  const SyncQueueItem({
    required this.operationId,
    required this.entityType,
    required this.action,
    required this.localId,
    this.serverId,
    this.baseVersion,
    this.dependsOn = const [],
    this.payload,
    required this.createdAt,
  });

  final String operationId;
  final String entityType;
  final String action;
  final String localId;
  final int? serverId;
  final int? baseVersion;
  final List<String> dependsOn;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;

  Map<String, Object?> toRow() {
    return {
      'operation_id': operationId,
      'entity_type': entityType,
      'action': action,
      'local_id': localId,
      'server_id': serverId,
      'base_version': baseVersion,
      'depends_on_json': jsonEncode(dependsOn),
      'payload_json': payload == null ? null : jsonEncode(payload),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncQueueItem.fromRow(Map<String, Object?> row) {
    return SyncQueueItem(
      operationId: row['operation_id'] as String,
      entityType: row['entity_type'] as String,
      action: row['action'] as String,
      localId: row['local_id'] as String,
      serverId: row['server_id'] as int?,
      baseVersion: row['base_version'] as int?,
      dependsOn: OfflineDataService._decodeStringList(
        row['depends_on_json'] as String?,
      ),
      payload: OfflineDataService._decodeMap(row['payload_json'] as String?),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OfflineDataService {
  OfflineDataService._();

  static final OfflineDataService instance = OfflineDataService._();

  static const _databaseName = 'polivisitas_offline.db';
  static const _databaseVersion = 1;

  static const _propertiesTable = 'cached_propriedades';
  static const _visitsTable = 'cached_visitas';
  static const _tasksTable = 'cached_encaminhamentos';
  static const _queueTable = 'sync_queue';
  static const _metadataTable = 'sync_metadata';

  static const _syncTokenKey = 'last_sync_token';
  static const _profileKeyPrefix = 'profile_json_';
  static const _dashboardKeyPrefix = 'dashboard_json_';

  Database? _database;

  Future<Database> get _db async {
    _database ??= await _open();
    return _database!;
  }

  Future<void> cachePropriedades(List<Map<String, dynamic>> rawItems) async {
    final db = await _db;
    final batch = db.batch();

    for (final item in rawItems) {
      final id = _asInt(item['id']);
      if (id == null) continue;

      batch.insert(_propertiesTable, {
        'local_id': _propertyLocalId(id),
        'server_id': id,
        'json': jsonEncode(item),
        'version': _asInt(item['version']),
        'updated_at':
            (item['atualizadoEm'] as String?) ??
            DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<PropriedadeModel>> readCachedPropriedades({bool? ativa}) async {
    final db = await _db;
    final rows = await db.query(_propertiesTable, orderBy: 'local_id ASC');
    return rows
        .map((row) => _decodeMap(row['json'] as String))
        .whereType<Map<String, dynamic>>()
        .map(PropriedadeModel.fromJson)
        .where((item) => ativa == null || item.ativa == ativa)
        .toList();
  }

  Future<PropriedadeModel?> findCachedPropriedade(int id) async {
    final db = await _db;
    final rows = await db.query(
      _propertiesTable,
      where: 'local_id = ?',
      whereArgs: [_propertyLocalId(id)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return PropriedadeModel.fromJson(_decodeMap(rows.first['json'] as String)!);
  }

  Future<void> cacheCurrentUserProfile(Map<String, dynamic> raw) async {
    final userId = _asInt(raw['id']);
    if (userId == null) {
      return;
    }
    await _setMetadata(_profileKey(userId), jsonEncode(raw));
  }

  Future<UsuarioModel?> readCachedCurrentUserProfile(int? userId) async {
    if (userId == null) {
      return null;
    }
    final raw = await _getMetadata(_profileKey(userId));
    final decoded = _decodeMap(raw);
    if (decoded == null) {
      return null;
    }
    return UsuarioModel.fromJson(decoded);
  }

  Future<void> cacheDashboard(Map<String, dynamic> raw, int? userId) async {
    if (userId == null) {
      return;
    }
    await _setMetadata(_dashboardKey(userId), jsonEncode(raw));
  }

  Future<DashboardModel?> readCachedDashboard(int? userId) async {
    if (userId == null) {
      return null;
    }
    final raw = await _getMetadata(_dashboardKey(userId));
    final decoded = _decodeMap(raw);
    if (decoded == null) {
      return null;
    }
    return DashboardModel.fromJson(decoded);
  }

  Future<void> cacheVisitas(List<Map<String, dynamic>> rawItems) async {
    final db = await _db;
    final pendingLocalIds = await _pendingLocalIds('VISITA');
    final batch = db.batch();

    for (final item in rawItems) {
      final id = _asInt(item['id']);
      if (id == null) continue;

      final localId = _visitLocalId(id);
      if (pendingLocalIds.contains(localId)) {
        continue;
      }

      final mergedItem = await _mergeVisitSnapshot(
        localId: localId,
        incoming: item,
      );

      batch.insert(_visitsTable, {
        'local_id': localId,
        'server_id': id,
        'json': jsonEncode(mergedItem),
        'version': _asInt(mergedItem['version']),
        'updated_at':
            (mergedItem['atualizadoEm'] as String?) ??
            DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<VisitaModel>> readCachedVisitas({String? status}) async {
    final db = await _db;
    final rows = await db.query(_visitsTable, orderBy: 'updated_at DESC');
    return rows
        .map((row) => _decodeMap(row['json'] as String))
        .whereType<Map<String, dynamic>>()
        .map(VisitaModel.fromJson)
        .where((item) => status == null || item.statusVisita == status)
        .toList();
  }

  Future<int> countCachedVisitas() async {
    final db = await _db;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_visitsTable'),
    );
    return result ?? 0;
  }

  Future<VisitaDetalheModel?> findCachedVisitDetail(int id) async {
    final row = await _findVisitRow(id);
    if (row == null) {
      return null;
    }
    return VisitaDetalheModel.fromJson(_decodeMap(row['json'] as String)!);
  }

  Future<VisitaModel> saveOfflineCreatedVisit({
    required Map<String, dynamic> payload,
    required int usuarioId,
    required String usuarioNome,
    required PropriedadeModel propriedade,
  }) async {
    final db = await _db;
    final localNumericId = -DateTime.now().microsecondsSinceEpoch;
    final localId = _visitLocalId(localNumericId);
    final now = DateTime.now().toIso8601String();

    final visitJson = {
      'id': localNumericId,
      'usuarioId': usuarioId,
      'usuarioNome': usuarioNome,
      'propriedadeId': propriedade.id,
      'propriedadeNome': propriedade.nome,
      'dataVisita': payload['dataVisita'],
      'horaVisita': payload['horaVisita'],
      'tipoVisita': payload['tipoVisita'],
      'temaPrincipal': payload['temaPrincipal'],
      'observacoes': payload['observacoes'],
      'statusVisita': 'AGENDADA',
      'urgencia': payload['urgencia'] ?? 'BAIXA',
    };

    await db.insert(_visitsTable, {
      'local_id': localId,
      'server_id': null,
      'json': jsonEncode(visitJson),
      'version': null,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _insertQueueItem(
      SyncQueueItem(
        operationId: _newOperationId('create-visita'),
        entityType: 'VISITA',
        action: 'CREATE_VISITA',
        localId: localId,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );

    return VisitaModel.fromJson(visitJson);
  }

  Future<VisitaModel> saveOfflineUpdatedVisit({
    required int visitId,
    required Map<String, dynamic> payload,
    PropriedadeModel? propriedade,
  }) async {
    final db = await _db;
    final row = await _findVisitRow(visitId);
    final existingJson = row == null
        ? <String, dynamic>{
            'id': visitId,
            'usuarioId': 0,
            'usuarioNome': '',
            'propriedadeId': payload['propriedadeId'],
            'propriedadeNome': propriedade?.nome ?? '',
            'dataVisita': payload['dataVisita'],
            'horaVisita': payload['horaVisita'],
            'statusVisita': 'AGENDADA',
            'urgencia': payload['urgencia'] ?? 'BAIXA',
          }
        : _decodeMap(row['json'] as String)!;

    existingJson
      ..['propriedadeId'] = payload['propriedadeId']
      ..['propriedadeNome'] =
          propriedade?.nome ?? existingJson['propriedadeNome']
      ..['dataVisita'] = payload['dataVisita']
      ..['horaVisita'] = payload['horaVisita']
      ..['tipoVisita'] = payload['tipoVisita']
      ..['temaPrincipal'] = payload['temaPrincipal']
      ..['observacoes'] = payload['observacoes']
      ..['urgencia'] = payload['urgencia'] ?? existingJson['urgencia'];

    final localId = _visitLocalId(existingJson['id'] as int);
    final baseVersion = row?['version'] as int?;

    await db.insert(_visitsTable, {
      'local_id': localId,
      'server_id': visitId > 0 ? visitId : null,
      'json': jsonEncode(existingJson),
      'version': baseVersion,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (visitId < 0) {
      await _replacePendingVisitPayload(localId, 'CREATE_VISITA', payload);
      return VisitaModel.fromJson(existingJson);
    }

    final latest = await _latestQueueItemFor(localId);
    final existingUpdate = await _findQueueItem(localId, 'UPDATE_VISITA');
    final item = SyncQueueItem(
      operationId:
          existingUpdate?.operationId ?? _newOperationId('update-visita'),
      entityType: 'VISITA',
      action: 'UPDATE_VISITA',
      localId: localId,
      serverId: visitId,
      baseVersion: existingUpdate?.baseVersion ?? baseVersion,
      dependsOn: _dependsOn(latest, existingUpdate),
      payload: payload,
      createdAt: existingUpdate?.createdAt ?? DateTime.now(),
    );

    await _insertQueueItem(item);
    return VisitaModel.fromJson(existingJson);
  }

  Future<VisitaModel> saveOfflineFinalizedVisit({
    required int visitId,
    required Map<String, dynamic> syncPayload,
  }) async {
    final db = await _db;
    final row = await _findVisitRow(visitId);
    if (row == null) {
      throw StateError('Visita não encontrada no cache local.');
    }

    final json = _decodeMap(row['json'] as String)!;
    json['statusVisita'] = 'CONCLUIDA';
    if (syncPayload['observacoesGerais'] != null) {
      json['observacoes'] = syncPayload['observacoesGerais'];
    }
    json['diagnosticos'] = _diagnosticosFromPayload(syncPayload, visitId);
    json['encaminhamentos'] = _encaminhamentosFromPayload(syncPayload, visitId);

    final localId = row['local_id'] as String;
    final latest = await _latestQueueItemFor(localId);
    final existingFinalize = await _findQueueItem(localId, 'FINALIZE_VISITA');
    final item = SyncQueueItem(
      operationId:
          existingFinalize?.operationId ?? _newOperationId('finalize-visita'),
      entityType: 'VISITA',
      action: 'FINALIZE_VISITA',
      localId: localId,
      serverId: visitId > 0 ? visitId : null,
      baseVersion: existingFinalize?.baseVersion ?? row['version'] as int?,
      dependsOn: _dependsOn(latest, existingFinalize),
      payload: syncPayload,
      createdAt: existingFinalize?.createdAt ?? DateTime.now(),
    );

    await db.insert(_visitsTable, {
      'local_id': localId,
      'server_id': row['server_id'],
      'json': jsonEncode(json),
      'version': row['version'],
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _insertQueueItem(item);
    return VisitaModel.fromJson(json);
  }

  Future<EncaminhamentoModel> saveOfflineConcludedTask(
    EncaminhamentoModel task,
  ) async {
    if (task.id <= 0) {
      throw StateError(
        'Encaminhamentos ainda não sincronizados não podem ser concluídos offline.',
      );
    }

    final db = await _db;
    final row = await _findTaskRow(task.id);
    final json = row == null
        ? _encaminhamentoToJson(task)
        : _decodeMap(row['json'] as String)!;
    json['status'] = 'CONCLUIDO';

    final localId = _taskLocalId(task.id);
    final existing = await _findQueueItem(localId, 'CONCLUDE_ENCAMINHAMENTO');
    if (existing == null) {
      await _insertQueueItem(
        SyncQueueItem(
          operationId: _newOperationId('conclude-encaminhamento'),
          entityType: 'ENCAMINHAMENTO',
          action: 'CONCLUDE_ENCAMINHAMENTO',
          localId: localId,
          serverId: task.id,
          baseVersion: row?['version'] as int?,
          createdAt: DateTime.now(),
        ),
      );
    }

    await db.insert(_tasksTable, {
      'local_id': localId,
      'server_id': task.id,
      'json': jsonEncode(json),
      'version': row?['version'],
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return EncaminhamentoModel.fromJson(json);
  }

  Future<EncaminhamentoModel> saveOfflineCancelledTask(
    EncaminhamentoModel task,
  ) async {
    if (task.id <= 0) {
      throw StateError(
        'Encaminhamentos ainda não sincronizados não podem ser cancelados offline.',
      );
    }

    final db = await _db;
    final row = await _findTaskRow(task.id);
    final json = row == null
        ? _encaminhamentoToJson(task)
        : _decodeMap(row['json'] as String)!;
    json['status'] = 'CANCELADO';

    final localId = _taskLocalId(task.id);
    final existing = await _findQueueItem(localId, 'CANCEL_ENCAMINHAMENTO');
    if (existing == null) {
      await _insertQueueItem(
        SyncQueueItem(
          operationId: _newOperationId('cancel-encaminhamento'),
          entityType: 'ENCAMINHAMENTO',
          action: 'CANCEL_ENCAMINHAMENTO',
          localId: localId,
          serverId: task.id,
          baseVersion: row?['version'] as int?,
          createdAt: DateTime.now(),
        ),
      );
    }

    await db.insert(_tasksTable, {
      'local_id': localId,
      'server_id': task.id,
      'json': jsonEncode(json),
      'version': row?['version'],
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return EncaminhamentoModel.fromJson(json);
  }

  Future<void> cacheEncaminhamentos(List<Map<String, dynamic>> rawItems) async {
    final db = await _db;
    final pendingLocalIds = await _pendingLocalIds('ENCAMINHAMENTO');
    final batch = db.batch();

    for (final item in rawItems) {
      final id = _asInt(item['id']);
      if (id == null) continue;

      final localId = _taskLocalId(id);
      if (pendingLocalIds.contains(localId)) {
        continue;
      }

      batch.insert(_tasksTable, {
        'local_id': localId,
        'server_id': id,
        'json': jsonEncode(item),
        'version': _asInt(item['version']),
        'updated_at':
            (item['atualizadoEm'] as String?) ??
            DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<List<EncaminhamentoModel>> readCachedEncaminhamentos({
    String? status,
  }) async {
    final db = await _db;
    final rows = await db.query(_tasksTable, orderBy: 'updated_at DESC');
    return rows
        .map((row) => _decodeMap(row['json'] as String))
        .whereType<Map<String, dynamic>>()
        .map(EncaminhamentoModel.fromJson)
        .where((item) => status == null || item.status == status)
        .toList();
  }

  Future<List<SyncQueueItem>> listPendingOperations() async {
    final db = await _db;
    final rows = await db.query(_queueTable, orderBy: 'created_at ASC');
    return rows.map(SyncQueueItem.fromRow).toList();
  }

  Future<int> countPendingOperations() async {
    final db = await _db;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_queueTable'),
        ) ??
        0;
  }

  Future<String?> getLastSyncToken() => _getMetadata(_syncTokenKey);

  Future<void> setLastSyncToken(String token) =>
      _setMetadata(_syncTokenKey, token);

  Future<void> upsertVisitSnapshot(
    Map<String, dynamic> snapshot, {
    String? previousLocalId,
    int? serverIdOverride,
  }) async {
    final db = await _db;
    final serverId = serverIdOverride ?? _asInt(snapshot['id']);
    if (serverId == null) return;

    final newLocalId = _visitLocalId(serverId);
    final mergedSnapshot = await _mergeVisitSnapshot(
      localId: newLocalId,
      incoming: snapshot,
    );
    final version = _asInt(mergedSnapshot['version']);
    final updatedAt =
        (mergedSnapshot['atualizadoEm'] as String?) ??
        DateTime.now().toIso8601String();

    await db.insert(_visitsTable, {
      'local_id': newLocalId,
      'server_id': serverId,
      'json': jsonEncode(mergedSnapshot),
      'version': version,
      'updated_at': updatedAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (previousLocalId != null && previousLocalId != newLocalId) {
      await db.delete(
        _visitsTable,
        where: 'local_id = ?',
        whereArgs: [previousLocalId],
      );
      await db.update(
        _queueTable,
        {'local_id': newLocalId, 'server_id': serverId},
        where: 'local_id = ?',
        whereArgs: [previousLocalId],
      );
    }
  }

  Future<void> upsertEncaminhamentoSnapshot(
    Map<String, dynamic> snapshot,
  ) async {
    final db = await _db;
    final serverId = _asInt(snapshot['id']);
    if (serverId == null) return;

    await db.insert(_tasksTable, {
      'local_id': _taskLocalId(serverId),
      'server_id': serverId,
      'json': jsonEncode(snapshot),
      'version': _asInt(snapshot['version']),
      'updated_at':
          (snapshot['atualizadoEm'] as String?) ??
          DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCachedVisitaStatus(int serverId, String status) async {
    final db = await _db;
    final row = await _findVisitRow(serverId);
    if (row == null) return;
    final json = _decodeMap(row['json'] as String);
    if (json == null) return;
    json['statusVisita'] = status;
    await db.update(
      _visitsTable,
      {'json': jsonEncode(json), 'updated_at': DateTime.now().toIso8601String()},
      where: 'local_id = ?',
      whereArgs: [row['local_id']],
    );
  }

  Future<void> updateCachedEncaminhamentoStatus(int serverId, String status) async {
    final db = await _db;
    final row = await _findTaskRow(serverId);
    if (row == null) return;
    final json = _decodeMap(row['json'] as String);
    if (json == null) return;
    json['status'] = status;
    await db.update(
      _tasksTable,
      {'json': jsonEncode(json), 'updated_at': DateTime.now().toIso8601String()},
      where: 'local_id = ?',
      whereArgs: [row['local_id']],
    );
  }

  Future<void> removeQueueOperation(String operationId) async {
    final db = await _db;
    await db.delete(
      _queueTable,
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }

  Future<void> deleteVisitByServerId(int serverId) async {
    final db = await _db;
    await db.delete(
      _visitsTable,
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
  }

  Future<void> deleteEncaminhamentoByServerId(int serverId) async {
    final db = await _db;
    await db.delete(_tasksTable, where: 'server_id = ?', whereArgs: [serverId]);
  }

  Future<void> deletePropriedadeByServerId(int serverId) async {
    final db = await _db;
    await db.delete(
      _propertiesTable,
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
  }

  Future<void> updateQueuedVisitReferences({
    required String previousLocalId,
    required String newLocalId,
    required int serverId,
  }) async {
    final db = await _db;
    await db.update(
      _queueTable,
      {'local_id': newLocalId, 'server_id': serverId},
      where: 'local_id = ?',
      whereArgs: [previousLocalId],
    );
  }

  Future<void> upsertPropriedadeSnapshot(Map<String, dynamic> snapshot) async {
    final db = await _db;
    final serverId = _asInt(snapshot['id']);
    if (serverId == null) return;

    await db.insert(_propertiesTable, {
      'local_id': _propertyLocalId(serverId),
      'server_id': serverId,
      'json': jsonEncode(snapshot),
      'version': _asInt(snapshot['version']),
      'updated_at':
          (snapshot['atualizadoEm'] as String?) ??
          DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete(_propertiesTable);
    await db.delete(_visitsTable);
    await db.delete(_tasksTable);
    await db.delete(_queueTable);
    await db.delete(_metadataTable);
  }

  Future<void> _replacePendingVisitPayload(
    String localId,
    String action,
    Map<String, dynamic> payload,
  ) async {
    final existing = await _findQueueItem(localId, action);
    if (existing == null) {
      return;
    }

    final db = await _db;
    await db.update(
      _queueTable,
      {'payload_json': jsonEncode(payload)},
      where: 'operation_id = ?',
      whereArgs: [existing.operationId],
    );
  }

  Future<void> _insertQueueItem(SyncQueueItem item) async {
    final db = await _db;
    await db.insert(
      _queueTable,
      item.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SyncQueueItem?> _findQueueItem(String localId, String action) async {
    final db = await _db;
    final rows = await db.query(
      _queueTable,
      where: 'local_id = ? AND action = ?',
      whereArgs: [localId, action],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SyncQueueItem.fromRow(rows.first);
  }

  Future<Map<String, dynamic>> _mergeVisitSnapshot({
    required String localId,
    required Map<String, dynamic> incoming,
  }) async {
    final existing = await _findVisitRowByLocalId(localId);
    if (existing == null) {
      return Map<String, dynamic>.from(incoming);
    }

    final existingJson = _decodeMap(existing['json'] as String);
    if (existingJson == null) {
      return Map<String, dynamic>.from(incoming);
    }

    final merged = Map<String, dynamic>.from(existingJson)..addAll(incoming);
    if (!incoming.containsKey('diagnosticos') &&
        existingJson.containsKey('diagnosticos')) {
      merged['diagnosticos'] = existingJson['diagnosticos'];
    }
    if (!incoming.containsKey('encaminhamentos') &&
        existingJson.containsKey('encaminhamentos')) {
      merged['encaminhamentos'] = existingJson['encaminhamentos'];
    }
    return merged;
  }

  Future<SyncQueueItem?> _latestQueueItemFor(String localId) async {
    final db = await _db;
    final rows = await db.query(
      _queueTable,
      where: 'local_id = ?',
      whereArgs: [localId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SyncQueueItem.fromRow(rows.first);
  }

  Future<Map<String, Object?>?> _findVisitRow(int visitId) async {
    final db = await _db;
    final rows = await db.query(
      _visitsTable,
      where: 'local_id = ? OR server_id = ?',
      whereArgs: [_visitLocalId(visitId), visitId > 0 ? visitId : null],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> _findVisitRowByLocalId(String localId) async {
    final db = await _db;
    final rows = await db.query(
      _visitsTable,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> _findTaskRow(int taskId) async {
    final db = await _db;
    final rows = await db.query(
      _tasksTable,
      where: 'local_id = ? OR server_id = ?',
      whereArgs: [_taskLocalId(taskId), taskId > 0 ? taskId : null],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Set<String>> _pendingLocalIds(String entityType) async {
    final db = await _db;
    final rows = await db.query(
      _queueTable,
      columns: ['local_id'],
      where: 'entity_type = ?',
      whereArgs: [entityType],
    );
    return rows
        .map((row) => row['local_id'] as String?)
        .whereType<String>()
        .toSet();
  }

  List<String> _dependsOn(SyncQueueItem? latest, SyncQueueItem? current) {
    if (latest == null || latest.operationId == current?.operationId) {
      return current?.dependsOn ?? const [];
    }
    return [latest.operationId];
  }

  Future<void> _setMetadata(String key, String value) async {
    final db = await _db;
    await db.insert(_metadataTable, {
      'meta_key': key,
      'meta_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> _getMetadata(String key) async {
    final db = await _db;
    final rows = await db.query(
      _metadataTable,
      where: 'meta_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['meta_value'] as String?;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    return openDatabase(
      path.join(databasesPath, _databaseName),
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_propertiesTable (
            local_id TEXT PRIMARY KEY,
            server_id INTEGER,
            json TEXT NOT NULL,
            version INTEGER,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_visitsTable (
            local_id TEXT PRIMARY KEY,
            server_id INTEGER,
            json TEXT NOT NULL,
            version INTEGER,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_tasksTable (
            local_id TEXT PRIMARY KEY,
            server_id INTEGER,
            json TEXT NOT NULL,
            version INTEGER,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_queueTable (
            operation_id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL,
            action TEXT NOT NULL,
            local_id TEXT NOT NULL,
            server_id INTEGER,
            base_version INTEGER,
            depends_on_json TEXT,
            payload_json TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_metadataTable (
            meta_key TEXT PRIMARY KEY,
            meta_value TEXT
          )
        ''');
      },
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _visitLocalId(int id) => 'visita:$id';
  static String _taskLocalId(int id) => 'encaminhamento:$id';
  static String _propertyLocalId(int id) => 'propriedade:$id';
  static String _profileKey(int userId) => '$_profileKeyPrefix$userId';
  static String _dashboardKey(int userId) => '$_dashboardKeyPrefix$userId';

  static String _newOperationId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  static Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static Map<String, dynamic> _encaminhamentoToJson(EncaminhamentoModel task) {
    return {
      'id': task.id,
      'visitaId': task.visitaId,
      'propriedadeNome': task.propriedadeNome,
      'acaoRealizada': task.acaoRealizada,
      'responsavel': task.responsavel,
      'prazo': task.prazo?.toIso8601String(),
      'verificacao': task.verificacao,
      'prioridade': task.prioridade,
      'status': task.status,
    };
  }

  static List<Map<String, dynamic>> _diagnosticosFromPayload(
    Map<String, dynamic> payload,
    int visitId,
  ) {
    final diagnosticos = (payload['diagnosticos'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return List.generate(diagnosticos.length, (index) {
      final item = diagnosticos[index];
      return {
        'id': -((visitId.abs() * 1000) + index + 1),
        'categoria': item['categoria'] ?? '',
        'criticidade': item['criticidade'] ?? 'BAIXA',
        'observacoes': item['observacoes'],
        if (item['imagemUrl'] != null) 'imagemUrl': item['imagemUrl'],
      };
    });
  }

  static List<Map<String, dynamic>> _encaminhamentosFromPayload(
    Map<String, dynamic> payload,
    int visitId,
  ) {
    final encaminhamentos =
        (payload['encaminhamentos'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

    return List.generate(encaminhamentos.length, (index) {
      final item = encaminhamentos[index];
      return {
        'id': -((visitId.abs() * 1000) + index + 1),
        'acaoRealizada': item['acaoRealizada'] ?? '',
        'prioridade': item['prioridade'] ?? 'MEDIA',
        'status': item['status'] ?? 'PENDENTE',
        'responsavel': item['responsavel'],
        'prazo': item['prazo'],
        'verificacao': item['verificacao'],
      };
    });
  }
}
