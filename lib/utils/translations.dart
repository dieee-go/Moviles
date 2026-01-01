/// Función para traducir roles de usuario
String translateRole(String role) {
  switch (role) {
    case 'admin':
      return 'Administrador';
    case 'organizer':
      return 'Organizador';
    case 'student':
      return 'Estudiante';
    default:
      return role;
  }
}

/// Función para traducir estados de eventos
String translateEventStatus(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return 'Activo';
    case 'done':
      return 'Finalizado';
    case 'cancelled':
      return 'Cancelado';
    case '':
      return 'Activo';
    default:
      return status;
  }
}
