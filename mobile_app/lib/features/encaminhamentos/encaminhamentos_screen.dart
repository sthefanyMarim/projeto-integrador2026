import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_screen.dart';

class EncaminhamentosScreen extends StatefulWidget {
  const EncaminhamentosScreen({super.key});

  @override
  State<EncaminhamentosScreen> createState() => _EncaminhamentosScreenState();
}

class _EncaminhamentosScreenState extends State<EncaminhamentosScreen> {
  static const _filters = ['Todos', 'Pendentes', 'Concluídos', 'Atrasados'];
  String _selectedFilter = 'Todos';

  static const _tasks = [
    _TaskData(
      title: 'Sítio Santa Rosa',
      visitDate: 'Visita 08/04/2026',
      description: 'Aplicação de inseticida sistêmico nas próximas 48h',
      priority: 'Alta',
      status: 'Pendente',
      statusColor: AppColors.error,
      deadline: 'Prazo: 15/04/2026',
    ),
    _TaskData(
      title: 'Chácara Esperança',
      visitDate: 'Visita 08/04/2026',
      description: 'Retirada e descarte das plantas com murcha bacteriana',
      priority: 'Alta',
      status: 'Atrasado',
      statusColor: AppColors.error,
      deadline: 'Prazo: 12/04/2026',
    ),
    _TaskData(
      title: 'Sítio São Luís',
      visitDate: 'Visita 01/04/2026',
      description: 'Melhoria da drenagem',
      priority: 'Média',
      status: 'Pendente',
      statusColor: AppColors.warning,
      deadline: 'Prazo: 20/04/2026',
    ),
    _TaskData(
      title: 'Sítio Felicidade',
      visitDate: 'Visita 08/04/2026',
      description: 'Ligar para Feirante.',
      priority: 'Média',
      status: 'Concluído',
      statusColor: AppColors.success,
      deadline: 'Prazo: 09/04/2026',
      completed: true,
    ),
  ];

  List<_TaskData> get _filteredTasks {
    if (_selectedFilter == 'Todos') return _tasks;
    return _tasks.where((task) {
      if (_selectedFilter == 'Pendentes') return task.status == 'Pendente';
      if (_selectedFilter == 'Concluídos') return task.status == 'Concluído';
      if (_selectedFilter == 'Atrasados') return task.status == 'Atrasado';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      safeAreaBottom: false,
      backgroundColor: AppColors.background,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterBar(),
                    const SizedBox(height: 20),
                    ..._filteredTasks.map(_buildTaskCard),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.maybePop(context),
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
                ),
              const Text(
                'Encaminhamentos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Acompanhe e finalize as pendências',
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _filters.map((filter) {
          final isActive = filter == _selectedFilter;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                margin: EdgeInsets.only(left: filter == _filters.first ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(_TaskData task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.visitDate,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  task.deadline,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusChip(task.priority, AppColors.warning),
                const SizedBox(width: 8),
                _buildStatusChip(task.status, task.statusColor),
                const Spacer(),
                if (!task.completed) ...[
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Concluir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                if (task.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Concluído',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaskData {
  const _TaskData({
    required this.title,
    required this.visitDate,
    required this.description,
    required this.priority,
    required this.status,
    required this.statusColor,
    required this.deadline,
    this.completed = false,
  });

  final String title;
  final String visitDate;
  final String description;
  final String priority;
  final String status;
  final Color statusColor;
  final String deadline;
  final bool completed;
}
