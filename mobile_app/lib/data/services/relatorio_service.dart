import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/propriedade_model.dart';
import '../models/relatorio_model.dart';
import 'api_client.dart';
import 'propriedade_service.dart';
import 'token_service.dart';

class RelatorioPeriodo {
  const RelatorioPeriodo({required this.label, required this.inicio, required this.fim});
  final String label;
  final DateTime inicio;
  final DateTime fim;

  static List<RelatorioPeriodo> opcoesPadrao() {
    final hoje = DateTime.now();
    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    return [
      RelatorioPeriodo(label: 'Mes atual', inicio: inicioMes, fim: hoje),
      RelatorioPeriodo(label: 'Ultimos 3 meses', inicio: hoje.subtract(const Duration(days: 90)), fim: hoje),
      RelatorioPeriodo(label: 'Ultimos 6 meses', inicio: hoje.subtract(const Duration(days: 180)), fim: hoje),
      RelatorioPeriodo(label: 'Ultimo ano', inicio: hoje.subtract(const Duration(days: 365)), fim: hoje),
    ];
  }

  String get inicioParam => _fmt(inicio);
  String get fimParam => _fmt(fim);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class RelatorioService {
  RelatorioService(TokenService tokenService)
      : _apiClient = ApiClient(tokenService),
        _propriedadeService = PropriedadeService(tokenService);

  final ApiClient _apiClient;
  final PropriedadeService _propriedadeService;

  Future<List<PropriedadeModel>> listarPropriedades() =>
      _propriedadeService.listarAtivas();

  Future<RelatorioGeralModel> buscarGeral(RelatorioPeriodo periodo) async {
    final response = await _apiClient.dio.get(
      '/api/relatorios/geral',
      queryParameters: {'inicio': periodo.inicioParam, 'fim': periodo.fimParam},
    );
    return RelatorioGeralModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RelatorioPropriedadeModel> buscarPropriedade(
      int propriedadeId, RelatorioPeriodo periodo) async {
    final response = await _apiClient.dio.get(
      '/api/relatorios/propriedade/$propriedadeId',
      queryParameters: {'inicio': periodo.inicioParam, 'fim': periodo.fimParam},
    );
    return RelatorioPropriedadeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> exportarGeralPdf(RelatorioPeriodo periodo) async {
    final response = await _apiClient.dio.get<List<int>>(
      '/api/relatorios/geral/pdf',
      queryParameters: {'inicio': periodo.inicioParam, 'fim': periodo.fimParam},
      options: Options(responseType: ResponseType.bytes),
    );
    await _salvarECompartilhar(
      bytes: response.data!,
      filename: 'relatorio-geral-${periodo.inicioParam}.pdf',
    );
  }

  Future<void> exportarPropriedadePdf(int propriedadeId, RelatorioPeriodo periodo) async {
    final response = await _apiClient.dio.get<List<int>>(
      '/api/relatorios/propriedade/$propriedadeId/pdf',
      queryParameters: {'inicio': periodo.inicioParam, 'fim': periodo.fimParam},
      options: Options(responseType: ResponseType.bytes),
    );
    await _salvarECompartilhar(
      bytes: response.data!,
      filename: 'relatorio-propriedade-${periodo.inicioParam}.pdf',
    );
  }

  Future<void> _salvarECompartilhar({required List<int> bytes, required String filename}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatorio PoliVisitas');
  }
}
