import 'package:dio/dio.dart';

import '../models/page_response.dart';
import '../models/visita_detalhe_model.dart';
import '../models/visita_model.dart';
import 'api_client.dart';
import 'network_service.dart';
import 'offline_data_service.dart';
import 'token_service.dart';

class SalvarVisitaRequest {
  const SalvarVisitaRequest({
    required this.propriedadeId,
    required this.dataVisita,
    required this.horaVisita,
    required this.tipoVisita,
    this.temaPrincipal,
    this.observacoes,
    this.urgencia,
    this.baseVersion,
  });

  final int propriedadeId;
  final DateTime dataVisita;
  final String horaVisita;
  final String tipoVisita;
  final String? temaPrincipal;
  final String? observacoes;
  final String? urgencia;
  final int? baseVersion;

  Map<String, dynamic> toJson() {
    final month = dataVisita.month.toString().padLeft(2, '0');
    final day = dataVisita.day.toString().padLeft(2, '0');

    return {
      'propriedadeId': propriedadeId,
      'dataVisita': '${dataVisita.year}-$month-$day',
      'horaVisita': horaVisita,
      'tipoVisita': tipoVisita,
      ...?temaPrincipal == null ? null : {'temaPrincipal': temaPrincipal},
      ...?observacoes == null ? null : {'observacoes': observacoes},
      ...?urgencia == null ? null : {'urgencia': urgencia},
      ...?baseVersion == null ? null : {'baseVersion': baseVersion},
    };
  }

  Map<String, dynamic> toSyncPayload() => toJson();
}

class DiagnosticoPayload {
  const DiagnosticoPayload({
    required this.categoria,
    required this.criticidade,
    required this.observacoes,
    this.imagemUrl,
    this.imagePath,
  });

  final String categoria;
  final String criticidade;
  final String observacoes;
  final String? imagemUrl;
  final String? imagePath;

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria,
      'criticidade': criticidade,
      'observacoes': observacoes,
      ...?imagemUrl == null ? null : {'imagemUrl': imagemUrl},
    };
  }

  Map<String, dynamic> toSyncJson() {
    return {
      'categoria': categoria,
      'criticidade': criticidade,
      'observacoes': observacoes,
      ...?imagemUrl == null ? null : {'imagemUrl': imagemUrl},
      ...?imagePath == null ? null : {'imagePath': imagePath},
    };
  }

  DiagnosticoPayload copyWith({String? imagemUrl}) {
    return DiagnosticoPayload(
      categoria: categoria,
      criticidade: criticidade,
      observacoes: observacoes,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      imagePath: imagePath,
    );
  }
}

class EncaminhamentoPayload {
  const EncaminhamentoPayload({
    required this.acaoRealizada,
    this.responsavel,
    this.prazo,
    this.verificacao,
    required this.prioridade,
  });

  final String acaoRealizada;
  final String? responsavel;
  final DateTime? prazo;
  final String? verificacao;
  final String prioridade;

  Map<String, dynamic> toJson() {
    String? prazoFormatado;
    if (prazo != null) {
      final month = prazo!.month.toString().padLeft(2, '0');
      final day = prazo!.day.toString().padLeft(2, '0');
      prazoFormatado = '${prazo!.year}-$month-$day';
    }

    return {
      'acaoRealizada': acaoRealizada,
      ...?responsavel == null ? null : {'responsavel': responsavel},
      ...?prazoFormatado == null ? null : {'prazo': prazoFormatado},
      ...?verificacao == null ? null : {'verificacao': verificacao},
      'prioridade': prioridade,
    };
  }
}

class FinalizarVisitaRequest {
  const FinalizarVisitaRequest({
    required this.diagnosticos,
    required this.encaminhamentos,
    this.observacoesGerais,
  });

  final List<DiagnosticoPayload> diagnosticos;
  final List<EncaminhamentoPayload> encaminhamentos;
  final String? observacoesGerais;

  Map<String, dynamic> toJson() {
    return {
      'diagnosticos': diagnosticos.map((item) => item.toJson()).toList(),
      'encaminhamentos': encaminhamentos.map((item) => item.toJson()).toList(),
      ...?observacoesGerais == null
          ? null
          : {'observacoesGerais': observacoesGerais},
    };
  }

  Map<String, dynamic> toSyncPayload() {
    return {
      'diagnosticos': diagnosticos.map((item) => item.toSyncJson()).toList(),
      'encaminhamentos': encaminhamentos.map((item) => item.toJson()).toList(),
      ...?observacoesGerais == null
          ? null
          : {'observacoesGerais': observacoesGerais},
    };
  }
}

class VisitaService {
  VisitaService(TokenService tokenService)
    : _tokenService = tokenService,
      _apiClient = ApiClient(tokenService);

  final TokenService _tokenService;
  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService = OfflineDataService.instance;

  Future<List<VisitaModel>> listar({String? status, int size = 300}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/visitas',
        queryParameters: {
          'size': size,
          ...?status == null ? null : {'status': status},
        },
      );

      final rawPage = response.data as Map<String, dynamic>;
      final rawContent = (rawPage['content'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      await _offlineDataService.cacheVisitas(rawContent);
      return _offlineDataService.readCachedVisitas(status: status);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      return _offlineDataService.readCachedVisitas(status: status);
    }
  }

  Future<int> contarTotal() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/visitas',
        queryParameters: {'size': 1, 'page': 0},
      );
      return PageResponse.fromJson(
        response.data as Map<String, dynamic>,
        VisitaModel.fromJson,
      ).totalElements;
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      return _offlineDataService.countCachedVisitas();
    }
  }

  Future<VisitaModel> criar(SalvarVisitaRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/visitas',
        data: request.toJson(),
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.upsertVisitSnapshot(raw);
      return VisitaModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }

      final propriedade = await _offlineDataService.findCachedPropriedade(
        request.propriedadeId,
      );
      if (propriedade == null) {
        throw StateError(
          'Nenhuma propriedade ativa foi encontrada no cache local para agendar a visita offline.',
        );
      }

      final userInfo = await _tokenService.getUserInfo();
      return _offlineDataService.saveOfflineCreatedVisit(
        payload: request.toSyncPayload(),
        usuarioId: userInfo.userId ?? 0,
        usuarioNome: userInfo.nome ?? 'Usuário logado',
        propriedade: propriedade,
      );
    }
  }

  Future<VisitaModel> atualizar(int id, SalvarVisitaRequest request) async {
    if (id <= 0) {
      final propriedade = await _offlineDataService.findCachedPropriedade(
        request.propriedadeId,
      );
      return _offlineDataService.saveOfflineUpdatedVisit(
        visitId: id,
        payload: request.toSyncPayload(),
        propriedade: propriedade,
      );
    }

    try {
      final response = await _apiClient.dio.put(
        '/api/visitas/$id',
        data: request.toJson(),
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.upsertVisitSnapshot(raw);
      return VisitaModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }

      final propriedade = await _offlineDataService.findCachedPropriedade(
        request.propriedadeId,
      );
      return _offlineDataService.saveOfflineUpdatedVisit(
        visitId: id,
        payload: request.toSyncPayload(),
        propriedade: propriedade,
      );
    }
  }

  Future<void> cancelar(int id) async {
    await _apiClient.dio.delete('/api/visitas/$id');
    await _offlineDataService.updateCachedVisitaStatus(id, 'CANCELADA');
  }

  Future<VisitaDetalheModel> buscarDetalhes(int id) async {
    if (id <= 0) {
      final cached = await _offlineDataService.findCachedVisitDetail(id);
      if (cached != null) {
        return cached;
      }
      throw StateError(
        'Os detalhes desta visita ainda estao disponiveis apenas no dispositivo.',
      );
    }

    try {
      final response = await _apiClient.dio.get('/api/visitas/$id/detalhes');
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.upsertVisitSnapshot(raw);
      return VisitaDetalheModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }

      final cached = await _offlineDataService.findCachedVisitDetail(id);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<String> uploadDiagnosticoImagem(int visitaId, String imagePath) async {
    final formData = FormData.fromMap({
      'arquivo': await MultipartFile.fromFile(imagePath),
    });
    final response = await _apiClient.dio.post(
      '/api/imagens/visita/$visitaId',
      data: formData,
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }

  Future<VisitaModel> finalizar(int id, FinalizarVisitaRequest request) async {
    if (id <= 0) {
      return _offlineDataService.saveOfflineFinalizedVisit(
        visitId: id,
        syncPayload: request.toSyncPayload(),
      );
    }

    try {
      final onlineRequest = await _prepareFinalizarRequest(id, request);
      final response = await _apiClient.dio.post(
        '/api/visitas/$id/finalizar',
        data: onlineRequest.toJson(),
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _cacheFinalizedVisitDetails(
        visitId: id,
        visitSnapshot: raw,
        request: onlineRequest,
      );
      return VisitaModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }

      return _offlineDataService.saveOfflineFinalizedVisit(
        visitId: id,
        syncPayload: request.toSyncPayload(),
      );
    }
  }

  Future<FinalizarVisitaRequest> _prepareFinalizarRequest(
    int visitId,
    FinalizarVisitaRequest request,
  ) async {
    final diagnosticos = <DiagnosticoPayload>[];
    for (final diagnostico in request.diagnosticos) {
      if (diagnostico.imagePath == null || diagnostico.imagePath!.isEmpty) {
        diagnosticos.add(diagnostico);
        continue;
      }

      final imageUrl = await uploadDiagnosticoImagem(
        visitId,
        diagnostico.imagePath!,
      );
      diagnosticos.add(diagnostico.copyWith(imagemUrl: imageUrl));
    }

    return FinalizarVisitaRequest(
      diagnosticos: diagnosticos,
      encaminhamentos: request.encaminhamentos,
      observacoesGerais: request.observacoesGerais,
    );
  }

  Future<void> _cacheFinalizedVisitDetails({
    required int visitId,
    required Map<String, dynamic> visitSnapshot,
    required FinalizarVisitaRequest request,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/visitas/$visitId/detalhes',
      );
      final raw = Map<String, dynamic>.from(response.data as Map);
      await _offlineDataService.upsertVisitSnapshot(raw);
      return;
    } catch (_) {
      final enriched = Map<String, dynamic>.from(visitSnapshot);
      if (request.observacoesGerais != null &&
          request.observacoesGerais!.trim().isNotEmpty) {
        enriched['observacoes'] = request.observacoesGerais;
      }
      enriched['diagnosticos'] = List.generate(request.diagnosticos.length, (
        index,
      ) {
        final item = request.diagnosticos[index];
        return {
          'id': -((visitId.abs() * 1000) + index + 1),
          'categoria': item.categoria,
          'criticidade': item.criticidade,
          'observacoes': item.observacoes,
          if (item.imagemUrl != null) 'imagemUrl': item.imagemUrl,
        };
      });
      enriched['encaminhamentos'] = List.generate(
        request.encaminhamentos.length,
        (index) {
          final item = request.encaminhamentos[index];
          return {
            'id': -((visitId.abs() * 1000) + index + 1),
            'acaoRealizada': item.acaoRealizada,
            'prioridade': item.prioridade,
            'status': 'PENDENTE',
            'responsavel': item.responsavel,
            'prazo': item.prazo == null ? null : _dateForApi(item.prazo!),
            'verificacao': item.verificacao,
          };
        },
      );
      await _offlineDataService.upsertVisitSnapshot(enriched);
    }
  }

  String _dateForApi(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
