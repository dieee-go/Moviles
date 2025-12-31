class FakeUserService {
  // Lista de usuarios de ejemplo con distintos roles
  static final List<Map<String, String>> _users = [
    {
      "id": "1",
      "name": "Juan Perez",
      "email": "juan.perez@ipn.mx",
      "password": "password123",
      "career": "Ingeniería en Sistemas",
      "avatarUrl": "https://picsum.photos/200",
      "role": "estudiante",
    },
    {
      "id": "2",
      "name": "Carlos López",
      "email": "carlos@ipn.mx",
      "password": "organizer123",
      "career": "Ingeniería Industrial",
      "avatarUrl": "https://picsum.photos/201",
      "role": "organizador",
    },
    {
      "id": "3",
      "name": "María Fernández",
      "email": "maria@ipn.mx",
      "password": "admin123",
      "career": "Administración",
      "avatarUrl": "https://picsum.photos/202",
      "role": "admin",
    },
  ];

  // Usuario actual (simulamos login)
  static Map<String, String>? _currentUser;

  static bool loginUser(String email, String password) {
    try {
      final user = _users.firstWhere(
        (u) => u["email"] == email && u["password"] == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Map<String, String>? getUser() => _currentUser;

  // 🔹 Cambiar rol de un usuario específico por email
  static void setRole(String email, String role) {
    for (var user in _users) {
      if (user["email"] == email) {
        user["role"] = role;
        break;
      }
    }
  }

  // 🔹 Eliminar usuario por email
  static void deleteUser(String email) {
    _users.removeWhere((user) => user["email"] == email);
  }

  // 🔹 Actualizar datos del usuario actual
  static void updateUser(String name, String email, String career, String password) {
    if (_currentUser != null) {
      _currentUser!["name"] = name;
      _currentUser!["email"] = email;
      _currentUser!["career"] = career;
      _currentUser!["password"] = password;
    }
  }

  static void updateUserAvatar(String url) {
    if (_currentUser != null) {
      _currentUser!["avatarUrl"] = url;
    }
  }

  static List<Map<String, String>> getAllUsers() => _users;
}
