import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _metricCards = [
    _MetricCardData(
      value: '12',
      label: 'Propriedades',
      color: AppColors.primary,
    ),
    _MetricCardData(value: '3', label: 'Atrasadas', color: AppColors.error),
    _MetricCardData(value: '5', label: 'Pendências', color: AppColors.warning),
  ];

  static const _visitasHoje = [
    _VisitCardData(
      title: 'Sítio Santa Rosa',
      time: '08:30',
      status: 'Concluída',
      statusColor: AppColors.success,
      stripeColor: AppColors.primary,
    ),
    _VisitCardData(
      title: 'Chácara Esperança',
      time: '10:00',
      status: 'Pendente',
      statusColor: AppColors.error,
      stripeColor: AppColors.error,
    ),
    _VisitCardData(
      title: 'Fazenda Bela Vista',
      time: '14:00',
      status: 'Pendente',
      statusColor: AppColors.error,
      stripeColor: AppColors.error,
    ),
  ];

  static const _pendenciasUrgentes = [
    _PendingCardData(title: 'Praga em Sítio Santa Rosa', level: 'Alta'),
    _PendingCardData(title: 'Solo degradado — Chácara Leme', level: 'Média'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaBottom: false, // Shell cuida do espaço da navbar
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildMetricCards(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Visitas de Hoje', 'Ver todas'),
                  const SizedBox(height: 12),
                  ..._visitasHoje.map(_buildVisitCard),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Pendências Urgentes', 'Ver todas'),
                  const SizedBox(height: 12),
                  ..._pendenciasUrgentes.map(_buildPendingCard),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Técnico/Bolsista',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Meu Dia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Quarta, 8 de Abril',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.headerSubtitle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return Row(
      children: _metricCards.map((card) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: card == _metricCards.first ? 0 : 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: card.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildVisitCard(_VisitCardData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 84,
            decoration: BoxDecoration(
              color: data.stripeColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        data.time,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: data.statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          data.status,
                          style: TextStyle(
                            color: data.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(_PendingCardData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.level,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data.level,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;
}

class _VisitCardData {
  const _VisitCardData({
    required this.title,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.stripeColor,
  });

  final String title;
  final String time;
  final String status;
  final Color statusColor;
  final Color stripeColor;
}

class _PendingCardData {
  const _PendingCardData({required this.title, required this.level});

  final String title;
  final String level;
}
