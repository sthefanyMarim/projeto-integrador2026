import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../data/services/token_service.dart';
import '../visita/agendamento_modal.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [
    _NavTab(
      path: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Início',
    ),
    _NavTab(
      path: '/calendario',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Calendário',
    ),
    _NavTab(
      path: '/encaminhamentos',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Pendências',
    ),
    _NavTab(
      path: '/mais',
      icon: Icons.more_horiz,
      activeIcon: Icons.more_horiz,
      label: 'Mais',
    ),
  ];

  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final userInfo = await TokenService().getUserInfo();
    if (!mounted) {
      return;
    }
    setState(() => _isAdmin = userInfo.tipo == 'ADMIN');
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/calendario')) return 1;
    if (location.startsWith('/encaminhamentos')) return 2;
    if (location.startsWith('/mais')) return 3;
    return 0;
  }

  void _onTabTap(BuildContext context, int index) {
    context.go(_tabs[index].path);
  }

  void _onFabTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AgendamentoModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == true || _isAdmin == null) {
      return Scaffold(body: widget.child);
    }

    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _indexFromLocation(location);

    return Scaffold(
      body: widget.child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _Fab(onTap: () => _onFabTap(context)),
      bottomNavigationBar: _NavBar(
        selectedIndex: selectedIndex,
        tabs: _tabs,
        onTap: (i) => _onTabTap(context, i),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  final int selectedIndex;
  final List<_NavTab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 72 + bottomPadding,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 72,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    tab: tabs[0],
                    selected: selectedIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    tab: tabs[1],
                    selected: selectedIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
                const SizedBox(width: 72),
                Expanded(
                  child: _NavItem(
                    tab: tabs[2],
                    selected: selectedIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    tab: tabs[3],
                    selected: selectedIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF00AE56) : AppColors.textHint;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? tab.activeIcon : tab.icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
