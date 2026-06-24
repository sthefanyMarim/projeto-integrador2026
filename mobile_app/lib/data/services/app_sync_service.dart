import 'package:dio/dio.dart';

import 'api_client.dart';
import 'dashboard_service.dart';
import 'encaminhamento_service.dart';
import 'network_service.dart';
import 'offline_data_service.dart';
import 'propriedade_service.dart';
import 'token_service.dart';
import 'usuario_service.dart';
import 'visita_service.dart';

class AppSyncService {
  AppSyncService._()
    : _tokenService = TokenService(),
      _networkService = NetworkService(),
      _offlineDataService = OfflineDataService.instance,
      _apiClient = ApiClient(TokenService());

  static final AppSyncService instance = AppSyncService._();

  final TokenService _tokenService;
  final NetworkService _networkService;
  final OfflineDataService _offlineDataService;
  final ApiClient _apiClient;
  late final PropriedadeService _propriedadeService = PropriedadeService(
    _tokenService,
  );
  late final UsuarioService _usuarioService = UsuarioService(_tokenService);
  late final DashboardService _dashboardService = DashboardService(
    _tokenService,
  );
  late final VisitaService _visitaService = VisitaService(_tokenService);
  late final EncaminhamentoService _encaminhamentoService =
      EncaminhamentoService(_tokenService);

  Future<bool>? _runningFuture;
  Future<bool>? _primingFuture;

  Future<bool> isServerReachable() => _networkService.isServerReachable();

  Future<bool> hasPendingOperations() async {
    return (await _offlineDataService.countPendingOperations()) > 0;
  }

  Future<bool> primeEssentialData() {
    _primingFuture ??= _primeEssentialData().whenComplete(() {
      _primingFuture = null;
    });
    return _primingFuture!;
  }

  Future<bool> synchronizePending() {
    _runningFuture ??= _synchronize().whenComplete(() {
      _runningFuture = null;
    });
    return _runningFuture!;
  }

  Future<bool> _synchronize() async {
    final pending = await _offlineDataService.listPendingOperations();
    if (pending.isEmpty) {
      return false;
    }

    if (!await _networkService.isServerReachable()) {
      return false;
    }

    final deviceId = await _tokenService.getOrCreateDeviceId();
    final pendingIds = pending.map((item) => item.operationId).toSet();
    final lastSyncToken = int.tryParse(
      await _offlineDataService.getLastSyncToken() ?? '0',
    );

    final operations = <Map<String, dynamic>>[];
    for (final item in pending) {
      operations.add(await _buildOperation(item, pendingIds, deviceId));
    }

    final response = await _apiClient.dio.post(
      '/api/sync',
      data: {
        'deviceId': deviceId,
        'lastSyncToken': lastSyncToken,
        'appVersion': 'mobile_app',
        'operations': operations,
      },
    );

    final body = response.data as Map<String, dynamic>;
    final operationResults =
        (body['operationResults'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    final serverChanges = (body['serverChanges'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    var appliedAny = false;
    String? errorMessage;

    for (final result in operationResults) {
      final status = (result['status'] as String?) ?? 'FAILED';
      if (status == 'APPLIED') {
        appliedAny = true;
        await _applySuccessfulResult(result);
        continue;
      }

      if (status == 'FAILED' || status == 'CONFLICT') {
        errorMessage ??=
            (result['message'] as String?) ??
            'Não foi possível concluir a sincronização.';
      }
    }

    for (final change in serverChanges) {
      await _applyServerChange(change);
    }

    final nextSyncToken = body['nextSyncToken'];
    if (nextSyncToken != null) {
      await _offlineDataService.setLastSyncToken(nextSyncToken.toString());
    }

    if (errorMessage != null) {
      throw StateError(errorMessage);
    }

    return appliedAny;
  }

  Future<bool> _primeEssentialData() async {
    if (!await _networkService.isServerReachable()) {
      return false;
    }

    var refreshedAny = false;

    Future<void> refresh(Future<void> Function() action) async {
      try {
        await action();
        refreshedAny = true;
      } catch (_) {
      }
    }

    await Future.wait([
      refresh(() async {
        await _usuarioService.buscarMe();
      }),
      refresh(() async {
        await _dashboardService.fetchDashboard();
      }),
      refresh(() async {
        await _propriedadeService.listarAtivas();
      }),
      refresh(() async {
        await _visitaService.listar();
      }),
      refresh(() async {
        await _encaminhamentoService.listar();
      }),
    ]);

    await refresh(_primeHistoricalVisitDetails);

    return refreshedAny;
  }

  Future<void> _primeHistoricalVisitDetails() async {
    final cachedVisits = await _offlineDataService.readCachedVisitas();
    final today = DateTime.now();
    final historicalVisits =
        cachedVisits
            .where(
              (visit) =>
                  visit.id > 0 &&
                  (visit.concluida ||
                      visit.cancelada ||
                      DateTime(
                        visit.dataVisita.year,
                        visit.dataVisita.month,
                        visit.dataVisita.day,
                      ).isBefore(DateTime(today.year, today.month, today.day))),
            )
            .toList()
          ..sort((a, b) => b.dataVisita.compareTo(a.dataVisita));

    for (final visit in historicalVisits.take(30)) {
      try {
        await _visitaService.buscarDetalhes(visit.id);
      } catch (_) {
      }
    }
  }

  Future<Map<String, dynamic>> _buildOperation(
    SyncQueueItem item,
    Set<String> pendingIds,
    String deviceId,
  ) async {
    return {
      'operationId': item.operationId,
      'entityType': item.entityType,
      'action': item.action,
      'localId': item.localId,
      if (item.serverId != null) 'serverId': item.serverId,
      if (item.baseVersion != null) 'baseVersion': item.baseVersion,
      if (item.dependsOn.isNotEmpty)
        'dependsOn': item.dependsOn.where(pendingIds.contains).toList(),
      if (item.payload != null)
        'payload': await _transformPayload(item, deviceId: deviceId),
    };
  }

  Future<Map<String, dynamic>> _transformPayload(
    SyncQueueItem item, {
    required String deviceId,
  }) async {
    final payload = item.payload;
    if (payload == null) {
      return const <String, dynamic>{};
    }

    if (item.action != 'FINALIZE_VISITA') {
      return payload;
    }

    final diagnosticos = (payload['diagnosticos'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    final transformedDiagnosticos = <Map<String, dynamic>>[];
    for (final diagnostico in diagnosticos) {
      final next = Map<String, dynamic>.from(diagnostico)
        ..remove('imagePath')
        ..remove('clientAttachmentId');

      final imagePath = diagnostico['imagePath'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        final upload = await _uploadAttachment(
          deviceId: deviceId,
          clientAttachmentId:
              diagnostico['clientAttachmentId'] as String? ??
              _newClientAttachmentId(),
          imagePath: imagePath,
        );
        next['attachmentId'] = upload['attachmentId'];
      }

      transformedDiagnosticos.add(next);
    }

    return {
      'diagnosticos': transformedDiagnosticos,
      'encaminhamentos': payload['encaminhamentos'],
      if (payload['observacoesGerais'] != null)
        'observacoesGerais': payload['observacoesGerais'],
    };
  }

  Future<Map<String, dynamic>> _uploadAttachment({
    required String deviceId,
    required String clientAttachmentId,
    required String imagePath,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/sync/attachments',
      data: FormData.fromMap({
        'deviceId': deviceId,
        'clientAttachmentId': clientAttachmentId,
        'purpose': 'VISITA_DIAGNOSTICO',
        'arquivo': await MultipartFile.fromFile(imagePath),
      }),
    );

    return response.data as Map<String, dynamic>;
  }

  Future<void> _applySuccessfulResult(Map<String, dynamic> result) async {
    final action = result['action'] as String? ?? '';
    final operationId = result['operationId'] as String? ?? '';
    final serverId = _asInt(result['serverId']);
    final localId = result['localId'] as String?;
    final snapshot = result['snapshot'] as Map<String, dynamic>?;

    switch (action) {
      case 'CREATE_VISITA':
        if (snapshot != null && serverId != null) {
          final newLocalId = 'visita:$serverId';
          await _offlineDataService.upsertVisitSnapshot(
            snapshot,
            previousLocalId: localId,
            serverIdOverride: serverId,
          );
          if (localId != null) {
            await _offlineDataService.updateQueuedVisitReferences(
              previousLocalId: localId,
              newLocalId: newLocalId,
              serverId: serverId,
            );
          }
        }
        break;
      case 'UPDATE_VISITA':
      case 'FINALIZE_VISITA':
        if (snapshot != null) {
          await _offlineDataService.upsertVisitSnapshot(
            snapshot,
            previousLocalId: localId,
            serverIdOverride: serverId,
          );
        }
        break;
      case 'CONCLUDE_ENCAMINHAMENTO':
      case 'CANCEL_ENCAMINHAMENTO':
        if (snapshot != null) {
          await _offlineDataService.upsertEncaminhamentoSnapshot(snapshot);
        }
        break;
    }

    if (operationId.isNotEmpty) {
      await _offlineDataService.removeQueueOperation(operationId);
    }
  }

  Future<void> _applyServerChange(Map<String, dynamic> change) async {
    final entityType = change['entityType'] as String? ?? '';
    final changeType = change['changeType'] as String? ?? '';
    final entityId = _asInt(change['entityId']);
    final snapshot = change['snapshot'] as Map<String, dynamic>?;

    if (changeType == 'DELETE' && entityId != null) {
      switch (entityType) {
        case 'PROPRIEDADE':
          await _offlineDataService.deletePropriedadeByServerId(entityId);
          break;
        case 'VISITA':
          await _offlineDataService.deleteVisitByServerId(entityId);
          break;
        case 'ENCAMINHAMENTO':
          await _offlineDataService.deleteEncaminhamentoByServerId(entityId);
          break;
      }
      return;
    }

    if (snapshot == null) {
      return;
    }

    switch (entityType) {
      case 'USUARIO':
        await _offlineDataService.cacheCurrentUserProfile(snapshot);
        final userId = _asInt(snapshot['id']);
        final nome = snapshot['nome'] as String?;
        final tipo = snapshot['tipo'] as String?;
        if (userId != null && nome != null && tipo != null) {
          await _tokenService.saveUserIdentity(
            nome: nome,
            userId: userId,
            tipo: tipo,
          );
        }
        break;
      case 'PROPRIEDADE':
        await _offlineDataService.upsertPropriedadeSnapshot(snapshot);
        break;
      case 'VISITA':
        await _offlineDataService.upsertVisitSnapshot(snapshot);
        break;
      case 'ENCAMINHAMENTO':
        await _offlineDataService.upsertEncaminhamentoSnapshot(snapshot);
        break;
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _newClientAttachmentId() {
    return 'attachment-${DateTime.now().microsecondsSinceEpoch}';
  }
}
