import 'package:dio/dio.dart';

import '../models/page_response.dart';
import '../models/visita_detalhe_model.dart';
import '../models/visita_model.dart';
import 'api_client.dart';
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
  });

  final int propriedadeId;
  final DateTime dataVisita;
  final String horaVisita;
  final String tipoVisita;
  final String? temaPrincipal;
  final String? observacoes;
  final String? urgencia;

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
    };
  }
}

class DiagnosticoPayload {
  const DiagnosticoPayload({
    required this.categoria,
    required this.criticidade,
    required this.observacoes,
    this.imagemUrl,
  });

  final String categoria;
  final String criticidade;
  final String observacoes;
  final String? imagemUrl;

  Map<String, dynamic> toJson() {
    return {
      'categoria': categoria,
      'criticidade': criticidade,
      'observacoes': observacoes,
      ...?imagemUrl == null ? null : {'imagemUrl': imagemUrl},
    };
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
}

class VisitaService {
  VisitaService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;

  Future<List<VisitaModel>> listar({String? status, int size = 300}) async {
    final response = await _apiClient.dio.get(
      '/api/visitas',
      queryParameters: {
        'size': size,
        ...?status == null ? null : {'status': status},
      },
    );

    final page = PageResponse.fromJson(
      response.data as Map<String, dynamic>,
      VisitaModel.fromJson,
    );
    return page.content;
  }

  Future<int> contarTotal() async {
    final response = await _apiClient.dio.get(
      '/api/visitas',
      queryParameters: {'size': 1, 'page': 0},
    );
    return PageResponse.fromJson(
      response.data as Map<String, dynamic>,
      VisitaModel.fromJson,
    ).totalElements;
  }

  Future<VisitaModel> criar(SalvarVisitaRequest request) async {
    final response = await _apiClient.dio.post(
      '/api/visitas',
      data: request.toJson(),
    );
    return VisitaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<VisitaModel> atualizar(int id, SalvarVisitaRequest request) async {
    final response = await _apiClient.dio.put(
      '/api/visitas/$id',
      data: request.toJson(),
    );
    return VisitaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> cancelar(int id) async {
    await _apiClient.dio.delete('/api/visitas/$id');
  }

  Future<VisitaDetalheModel> buscarDetalhes(int id) async {
    final response = await _apiClient.dio.get('/api/visitas/$id/detalhes');
    return VisitaDetalheModel.fromJson(response.data as Map<String, dynamic>);
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
    final response = await _apiClient.dio.post(
      '/api/visitas/$id/finalizar',
      data: request.toJson(),
    );
    return VisitaModel.fromJson(response.data as Map<String, dynamic>);
  }
}
