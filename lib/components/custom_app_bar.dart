import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userPhotoUrl;
  final String? userName;
  final VoidCallback onAvatarTap;
  final VoidCallback onNotificationsTap;

  const CustomAppBar({
    super.key,
    this.userPhotoUrl,
    this.userName,
    required this.onAvatarTap,
    required this.onNotificationsTap,
  });

  Widget _buildUserAvatar() {
    if (userPhotoUrl != null && userPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(userPhotoUrl!),
        onBackgroundImageError: (_, _) {
          // Fallback si la imagen falla
        },
        child: userPhotoUrl == null
            ? Text(userName?.isNotEmpty == true
                ? userName![0].toUpperCase()
                : '?')
            : null,
      );
    } else {
      return CircleAvatar(
        radius: 18,
        child: Text(
          userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        color: scheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/unieventos_icon.svg',
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'UniEventos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationsTap,
                color: scheme.onSurface,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(25),
                child: _buildUserAvatar(),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
