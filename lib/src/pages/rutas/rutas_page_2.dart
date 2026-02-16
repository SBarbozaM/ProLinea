import 'package:embarques_tdp/src/models/rutas/ruta_listar.dart';
import 'package:embarques_tdp/src/pages/rutas/ruta_detalle_page.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/rutas_service.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RutaListPage extends StatefulWidget {
  const RutaListPage({
    Key? key,
  }) : super(key: key);

  @override
  _RutaListPageState createState() => _RutaListPageState();
}

class _RutaListPageState extends State<RutaListPage> {
  final RutaListarServicio _servicio = RutaListarServicio();

  late String _tipoDoc;
  late String _numDoc;
  late String _codOperacion;

  bool _isSearching = false;
  String _searchQuery = '';

  bool _filtroRecojosActivo = false;
  bool _filtroRepartosActivo = false;

  DateTime _horaConsulta = DateTime.now();
  bool _isRefreshing = false;

  // Set<String> _tiposRuta = {};
  // Map<String, bool> _filtrosActivos = {};

  Set<String> _tiposRuta = {};
  Map<String, bool> _filtrosActivos = {};
  List<RutaListar> _todasLasRutas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final tipoDoc = usuarioProvider.usuario.tipoDoc;
      final numDoc = usuarioProvider.usuario.numDoc;
      final codOperacion = usuarioProvider.usuario.codOperacion;

      await _servicio.cargarRutas(tipoDoc, numDoc, codOperacion);

      setState(() {
        _horaConsulta = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
      _horaConsulta = DateTime.now();
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final tipoDoc = usuarioProvider.usuario.tipoDoc;
      final numDoc = usuarioProvider.usuario.numDoc;
      final codOperacion = usuarioProvider.usuario.codOperacion;

      await _servicio.cargarRutas(tipoDoc, numDoc, codOperacion);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al actualizar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _servicio.disposeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar  ruta...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mis Rutas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                  Row(
                    children: [
                      const Text(
                        'Fecha de Consulta: ',
                        style: TextStyle(fontSize: 10, height: 0.7, color: AppColors.greyColor),
                      ),
                      Text(
                        '${DateFormat('hh:mm a').format(_horaConsulta)}',
                        style: const TextStyle(fontSize: 13, height: 0.7, color: Color.fromARGB(255, 241, 239, 174)),
                      )
                    ],
                  ),
                ],
              ),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
            ),
        ],
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.mainBlueColor, // 🎨 color del spinner
        //  backgroundColor: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.tune),
                  SizedBox(width: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilterChip(
                        label: const Text('Recojos'),
                        selected: _filtroRecojosActivo,
                        onSelected: (selected) {
                          setState(() {
                            _filtroRecojosActivo = selected;
                          });
                        },
                        selectedColor: AppColors.activeFilterColor,
                        labelStyle: TextStyle(
                          color: _filtroRecojosActivo ? Colors.white : Colors.black,
                        ),
                        showCheckmark: false,
                      ),
                      SizedBox(width: 10),
                      FilterChip(
                        label: Text('Repartos'),
                        selected: _filtroRepartosActivo,
                        onSelected: (selected) {
                          setState(() {
                            _filtroRepartosActivo = selected;
                          });
                        },
                        selectedColor: AppColors.activeFilterColor,
                        // checkmarkColor: Colors.white,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: _filtroRepartosActivo ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            //Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<RutaListar>>(
                stream: _servicio.rutasStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final rutas = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: rutas.length,
                      itemBuilder: (context, index) {
                        final ruta = rutas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RutaDetailPage(
                                  titulo: '${ruta.origen} - ${ruta.destino}',
                                  descripcion: ruta.camino,
                                  urlMapa: ruta.mapa,
                                ),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header con código y badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.route, color: AppColors.mainBlueColor, size: 30),
                                          const SizedBox(width: 8),
                                          Text('${ruta.origen} - ${ruta.destino}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Información de origen y destino
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Columna de iconos
                                      Column(
                                        children: [
                                          const Icon(Icons.location_on_rounded, color: Colors.blue, size: 30),
                                          Container(
                                            width: 2,
                                            height: 20,
                                            color: Colors.grey[300],
                                          ),
                                          const Icon(Icons.location_on_rounded, color: Colors.red, size: 30),
                                        ],
                                      ),
                                      const SizedBox(width: 12),

                                      // Columna de texto
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(ruta.inicio, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('Origen', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            const SizedBox(height: 16),
                                            Text(ruta.fin, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text('Destino', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              _servicio.cargarRutas(_tipoDoc, _numDoc, _codOperacion);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainBlueColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainBlueColor),
                        ),
                        const SizedBox(height: 16),
                        Text('Cargando rutas...', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
