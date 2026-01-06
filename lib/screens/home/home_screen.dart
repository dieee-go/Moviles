import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../components/skeletons.dart';
import '../../components/custom_app_bar.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';
import '../admin/admin_panel_screen.dart';
import '../events/calendar_screen.dart';
import '../events/explore_events_screen.dart';
import '../events/my_events_screen.dart';
import '../events/my_registrations_screen.dart';
import 'inicio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _userRole;
  bool _loadingRole = true;
  String? _userPhotoUrl;
  String? _userName;

  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _updateStatusBarStyle() {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBarStyle();
    _updateStatusBarStyle();
  }

  Future<void> _loadUserRole() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await supabase
            .from('profiles')
            .select('role, avatar_url, nombre, primer_apellido')
            .eq('id', userId)
            .single();
        
        final role = (data['role'] as String?)?.trim().toLowerCase();
        final nombre = data['nombre'] as String?;
        final apellido = data['primer_apellido'] as String?;
        
        setState(() {
          _userRole = role;
          _userPhotoUrl = data['avatar_url'] as String?;
          _userName = nombre ?? apellido ?? 'Usuario';
          _loadingRole = false;
          _setupNavigation(role);
        });
      } else {
        setState(() {
          _loadingRole = false;
          _setupNavigation(null);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user role: $e');
      setState(() {
        _loadingRole = false;
        _setupNavigation(null);
      });
    }
  }

  void _setupNavigation(String? role) {
    if (role == 'admin') {
      _pages = [
        InicioScreen(),
        ExploreEventsScreen(),
        AdminPanelScreen(),
        const CalendarScreen(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
      ];
    } else if (role == 'organizer') {
      _pages = [
        InicioScreen(),
        ExploreEventsScreen(),
        MyEventsScreen(key: MyEventsScreen.globalKey),
        const CalendarScreen(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mis Eventos'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
      ];
    } else {
      // Estudiante o sin rol
      _pages = [
        InicioScreen(),
        ExploreEventsScreen(),
        MyRegistrationsScreen(),
        const CalendarScreen(),
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.event_available), label: 'Registros'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
      ];
    }
  }

  void _onFabPressed() {
    if (_userRole == 'organizer' || _userRole == 'admin') {
      Navigator.pushNamed(context, '/create-event').then((_) {
        // Recargar lista de eventos cuando regresa
        MyEventsScreen.globalKey.currentState?.reloadEvents();
      });
    } else {
      // Escanear QR para estudiantes
      Navigator.pushNamed(context, '/qr-scan');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Scaffold _buildHomeSkeleton() {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 65),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeletons.box(width: 160, height: 20, radius: 8),
                const SizedBox(height: 12),
                Skeletons.box(width: 220, height: 16, radius: 8),
                const SizedBox(height: 24),
                Skeletons.listTiles(count: 2, leadingSize: 64),
              ],
            ),
          ),
          const Spacer(),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                height: 78,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0.5),
                  child: Row(
                    children: List.generate(5, (idx) {
                      if (idx == 2) {
                        return const Expanded(child: SizedBox.shrink());
                      }
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Skeletons.circle(size: 28),
                              const SizedBox(height: 6),
                              Skeletons.box(width: 40, height: 11, radius: 4),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: () {},
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.hourglass_empty, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loadingRole) {
      return _buildHomeSkeleton();
    }

    return Scaffold(
      appBar: CustomAppBar(
        userPhotoUrl: _userPhotoUrl,
        userName: _userName,
        onAvatarTap: () async {
          await Navigator.pushNamed(context, '/profile');
          _loadUserRole(); // recarga avatar/nombre tras volver del perfil
        },
        onNotificationsTap: () => Navigator.pushNamed(context, '/notifications'),
      ),
      body: _pages.isEmpty
          ? const Center(child: Text('Error cargando navegación'))
          : _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: _onFabPressed,
        backgroundColor: scheme.primary,
        child: Icon(
          _userRole == 'organizer' || _userRole == 'admin'
              ? Icons.add
              : Icons.qr_code_scanner,
          size: 28,
          color: scheme.onPrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12,
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0.5),
            child: Row(
              children: List.generate(5, (idx) {
                // Distribución fija de 5 slots (4 botones + hueco central para FAB)
                if (idx == 2) {
                  return const Expanded(
                    child: SizedBox(height: 8),
                  );
                }

                final navIdx = idx < 2 ? idx : idx - 1;
                final item = _navItems[navIdx];
                final isActive = _currentIndex == navIdx;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _onNavItemTapped(navIdx),
                    child: SizedBox.expand(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                (item.icon as Icon).icon,
                                color: isActive ? scheme.primary : scheme.secondaryText,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isActive ? scheme.primary : scheme.secondaryText,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                        ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
