import 'package:embarques_tdp/src/models/Autorizaciones/backo/TipoDocumento.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

class OpcionesDocumentoPage extends StatelessWidget {
  const OpcionesDocumentoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = ModalRoute.of(context)!.settings.arguments as TipoDocumento;

    final List<Map<String, dynamic>> opciones = [
      {'titulo': 'Pendientes', 'icono': Icons.pending_actions, 'color': Colors.orange, 'tipo': 'pendientes'},
      {'titulo': 'Aprobados', 'icono': Icons.check_circle_outline, 'color': Colors.green, 'tipo': 'aprobados'},
      {'titulo': 'Rechazados', 'icono': Icons.cancel_outlined, 'color': Colors.red, 'tipo': 'rechazados'},
      {'titulo': 'Observados', 'icono': Icons.remove_red_eye_outlined, 'color': Colors.blue, 'tipo': 'observados'},
      {'titulo': 'Registrados', 'icono': Icons.list_alt_outlined, 'color': Colors.purple, 'tipo': 'registrados'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(doc.descripcion),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: opciones.length,
        itemBuilder: (context, index) {
          final opcion = opciones[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (opcion['color'] as Color?)?.withOpacity(0.15) ?? AppColors.mainBlueColor.withOpacity(0.15),
                child: Icon(opcion['icono'], color: opcion['color']),
              ),
              title: Text(
                opcion['titulo'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.mainBlueColor),
              onTap: () {
                Navigator.of(context).pushNamed(
                  'listaDocumentosBacko',
                  arguments: {
                    'tipoDocumento': doc,
                    'tipo': opcion['tipo'], // 👈 pendientes, aprobados, etc.
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('inicio', (route) => false),
        backgroundColor: AppColors.mainBlueColor,
        tooltip: 'Regresar a Inicio',
        child: const Icon(Icons.home),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
