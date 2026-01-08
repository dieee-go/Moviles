import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_preferences_provider.dart';
import '../../theme/app_theme_extensions.dart';
import 'change_password_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _sendingRequest = false;
  bool _loadingRequestStatus = false;
  String? _requestStatus;
  DateTime? _requestUpdatedAt;
  String? _profileRole;
  String? _userName;
  String? _userEmail;
  String? _avatarUrl;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadRequestStatus();
    _loadUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ThemeController.of(context);
    final mode = controller?.themeMode ?? ThemeMode.light;
    if (_themeMode != mode) {
      setState(() => _themeMode = mode);
    }
  }

  Future<void> _loadUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _profileRole = data['role'] as String?;
        });
      }
    } catch (_) {
      // Silenciar errores de rol
    }
  }

  Future<void> _loadUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await supabase
          .from('profiles')
          .select('nombre, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _userName = data['nombre'] as String?;
          _avatarUrl = data['avatar_url'] as String?;
          _userEmail = user.email;
        });
      }
    } catch (_) {
      // Silenciar errores
    }
  }

  Future<bool> _confirmRequestDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicitar rol de organizador'),
          content: const Text(
              'Enviaremos tu solicitud para que un administrador la revise. ¿Quieres continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Solicitar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _requestOrganizerRole() {
    // Validar si puede solicitar
    if (!_canRequestOrganizer()) {
      // Si fue revocado, mostrar mensaje específico
      if (_requestStatus == 'revoked') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes hacer más solicitudes porque tu rol de organizador fue revocado'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      // Si está pendiente, mostrar otro mensaje
      else if (_requestStatus == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya tienes una solicitud pendiente')),
        );
      }
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para enviar la solicitud')),
      );
      return;
    }

    if (_sendingRequest) return;

    _confirmRequestDialog().then((confirmed) {
      if (!confirmed) return;

      setState(() => _sendingRequest = true);

      () async {
        try {
          // Evita duplicados: si ya hay solicitud pendiente, solo notifica
          final existing = await supabase
              .from('role_requests')
              .select('status')
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (existing != null && existing['status'] == 'pending') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ya tienes una solicitud pendiente')),
              );
            }
            return;
          }

          // Si existe una solicitud anterior (rejected o revoked), elimínala primero
          if (existing != null && (existing['status'] == 'rejected' || existing['status'] == 'revoked')) {
            await supabase
                .from('role_requests')
                .delete()
                .eq('user_id', user.id);
          }

          await supabase.from('role_requests').insert({
            'user_id': user.id,
            'status': 'pending',
            'message': 'Solicitud enviada desde app',
          });

          await _loadRequestStatus();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Solicitud de rol de organizador enviada')),
            );
          }
        } on PostgrestException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.message}')),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error inesperado al enviar solicitud')),
            );
          }
        } finally {
          if (mounted) setState(() => _sendingRequest = false);
        }
      }();
    });
  }

  Future<void> _loadRequestStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _loadingRequestStatus = true;
    });

    try {
      final data = await supabase
          .from('role_requests')
          .select('status, updated_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _requestStatus = data?['status'] as String?;
        _requestUpdatedAt = data?['updated_at'] != null
            ? DateTime.tryParse(data!['updated_at'] as String)
            : null;
      });
    } catch (_) {
      setState(() {
        _requestStatus = null;
        _requestUpdatedAt = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRequestStatus = false;
        });
      }
    }
  }

  Widget _statusBadge() {
    if (_loadingRequestStatus) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      );
    }
    final status = _requestStatus;
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Aprobada';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rechazada';
        break;
      case 'revoked':
        color = Colors.grey;
        label = 'Revocada';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      default:
        color = Colors.grey;
        label = 'Sin solicitud';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 31),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _statusSubtitle() {
    String formatDate(DateTime dt) {
      final d = dt.toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      final hh = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yyyy $hh:$min';
    }

    if (_requestStatus == null) {
      final roleLabel = _friendlyRole(_profileRole);
      return roleLabel.isEmpty
          ? 'Aún no has enviado una solicitud'
          : 'Rol actual: $roleLabel';
    }

    final updated = _requestUpdatedAt;
    switch (_requestStatus) {
      case 'pending':
        if (updated != null) {
          return 'Tu solicitud está en revisión. Enviada el ${formatDate(updated)}';
        }
        return 'Tu solicitud está en revisión.';
      case 'approved':
        if (updated != null) {
          return 'Solicitud aprobada el ${formatDate(updated)}. Ya cuentas con el rol de organizador.';
        }
        return 'Solicitud aprobada. Ya cuentas con el rol de organizador.';
      case 'rejected':
        if (updated != null) {
          final daysSince = DateTime.now().difference(updated.toLocal()).inDays;
          final remaining = (30 - daysSince).clamp(0, 30);
          if (remaining > 0) {
            return 'Solicitud rechazada el ${formatDate(updated)}. Podrás volver a solicitar en $remaining días.';
          } else {
            return 'Solicitud rechazada el ${formatDate(updated)}. Ya puedes volver a solicitar.';
          }
        }
        return 'Solicitud rechazada.';
      case 'revoked':
        if (updated != null) {
          return 'Tu rol de organizador fue revocado el ${formatDate(updated)}. No puedes solicitar nuevamente.';
        }
        return 'Tu rol de organizador fue revocado. No puedes solicitar nuevamente.';
      default:
        if (updated != null) {
          return 'Último estado: $_requestStatus. Actualizado el ${formatDate(updated)}';
        }
        return 'Último estado: $_requestStatus';
    }
  }

  bool _canRequestOrganizer() {
    final role = _profileRole;
    if (role == 'organizer' || role == 'admin') return false;
    if (_requestStatus == null) return true;
    if (_requestStatus == 'pending') return false;
    if (_requestStatus == 'revoked') return false; // No permitir solicitar si fue revocado
    if (_requestStatus == 'rejected' && _requestUpdatedAt != null) {
      final daysSince = DateTime.now().difference(_requestUpdatedAt!.toLocal()).inDays;
      return daysSince >= 30;
    }
    return true;
  }

  bool _shouldShowStatusTile() {
    final role = _profileRole;
    if (role == 'organizer' || role == 'admin') return false;
    return _requestStatus != null;
  }

  String _friendlyRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'organizer':
        return 'Organizador';
      case 'student':
        return 'Estudiante';
      default:
        return role ?? '';
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
      ? Colors.black.withValues(alpha: 90) // 35% of 255 ≈ 90
      : const Color(0x0D000000);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _leadingIcon(IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: scheme.primary),
    );
  }

  ListTile _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: _leadingIcon(icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: Switch(
        value: value,
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final scheme = Theme.of(context).colorScheme;
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.grey[400];
        }),
        onChanged: onChanged,
      ),
    );
  }

  ListTile _navigationTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _leadingIcon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: titleColor ?? scheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: scheme.secondaryText),
      onTap: onTap,
    );
  }

  void _toggleDarkMode(bool value) {
    final controller = ThemeController.of(context);
    final mode = value ? ThemeMode.dark : ThemeMode.light;
    controller?.setThemeMode(mode);
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: TextStyle(
            color: appBarColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: appBarColor,
        iconTheme: IconThemeData(color: appBarColor),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header con perfil del usuario
          _buildProfileHeader(),
          const SizedBox(height: 32),

          // Apariencia
          _sectionTitle('Apariencia', Icons.palette_outlined),
          _sectionCard(
            children: [
              _switchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Modo oscuro',
                value: _themeMode == ThemeMode.dark,
                onChanged: _toggleDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Notificaciones
          _sectionTitle('Notificaciones', Icons.notifications_outlined),
          _buildNotificationsSection(),
          const SizedBox(height: 28),

          // Solicitud de rol (si aplica)
          if (_profileRole != 'admin' && _profileRole != 'organizer') ...[
            _sectionTitle('Rol de organizador', Icons.verified_user_outlined),
            _sectionCard(
              children: [
                if (_shouldShowStatusTile())
                  ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    title: const Text(
                      'Estado de solicitud',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _statusSubtitle(),
                      style: TextStyle(fontSize: 13, color: scheme.secondaryText),
                    ),
                    trailing: _statusBadge(),
                    onTap: _loadRequestStatus,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conviértete en organizador',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea y gestiona tus propios eventos en la plataforma',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _canRequestOrganizer() ? _requestOrganizerRole : null,
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Solicitar rol'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // Cuenta
          _sectionTitle('Cuenta', Icons.account_circle_outlined),
          _sectionCard(
            children: [
              _navigationTile(
                icon: Icons.lock_reset_outlined,
                title: 'Cambiar contraseña',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Información
          _sectionTitle('Información', Icons.info_outlined),
          _sectionCard(
            children: [
              _navigationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Política de privacidad',
                onTap: () {},
              ),
              const Divider(height: 1),
              _navigationTile(
                icon: Icons.description_outlined,
                title: 'Términos de servicio',
                onTap: () {},
              ),
              const Divider(height: 1),
              _navigationTile(
                icon: Icons.info_outline,
                title: 'Acerca de la aplicación',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Cerrar sesión (separado)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cerrar sesión desde la pantalla de perfil')),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) {
        if (prefs == null) {
          return _sectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Cargando preferencias...',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondaryText),
                ),
              ),
            ],
          );
        }

        return _sectionCard(
          children: [
            // Registros
            _switchTile(
              icon: Icons.how_to_reg_outlined,
              title: 'Confirmación de registro',
              value: prefs.registrationNotifications,
              onChanged: (v) => _updatePreference('registration', v, prefs),
            ),
            const Divider(height: 1),
            // Cambios en eventos
            _switchTile(
              icon: Icons.edit_outlined,
              title: 'Cambios en eventos',
              value: prefs.eventUpdateNotifications,
              onChanged: (v) => _updatePreference('event_update', v, prefs),
            ),
            const Divider(height: 1),
            // Recordatorios
            _switchTile(
              icon: Icons.schedule_outlined,
              title: 'Recordatorios',
              value: prefs.reminderNotifications,
              onChanged: (v) => _updatePreference('reminder', v, prefs),
            ),
            // Expandible para tiempo de recordatorio
            if (prefs.reminderNotifications)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildReminderTimePicker(prefs),
              ),
            const Divider(height: 1),
            // Alertas de organizador
            _switchTile(
              icon: Icons.person_add_outlined,
              title: 'Alertas de organizador',
              value: prefs.organizerNotifications,
              onChanged: (v) => _updatePreference('organizer', v, prefs),
            ),
            const Divider(height: 1),
            // Alertas de admin
            _switchTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Alertas de administrador',
              value: prefs.adminNotifications,
              onChanged: (v) => _updatePreference('admin', v, prefs),
            ),
            const Divider(height: 1),
            // Horario silencioso
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bedtime_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text(
                'Horario silencioso',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${prefs.silentHoursStart.hour.toString().padLeft(2, '0')}:${prefs.silentHoursStart.minute.toString().padLeft(2, '0')} - ${prefs.silentHoursEnd.hour.toString().padLeft(2, '0')}:${prefs.silentHoursEnd.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondaryText),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showSilentHoursDialog(prefs),
            ),
          ],
        );
      },
      loading: () => _sectionCard(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
      error: (error, stack) => _sectionCard(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimePicker(NotificationPreference prefs) {
    const options = [15, 30, 60, 1440];
    const labels = ['15 min', '30 min', '1 hora', '1 día'];
    
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recordar antes de',
            style: TextStyle(
              fontSize: 12,
              color: scheme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(
              options.length,
              (index) => ChoiceChip(
                label: Text(labels[index]),
                selected: prefs.reminderMinutesBefore == options[index],
                onSelected: (_) => _updateReminderTime(options[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSilentHoursDialog(NotificationPreference prefs) {
    TimeOfDay selectedStart = prefs.silentHoursStart;
    TimeOfDay selectedEnd = prefs.silentHoursEnd;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Horario silencioso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Desde'),
                trailing: Text(
                  '${selectedStart.hour.toString().padLeft(2, '0')}:${selectedStart.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedStart,
                  );
                  if (time != null) {
                    setStateDialog(() => selectedStart = time);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Hasta'),
                trailing: Text(
                  '${selectedEnd.hour.toString().padLeft(2, '0')}:${selectedEnd.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedEnd,
                  );
                  if (time != null) {
                    setStateDialog(() => selectedEnd = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(userNotificationPreferencesProvider.notifier)
                    .updateSilentHours(selectedStart, selectedEnd);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Horario silencioso actualizado')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePreference(
    String field,
    bool value,
    NotificationPreference prefs,
  ) async {
    final notifier = ref.read(userNotificationPreferencesProvider.notifier);
    final success = await notifier.togglePreference(field);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferencia actualizada')),
      );
    }
  }

  Future<void> _updateReminderTime(int minutes) async {
    final notifier = ref.read(userNotificationPreferencesProvider.notifier);
    final success = await notifier.updateReminderTime(minutes);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tiempo de recordatorio actualizado')),
      );
    }
  }

  Widget _buildProfileHeader() {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.1),
            scheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar y nombre
          Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.2),
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.person,
                            size: 36,
                            color: scheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 36,
                        color: scheme.primary,
                      ),
              ),
              const SizedBox(width: 16),
              // Nombre y rol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _friendlyRole(_profileRole),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
