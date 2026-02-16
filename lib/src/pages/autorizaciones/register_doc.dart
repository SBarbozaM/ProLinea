import 'package:flutter/material.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:embarques_tdp/src/services/list_docs_auth_service.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/doc_Auth_model.dart';
import '../../providers/providers.dart';

class Documento {
  final int id;
  final String titulo;
  final String fechaRegistro;

  Documento({
    required this.id,
    required this.titulo,
    required this.fechaRegistro,
  });
}

class DocumentosRegistrados extends StatelessWidget {
  final ListDocsAuthServicio documentoService = ListDocsAuthServicio();

  Future<DocAuthModel> _obtenerListDocsAuth(String tipoDoc, String numDoc, String idSubAut) async {
    return await documentoService.listarDocsAuthsUsuario(tipoDoc, numDoc, idSubAut);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos registrados'),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: FutureBuilder<DocAuthModel>(
        future: _obtenerListDocsAuth(usuarioProvider.usuario.tipoDoc, usuarioProvider.usuario.numDoc, '217'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.authDocs.isEmpty) {
            return Center(child: Text('No hay documentos registrados'));
          } else {
            final documentos = snapshot.data!.authDocs;
            return ListView.builder(
              itemCount: documentos.length,
              itemBuilder: (context, index) {
                final documento = documentos[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Icon(Icons.description),
                    title: Text(documento.documento),
                    subtitle: Text('Fecha de Registro: ${documento.fecha}'),
                    onTap: () {
                      // Acción al hacer clic en un documento (opcional)
                      print('Documento seleccionado: ${documento.pkOrden}');
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
