import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_screen.dart';
import '../../data/models/propriedade_model.dart';

class PropriedadePerfilScreen extends StatelessWidget {
  const PropriedadePerfilScreen({super.key, required this.propriedade});

  final PropriedadeModel propriedade;

  @override
  Widget build(BuildContext context) {
    final p = propriedade;
    final initials = _initials(p.nome);
    final bgColor = _avatarBgColor(p.nome);
    final textColor = _avatarTextColor(p.nome);
    final hasGps = p.latitude != null && p.longitude != null;

    return AppScreen(
      safeAreaTop: false,
      safeAreaBottom: true,
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, p, initials, bgColor, textColor),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('FEIRANTE / RESPONSÁVEL'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Nome do Responsável',
                      value: p.nomeProprietario.isNotEmpty
                          ? p.nomeProprietario
                          : '—',
                    ),
                    if (p.telefone != null && p.telefone!.isNotEmpty) ...[
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Telefone de Contato',
                        value: p.telefone!,
                      ),
                      _InfoRow(
                        icon: Icons.chat_outlined,
                        label: 'WhatsApp',
                        value: p.telefone!,
                      ),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  _sectionLabel('LOCALIZAÇÃO'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _InfoRow(
                      label: 'Endereço',
                      value: (p.endereco != null && p.endereco!.isNotEmpty)
                          ? p.endereco!
                          : 'Não informado',
                    ),
                    _InfoRow(
                      label: 'Município / Estado',
                      value: _municipioEstado(p),
                    ),
                    if (hasGps)
                      _InfoRow(
                        label: 'Coordenadas GPS',
                        value:
                            'Lat: ${p.latitude!.toStringAsFixed(4)}  ·  Long: ${p.longitude!.toStringAsFixed(4)}',
                      ),
                  ]),
                  if (hasGps) ...[
                    const SizedBox(height: 8),
                    _mapButton(p.latitude!, p.longitude!),
                  ],
                  const SizedBox(height: 16),
                  _sectionLabel('SOBRE A PROPRIEDADE'),
                  const SizedBox(height: 8),
                  _infoCard([
                    if (p.criadoEm != null)
                      _InfoRow(
                        label: 'Cadastrada em',
                        value: _formatDate(p.criadoEm!),
                      ),
                    _InfoRow(
                      label: 'Status',
                      value: p.ativa
                          ? 'Ativa — disponível para visitas'
                          : 'Inativa — fora de operação',
                    ),
                    if (p.tipoProducao != null && p.tipoProducao!.isNotEmpty)
                      _InfoRow(
                        label: 'Tipo de Produção',
                        value: p.tipoProducao!,
                      ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    PropriedadeModel p,
    String initials,
    Color bgColor,
    Color textColor,
  ) {
    final dateStr = p.criadoEm != null ? _formatDateShort(p.criadoEm!) : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Perfil da Propriedade',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                p.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ID #${p.id}',
                    style: const TextStyle(
                      color: Color(0xFFB2E5CC),
                      fontSize: 10,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '·',
                      style: TextStyle(color: Color(0xFFB2E5CC), fontSize: 10),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.ativa
                          ? const Color(0xFFE0FAEB)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.ativa ? '● Ativa' : '● Inativa',
                      style: TextStyle(
                        color: p.ativa
                            ? const Color(0xFF00AE56)
                            : AppColors.textHint,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (dateStr != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '·',
                        style: TextStyle(
                          color: Color(0xFFB2E5CC),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFFB2E5CC),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapButton(double lat, double lng) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, size: 16, color: Color(0xFF00AE56)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Ver no mapa →',
                style: TextStyle(
                  color: Color(0xFF00AE56),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFA6A6A6),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _infoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final row = entry.value;
          final isLast = entry.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (row.icon != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          row.icon,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              color: Color(0xFFA6A6A6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            row.value,
                            style: const TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  color: Color(0xFFF5F5F5),
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _municipioEstado(PropriedadeModel p) {
    final parts = [
      if (p.municipio != null && p.municipio!.isNotEmpty) p.municipio!,
      if (p.estado != null && p.estado!.isNotEmpty) p.estado!,
    ];
    return parts.isEmpty ? 'Não informado' : parts.join(' — ');
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Color _avatarBgColor(String name) {
    const palette = [
      Color(0xFFE0FAEB),
      Color(0xFFFAE5F5),
      Color(0xFFDBEDF7),
      Color(0xFFFCF5DB),
      Color(0xFFF5F5F5),
    ];
    final hash = name.codeUnits.fold(0, (a, c) => a + c);
    return palette[hash % palette.length];
  }

  Color _avatarTextColor(String name) {
    const palette = [
      Color(0xFF006A18),
      Color(0xFF9C2678),
      Color(0xFF2980BA),
      Color(0xFF996B0F),
      Color(0xFFCCCCCC),
    ];
    final hash = name.codeUnits.fold(0, (a, c) => a + c);
    return palette[hash % palette.length];
  }
}

class _InfoRow {
  const _InfoRow({this.icon, required this.label, required this.value});
  final IconData? icon;
  final String label;
  final String value;
}
