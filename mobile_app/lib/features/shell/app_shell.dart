import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_refresh_bus.dart';
import '../../data/services/app_sync_service.dart';
import '../../data/services/token_service.dart';
import '../visita/agendamento_modal.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
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
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAdmin == false) {
      _refreshAppData(pullServerData: true);
    }
  }

  Future<void> _loadRole() async {
    final userInfo = await TokenService().getUserInfo();
    if (!mounted) {
      return;
    }
    final isAdmin = userInfo.tipo == 'ADMIN';
    setState(() => _isAdmin = isAdmin);
    if (!isAdmin) {
      await _refreshAppData(pullServerData: true);
    }
  }

  Future<void> _refreshAppData({required bool pullServerData}) async {
    if (_syncing) {
      return;
    }

    final syncService = AppSyncService.instance;
    final hasPending = await syncService.hasPendingOperations();
    final serverReachable = await syncService.isServerReachable();
    if (!hasPending && (!pullServerData || !serverReachable)) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _syncing = true);

    try {
      var changed = false;
      if (hasPending) {
        changed = await syncService.synchronizePending();
      }
      if (pullServerData && serverReachable) {
        changed = await syncService.primeEssentialData() || changed;
      }
      if (changed) {
        AppRefreshBus.notifyChanged();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Nao foi possivel sincronizar os dados pendentes.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/calendario')) return 1;
    if (location.startsWith('/encaminhamentos')) return 2;
    if (location.startsWith('/mais')) return 3;
    return 0;
  }

  Future<void> _onTabTap(int index) async {
    await _refreshAppData(pullServerData: false);
    if (!mounted) {
      return;
    }
    context.go(_tabs[index].path);
  }

  Future<void> _onFabTap() async {
    await _refreshAppData(pullServerData: false);
    if (!mounted) {
      return;
    }
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
      body: Stack(
        children: [
          widget.child,
          if (_syncing)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Atualizando dados do app',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aguarde enquanto carregamos os dados mais recentes e enviamos o que ficou salvo offline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _Fab(onTap: _onFabTap),
      bottomNavigationBar: _NavBar(
        selectedIndex: selectedIndex,
        tabs: _tabs,
        onTap: _onTabTap,
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
