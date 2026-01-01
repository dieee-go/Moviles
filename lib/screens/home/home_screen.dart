import 'package:flutter/material.dart';
import '../../components/skeletons.dart';
import '../../main.dart';
import '../../theme/app_theme_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String? _userRole;
  bool _loadingRole = true;

  List<String> _pageRoutes = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();
        
        final role = (data['role'] as String?)?.trim().toLowerCase();
        
        setState(() {
          _userRole = role;
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
      setState(() {
        _loadingRole = false;
        _setupNavigation(null);
      });
    }
  }

  void _setupNavigation(String? role) {
    if (role == 'admin') {
      _pageRoutes = [
        '/inicio',
        '/explore',
        '/admin',
        '/calendar',
        '/profile',
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Admin'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else if (role == 'organizer') {
      _pageRoutes = [
        '/inicio',
        '/explore',
        '/my-events',
        '/calendar',
        '/profile',
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mis Eventos'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    } else {
      // Estudiante o sin rol
      _pageRoutes = [
        '/inicio',
        '/explore',
        '/calendar',
        '/profile',
      ];
      _navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendario'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ];
    }
  }

  void _onFabPressed() {
    if (_userRole == 'organizer' || _userRole == 'admin') {
      Navigator.pushNamed(context, '/create-event');
    } else {
      // Escanear QR para estudiantes
      Navigator.pushNamed(context, '/qr-scan');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() => _currentIndex = index);
    Navigator.pushNamed(context, _pageRoutes[index]);
  }

  Scaffold _buildHomeSkeleton() {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 60),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (_) => Skeletons.circle(size: 40)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.hourglass_empty, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) {
              // Determinar cuál es el índice actual basado en la ruta
              final routeIndex = _pageRoutes.indexOf(settings.name ?? '/inicio');
              if (routeIndex != -1) {
                _currentIndex = routeIndex;
              }
              // Retornar página vacía, la verdadera navegación ocurre en el nivel superior
              return const SizedBox.shrink();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
          height: 65,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length * 2 - 1, (idx) {
                // Calcular índice del item real y si es espacio
                final isSpace = idx.isOdd;
                final itemIdx = idx ~/ 2;
                
                if (isSpace) {
                  // Espacio para el FAB
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [SizedBox(height: 8)],
                    ),
                  );
                }
                
                final item = _navItems[itemIdx];
                final isActive = _currentIndex == itemIdx;
                
                return SizedBox(
                  width: 60,
                  child: InkWell(
                    onTap: () => _onNavItemTapped(itemIdx),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (item.icon as Icon).icon,
                          color: isActive ? scheme.primary : scheme.secondaryText,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive ? scheme.primary : scheme.secondaryText,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
