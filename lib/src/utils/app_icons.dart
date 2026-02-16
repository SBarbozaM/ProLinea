import 'package:flutter/material.dart';

IconData getIconFromName(String iconName) {
  const Map<String, IconData> iconMap = {
    'home': Icons.home,
    'notifications': Icons.notifications,
    'search': Icons.search,
    'settings': Icons.settings,
    'description': Icons.description,
    'warning': Icons.warning,
    'call': Icons.call, // Llamada
    'email': Icons.email, // Correo electrónico
    'message': Icons.message, // Mensaje
    'announcement': Icons.announcement, // Anuncio
    'celebration': Icons.celebration, // Celebración (felicitaciones)
    'assignment': Icons.assignment, // Asignación (tareas o documentos)
    'file_copy': Icons.file_copy, // Documento o archivo
    'archive': Icons.archive, // Archivado
    'check_circle': Icons.check_circle, // Verificación o éxito
    'highlight_off': Icons.highlight_off, // Error o atención
    'access_alarm': Icons.access_alarm, // Alarma
    'accessibility': Icons.accessibility, // Accesibilidad o algo importante
    'group': Icons.group, // Reconocimiento (grupo o equipo)
    'alarm_on': Icons.alarm_on, // Alarma activada
    'notifications_active': Icons.notifications_active, // Notificaciones activas
    'priority_high': Icons.priority_high, 
    'new_releases': Icons.new_releases, 
    'update': Icons.update,




  };

  return iconMap[iconName] ?? Icons.notifications;
}
