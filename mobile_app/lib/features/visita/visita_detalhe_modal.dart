import 'package:flutter/material.dart';

import '../../core/api_error_dialog.dart';
import '../../core/app_colors.dart';
import '../../core/env.dart';
import '../../data/models/visita_detalhe_model.dart';
import '../../data/models/visita_model.dart';
import '../../data/services/token_service.dart';
import '../../data/services/visita_service.dart';
import 'visita_form_options.dart';

class VisitaDetalheModal extends StatefulWidget {
  const VisitaDetalheModal({super.key, required this.visit});

  final VisitaModel visit;

  @override
  State<VisitaDetalheModal> createState() => _VisitaDetalheModalState();
}

class _VisitaDetalheModalState extends State<VisitaDetalheModal> {
  late final VisitaService _service;
  late final Future<VisitaDetalheModel> _future;

  @override
  void initState() {
    super.initState();
    _service = VisitaService(TokenService());
    _future = _service.buscarDetalhes(widget.visit.id);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  Color _statusColor(String status) => switch (status) {
    'CONCLUIDA' => AppColors.success,
    'CANCELADA' => AppColors.textMuted,
    'ATRASADA' => AppColors.error,
    _ => AppColors.primary,
  };

  String _statusLabel(String status) => switch (status) {
    'CONCLUIDA' => 'ConcluÃ­da',
    'CANCELADA' => 'Cancelada',
    'ATRASADA' => 'Atrasada',
    _ => 'Pendente',
  };

  Color _urgenciaColor(String urgencia) => switch (urgencia) {
    'CRITICA' => AppColors.error,
    'ALTA' => AppColors.warning,
    'MEDIA' => AppColors.info,
    _ => AppColors.success,
  };

  Color _criticidadeColor(String value) => switch (value) {
    'CRITICA' => AppColors.error,
    'ALTA' => AppColors.warning,
    'MEDIA' => AppColors.info,
    _ => AppColors.success,
  };

  Color _criticidadeBackground(String value) => switch (value) {
    'CRITICA' => AppColors.errorSurface,
    'ALTA' => AppColors.warningSurface,
    'MEDIA' => AppColors.infoSurface,
    _ => AppColors.successSurface,
  };

  Color _prioridadeColor(String value) => switch (value) {
    'CRITICA' => AppColors.error,
    'ALTA' => AppColors.warning,
    'MEDIA' => AppColors.info,
    _ => AppColors.success,
  };

  Color _prioridadeBackground(String value) => switch (value) {
    'CRITICA' => AppColors.errorSurface,
    'ALTA' => AppColors.warningSurface,
    'MEDIA' => AppColors.infoSurface,
    _ => AppColors.successSurface,
  };

  Color _encStatusColor(String status) => switch (status) {
    'CONCLUIDO' => AppColors.success,
    'VENCIDO' => AppColors.error,
    _ => AppColors.info,
  };

  String _encStatusLabel(String status) => switch (status) {
    'CONCLUIDO' => 'ConcluÃ­do',
    'VENCIDO' => 'Vencido',
    _ => 'Pendente',
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(
                child: FutureBuilder<VisitaDetalheModel>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _buildError(snapshot.error!);
                    }
                    return _buildBody(scrollController, snapshot.data!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final visit = widget.visit;
    final statusColor = _statusColor(visit.statusVisita);
    final urgenciaColor = _urgenciaColor(visit.urgencia);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visit.propriedadeNome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDate(visit.dataVisita)}  â€¢  ${visit.horaCurta}',
            style: const TextStyle(
              color: AppColors.headerSubtitle,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _headerChip(_statusLabel(visit.statusVisita), statusColor),
              const SizedBox(width: 8),
              _headerChip(
                optionLabel(urgenciaOptions, visit.urgencia),
                urgenciaColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Nao foi possivel carregar os detalhes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ApiErrorDialog.show(
                context,
                error,
                title: 'Erro ao carregar detalhes',
                fallback: 'Nao foi possivel carregar os detalhes da visita.',
              ),
              child: const Text('Ver erro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController controller, VisitaDetalheModel detalhe) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildResumoCard(detalhe),
        const SizedBox(height: 12),
        _buildDiagnosticosSection(detalhe.diagnosticos),
        const SizedBox(height: 12),
        _buildEncaminhamentosSection(detalhe.encaminhamentos),
      ],
    );
  }

  Widget _buildResumoCard(VisitaDetalheModel detalhe) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Resumo TÃ©cnico', Icons.summarize_outlined),
          const SizedBox(height: 14),
          _infoRow(Icons.person_outline, 'TÃ©cnico', detalhe.usuarioNome),
          if (detalhe.tipoVisita != null) ...[
            const SizedBox(height: 10),
            _infoRow(
              Icons.category_outlined,
              'Tipo de visita',
              optionLabel(
                tipoVisitaOptions,
                detalhe.tipoVisita,
                fallback: detalhe.tipoVisita ?? '',
              ),
            ),
          ],
          if (detalhe.temaPrincipal != null &&
              detalhe.temaPrincipal!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              Icons.topic_outlined,
              'Tema principal',
              detalhe.temaPrincipal!,
            ),
          ],
          if (detalhe.observacoes != null &&
              detalhe.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _label('ObservaÃ§Ãµes gerais'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                detalhe.observacoes!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticosSection(List<DiagnosticoResumado> items) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'DiagnÃ³sticos',
                  Icons.medical_services_outlined,
                ),
              ),
              _countBadge(items.length),
            ],
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Nenhum diagnÃ³stico registrado.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            ...items.map(_buildDiagnosticoCard),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagnosticoCard(DiagnosticoResumado item) {
    final color = _criticidadeColor(item.criticidade);
    final background = _criticidadeBackground(item.criticidade);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.categoria,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            optionLabel(criticidadeOptions, item.criticidade),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.observacoes != null &&
                        item.observacoes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.observacoes!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (item.imagemUrl != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          Env.rewriteMediaUrl(item.imagemUrl!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 180,
                              color: AppColors.grey100,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              color: AppColors.grey100,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Imagem indisponÃ­vel',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncaminhamentosSection(List<EncaminhamentoResumado> items) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'Encaminhamentos',
                  Icons.assignment_outlined,
                ),
              ),
              _countBadge(items.length),
            ],
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Nenhum encaminhamento registrado.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            ...items.map(_buildEncaminhamentoCard),
          ],
        ],
      ),
    );
  }

  Widget _buildEncaminhamentoCard(EncaminhamentoResumado item) {
    final color = _prioridadeColor(item.prioridade);
    final background = _prioridadeBackground(item.prioridade);
    final statusColor = _encStatusColor(item.status);
    final prazoLabel = item.prazo == null
        ? 'Sem prazo'
        : _formatDate(item.prazo!);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.acaoRealizada,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            optionLabel(prioridadeOptions, item.prioridade),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _iconRow(
                      Icons.person_outline,
                      item.responsavel ?? 'ResponsÃ¡vel nÃ£o informado',
                    ),
                    const SizedBox(height: 4),
                    _iconRow(Icons.calendar_today_outlined, prazoLabel),
                    if (item.verificacao != null) ...[
                      const SizedBox(height: 4),
                      _iconRow(
                        Icons.fact_check_outlined,
                        optionLabel(
                          verificacaoOptions,
                          item.verificacao,
                          fallback: item.verificacao ?? '',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _encStatusLabel(item.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _countBadge(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
