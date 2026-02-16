import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:embarques_tdp/src/models/check_list/checklist.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/bloc/checklist_bloc.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// [18:52 - VIDEO] Import necesario
// import 'package:video_player/video_player.dart';

class CheckListDetalleMantenimientoPage extends StatefulWidget {
  final CheckList checkList;

  const CheckListDetalleMantenimientoPage({
    super.key,
    required this.checkList,
  });

  @override
  State<CheckListDetalleMantenimientoPage> createState() => _CheckListDetalleMantenimientoPageState();
}

class _CheckListDetalleMantenimientoPageState extends State<CheckListDetalleMantenimientoPage> {
  TextEditingController descripcion = TextEditingController();

  @override
  void initState() {
    super.initState();
    descripcion.text = widget.checkList.observacion;
  }

  // 👉 función que ejecutamos cuando se presiona "atrás"
  Future<bool> _handleBackPressed() async {
    Log.insertarLogDomicilio(
      context: context,
      mensaje: "Navega al check list",
      rpta: "OK",
    );
    if (descripcion.text.trim().length < 4) {
      _mostrarModalRespuesta(
        "Para salir, por favor ingresa una descripción con al menos 4 caracteres.",
        "",
        false,
      ).show();
      return false;
    }
    setState(() {
      widget.checkList.observacion = descripcion.text.trim();
    });

    context.read<ChecklistBloc>().add(
          NoLikeCompletadoEvent(checkmodel: widget.checkList),
        );

    return true;
  }

  int getTotalImageBytes() {
    int total = 0;
    for (var r in widget.checkList.recursos) {
      total += base64Decode(r.redehSArchivo).length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<ChecklistBloc>().state;

    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text("${widget.checkList.grupos}"),
          centerTitle: true,
          backgroundColor: AppColors.mainBlueColor,
          leading: IconButton(
            onPressed: () async {
              bool puedeSalir = await _handleBackPressed();
              if (puedeSalir) Navigator.pop(context, "guardado");
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  context.read<ChecklistBloc>().add(
                        NoLikeNoCompletadoEvent(checkmodel: widget.checkList),
                      );
                  Navigator.pop(context, "cancelado");
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18), // Fondo suave
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(top: 20, left: 20, right: 20),
            child: SingleChildScrollView(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${widget.checkList.trabajo}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descripcion,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.mainBlueColor,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        hintText: "Ingrese las observaciones encontradas...",
                      ),
                      cursorColor: AppColors.mainBlueColor,
                      maxLines: 7,
                    ),
                    SizedBox(height: 12),

                    // 🔵 TITULO + BOTONES FOTO Y VIDEO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fotos",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainBlueColor,
                          ),
                        ),
                        Text(
                          "Peso total: ${(getTotalImageBytes() / 1024).toStringAsFixed(1)} KB",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Row(
                          children: [
                            // FOTO
                            GestureDetector(
                              onTap: () async {
                                if (widget.checkList.recursos.length >= state.validarCheck.maxFiles) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Solo se permiten 2 imágenes")),
                                  );
                                  return;
                                }

                                if (await Permission.camera.request().isGranted) {
                                  final picker = ImagePicker();
                                  final XFile? img = await picker.pickImage(
                                    source: ImageSource.camera,
                                    maxWidth: 1200,
                                  );
                                  if (img == null) return;

                                  final compressed = await FlutterImageCompress.compressWithFile(
                                    img.path,
                                    format: CompressFormat.webp,
                                    quality: 40,
                                    minWidth: 400,
                                  );

                                  if (compressed == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error al comprimir imagen")),
                                    );
                                    return;
                                  }

                                  final int compressedBytes = compressed.length;
                                  final double kb = compressedBytes / 1024;
                                  print("📦 Imagen comprimida WEBP: ${kb.toStringAsFixed(2)} KB");

                                  int newTotal = getTotalImageBytes() + compressedBytes;
                                  if (newTotal > (state.validarCheck.maxSizeFiles * 1024)) {
                                    _mostrarModalRespuesta(
                                      "Las imágenes superan el límite permitido de ${state.validarCheck.maxSizeFiles} KB.",
                                      "Elimine una imagen para continuar.",
                                      false,
                                    ).show();
                                    return;
                                  }

                                  String base64Image = base64Encode(compressed);

                                  DateTime now = DateTime.now();
                                  int id = now.toUtc().millisecondsSinceEpoch;

                                  Recurso fotos = Recurso(
                                    dehSCodigo: id.toString(),
                                    viaJNroViaje: context.read<ChecklistBloc>().state.validarCheck.nroViaje.toString(),
                                    redehSArchivo: base64Image,
                                    redehSTipoArchivo: ".webp",
                                    redehSFechaRegistrada: DateFormat('dd/MM/yyyy HH:mm:ss').format(now),
                                  );

                                  setState(() {
                                    widget.checkList.recursos.add(fotos);
                                  });
                                }
                              },
                              child: Icon(
                                Icons.add_a_photo,
                                color: AppColors.mainBlueColor,
                              ),
                            ),

                            SizedBox(width: 15),

                            // [18:52 - VIDEO] Nuevo botón de video
                            // GestureDetector(
                            //   onTap: () async {
                            //     await _agregarVideo();
                            //   },
                            //   child: Icon(
                            //     Icons.videocam,
                            //     color: Colors.redAccent,
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // 🔵 LISTA DE FOTOS / VIDEOS
                    Container(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.checkList.recursos.length,
                        itemBuilder: (context, index) {
                          Recurso archivo = widget.checkList.recursos[index];
                          Uint8List bytes = Base64Decoder().convert(archivo.redehSArchivo);

                          // Si es VIDEO
                          // if (archivo.redehSTipoArchivo == ".mp4") {
                          //   return GestureDetector(
                          //     onTap: () {
                          //       showDialog(
                          //         context: context,
                          //         builder: (_) => AlertDialog(
                          //           contentPadding: EdgeInsets.zero,
                          //           content: Container(
                          //             height: 300,
                          //             width: 300,
                          //             child: VideoPlayerWidget(bytes: bytes),
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //     child: Container(
                          //       width: 70,
                          //       height: 90,
                          //       color: Colors.black,
                          //       child: Icon(Icons.play_arrow,
                          //           color: Colors.white),
                          //     ),
                          //   );
                          // }

                          // Si es FOTO
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    contentPadding: EdgeInsets.zero,
                                    content: Container(
                                      width: MediaQuery.of(context).size.width * 0.9,
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Image.memory(
                                          bytes,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: MaterialButton(
                                              onPressed: () {
                                                setState(() {
                                                  widget.checkList.recursos.remove(archivo);
                                                  Navigator.pop(context);
                                                });
                                              },
                                              height: 40,
                                              color: AppColors.redColor,
                                              child: Text(
                                                "Eliminar",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Expanded(
                                            child: MaterialButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              height: 40,
                                              color: AppColors.mainBlueColor,
                                              child: Text(
                                                "Cerrar",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Container(
                                width: 70,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  image: DecorationImage(
                                    image: MemoryImage(bytes),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Expanded(child: Container()),

                    Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 10,
                      ),
                      child: MaterialButton(
                        minWidth: double.infinity,
                        height: 50,
                        color: AppColors.mainBlueColor,
                        onPressed: () {
                          validarGuardar();
                        },
                        child: Text(
                          "Guardar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // [18:52 - VIDEO] Función para agregar video
  // Future<void> _agregarVideo() async {
  //   const int MAX_TOTAL_BYTES = 200 * 1024;

  //   final picker = ImagePicker();

  //   final XFile? video = await picker.pickVideo(
  //     source: ImageSource.camera,
  //     maxDuration: Duration(seconds: 5),
  //   );

  //   if (video == null) return;

  //   final bytes = await video.readAsBytes();
  //   final int size = bytes.length;
  //   final double sizeKB = size / 1024;
  //   final double sizeMB = sizeKB / 1024;

  //   print("🎥 Video capturado: ${sizeKB.toStringAsFixed(2)} KB (${sizeMB.toStringAsFixed(2)} MB)");

  //   if (size > MAX_TOTAL_BYTES) {
  //     _mostrarModalRespuesta(
  //       "El video pesa demasiado (${sizeMB.toStringAsFixed(2)} MB).",
  //       "El checklist solo permite hasta 200 KB.",
  //       false,
  //     ).show();
  //     return;
  //   }

  //   String base64Video = base64Encode(bytes);

  //   DateTime now = DateTime.now();
  //   int id = now.toUtc().millisecondsSinceEpoch;

  //   Recurso recursoVideo = Recurso(
  //     dehSCodigo: id.toString(),
  //     viaJNroViaje: context.read<ChecklistBloc>().state.validarCheck.nroViaje.toString(),
  //     redehSArchivo: base64Video,
  //     redehSTipoArchivo: ".mp4",
  //     redehSFechaRegistrada: DateFormat('dd/MM/yyyy HH:mm:ss').format(now),
  //   );

  //   setState(() {
  //     widget.checkList.recursos.add(recursoVideo);
  //   });
  // }

  validarGuardar() {
    setState(() {
      widget.checkList.observacion = descripcion.text.trim();
    });

    if (descripcion.text.trim().length < 4) {
      return _mostrarModalRespuesta(
        "Para guardar, por favor ingresa una descripción con al menos 4 caracteres.",
        "",
        false,
      ).show();
    }

    context.read<ChecklistBloc>().add(
          NoLikeCompletadoEvent(checkmodel: widget.checkList),
        );

    Navigator.pop(context, "guardado");
  }

  AwesomeDialog _mostrarModalRespuesta(String titulo, String cuerpo, bool success) {
    return AwesomeDialog(
      context: context,
      dialogType: success ? DialogType.success : DialogType.error,
      animType: AnimType.topSlide,
      title: titulo,
      desc: cuerpo,
      descTextStyle: TextStyle(fontSize: 15)
    );
  }
}

// class VideoPlayerWidget extends StatefulWidget {
//   final Uint8List bytes;

//   const VideoPlayerWidget({super.key, required this.bytes});

//   @override
//   State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   VideoPlayerController? controller;

//   @override
//   void initState() {
//     super.initState();
//     _loadVideo();
//   }

//   Future<void> _loadVideo() async {
//     // Crear archivo temporal
//     final tempDir = await getTemporaryDirectory();
//     final tempFile = File("${tempDir.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4");

//     // Escribir los bytes
//     await tempFile.writeAsBytes(widget.bytes);

//     // Crear controlador desde archivo
//     controller = VideoPlayerController.file(tempFile)
//       ..initialize().then((_) {
//         setState(() {});
//         controller!.play();
//       });
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (controller == null || !controller!.value.isInitialized) {
//       return Center(child: CircularProgressIndicator());
//     }

//     return AspectRatio(
//       aspectRatio: controller!.value.aspectRatio,
//       child: VideoPlayer(controller!),
//     );
//   }
// }
