import 'package:embarques_tdp/src/models/rutas/ruta_listar.dart';
import 'package:embarques_tdp/src/pages/rutas/ruta_detalle_page.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:embarques_tdp/src/services/rutas_service.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RutaListPage extends StatefulWidget {
  const RutaListPage({Key? key}) : super(key: key);

  @override
  _RutaListPageState createState() => _RutaListPageState();
}

class _RutaListPageState extends State<RutaListPage> {
  final RutaListarServicio _servicio = RutaListarServicio();
  late String _tipoDoc;
  late String _numDoc;
  late String _codOperacion;

  //bool _isSearching = false;
  String _searchQuery = '';
  DateTime _horaConsulta = DateTime.now();
  bool _isRefreshing = false;

  // Variables para filtros dinámicos
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
      _tipoDoc = usuarioProvider.usuario.tipoDoc;
      _numDoc = usuarioProvider.usuario.numDoc;
      _codOperacion = usuarioProvider.usuario.codOperacion;

      await _servicio.cargarRutas(_tipoDoc, _numDoc, _codOperacion);

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

  void _procesarNuevasRutas(List<RutaListar> rutas) {
    // Extraer tipos únicos
    final nuevosTipos = <String>{};
    for (final ruta in rutas) {
      if (ruta.tipo.isNotEmpty) {
        nuevosTipos.add(ruta.tipo);
      }
    }

    // Solo actualizar si hay cambios
    if (!_compararConjuntos(nuevosTipos, _tiposRuta)) {
      setState(() {
        _tiposRuta = nuevosTipos;
        _todasLasRutas = rutas;

        // Mantener el estado de los filtros existentes
        final nuevosFiltros = <String, bool>{};
        for (final tipo in nuevosTipos) {
          nuevosFiltros[tipo] = _filtrosActivos[tipo] ?? false;
        }
        _filtrosActivos = nuevosFiltros;
      });
    } else if (_todasLasRutas != rutas) {
      // Actualizar solo la lista de rutas si los tipos no cambiaron
      setState(() {
        _todasLasRutas = rutas;
      });
    }
  }

  bool _compararConjuntos(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;
    for (final item in set1) {
      if (!set2.contains(item)) return false;
    }
    return true;
  }

  List<RutaListar> _aplicarFiltros(List<RutaListar> rutas) {
    // Si no hay filtros activos, mostrar todas las rutas
    if (!_filtrosActivos.values.any((isActive) => isActive)) {
      return rutas;
    }

    // Filtrar por los tipos seleccionados
    return rutas.where((ruta) {
      return _filtrosActivos[ruta.tipo] == true;
    }).toList();
  }

  List<RutaListar> _aplicarBusqueda(List<RutaListar> rutas) {
    if (_searchQuery.isEmpty) return rutas;

    return rutas.where((ruta) {
      return ruta.destino.toLowerCase().contains(_searchQuery.toLowerCase()) || ruta.origen.toLowerCase().contains(_searchQuery.toLowerCase()) || ruta.inicio.toLowerCase().contains(_searchQuery.toLowerCase()) || ruta.fin.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      _horaConsulta = DateTime.now();
    });

    try {
      await _servicio.cargarRutas(_tipoDoc, _numDoc, _codOperacion);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al actualizar: $e';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
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
        title: Text('Rutas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
        ),
        actions: [
          // if (!_isSearching)
          // IconButton(
          //   icon: const Icon(Icons.search, color: Colors.white),
          //   onPressed: () {
          //     setState(() {
          //       _isSearching = true;
          //     });
          //   },
          // ),
          // if (_isSearching)
          //   IconButton(
          //     icon: const Icon(Icons.close, color: Colors.white),
          //     onPressed: () {
          //       setState(() {
          //         _searchQuery = '';
          //         _isSearching = false;
          //       });
          //     },
          //   ),
        ],
        elevation: 4,
      ),
      body: StreamBuilder<List<RutaListar>>(
        stream: _servicio.rutasStream,
        builder: (context, snapshot) {
          // Procesar datos cuando lleguen
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _procesarNuevasRutas(snapshot.data!);
            });
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.mainBlueColor,
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: TextField(
                      //autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar ruta...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.grey, // color cuando NO está enfocado
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.grey, // color cuando SÍ está enfocado
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, // padding lateral
                          vertical: 10, // padding arriba/abajo
                        ),
                      ),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 33, 31, 31),
                        fontSize: 18,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    )),

                // Filtros dinámicos
                if (_tiposRuta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 5, right: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.tune, color: AppColors.mainBlueColor),
                        const SizedBox(width: 5),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _tiposRuta.map((tipo) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: FilterChip(
                                    label: Text(tipo),
                                    selected: _filtrosActivos[tipo] ?? false,
                                    onSelected: (selected) {
                                      setState(() {
                                        _filtrosActivos[tipo] = selected;
                                      });
                                    },
                                    selectedColor: AppColors.activeFilterColor,
                                    labelStyle: TextStyle(
                                      color: (_filtrosActivos[tipo] ?? false) ? Colors.white : Colors.black,
                                    ),
                                    showCheckmark: false,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Fecha de Consulta: ',
                      style: TextStyle(fontSize: 10, height: 0.7, color: Color.fromARGB(255, 87, 86, 86)),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(_horaConsulta),
                      style: const TextStyle(fontSize: 13, height: 0.7, color: AppColors.greenColor, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 12)
                  ],
                ),

                // Contenido principal
                Expanded(
                  child: _buildContenido(snapshot),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContenido(AsyncSnapshot<List<RutaListar>> snapshot) {
    if (snapshot.hasError) {
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

    if (!snapshot.hasData || _isLoading) {
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
    }

    final rutasFiltradas = _aplicarFiltros(_todasLasRutas);
    final rutasBusqueda = _aplicarBusqueda(rutasFiltradas);

    if (rutasBusqueda.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron rutas con "$_searchQuery"'
                  : _filtrosActivos.values.any((isActive) => isActive)
                      ? 'No hay rutas con los filtros aplicados'
                      : 'No se encontraron rutas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_filtrosActivos.values.any((isActive) => isActive) || _searchQuery.isNotEmpty) const SizedBox(height: 16),
            if (_filtrosActivos.values.any((isActive) => isActive) || _searchQuery.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainBlueColor, // color de fondo
                  foregroundColor: Colors.white, // color del texto / iconos
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  setState(() {
                    // Limpiar filtros y búsqueda
                    for (var tipo in _filtrosActivos.keys) {
                      _filtrosActivos[tipo] = false;
                    }
                    _searchQuery = '';

                    /// _isSearching = false;
                  });
                },
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rutasBusqueda.length,
      itemBuilder: (context, index) {
        final ruta = rutasBusqueda[index];
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
                      // Row(
                      //   children: [
                      //     const Icon(Icons.route, color: AppColors.mainBlueColor, size: 30),
                      //     const SizedBox(width: 2),
                      //     Text('${ruta.origen} - ${ruta.destino}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                      //   ],
                      // ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // para que se alinee arriba}
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.route, color: AppColors.mainBlueColor, size: 30),
                            const SizedBox(width: 4),
                            // Texto que se adapta al espacio
                            Expanded(
                              child: Text(
                                '${ruta.origen} - ${ruta.destino}',
                                style: const TextStyle(
                                  fontSize: 25, // puedes bajar de 25 para evitar overflow
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true, // permite salto de línea
                                overflow: TextOverflow.visible, // no corta con "..."
                                maxLines: 2, // máximo de líneas (ajústalo a lo que quieras)
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Badge con el tipo de ruta
                      // Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.mainBlueColor.withOpacity(0.1),
                      //     borderRadius: BorderRadius.circular(12),
                      //   ),
                      //   child: Text(
                      //     ruta.tipo,
                      //     style: const TextStyle(
                      //       color: AppColors.mainBlueColor,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Información de origen y destino
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna de iconos
                        Column(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.blue, size: 25),
                            Container(
                              width: 2,
                              height: 20,
                              color: Colors.grey[300],
                            ),
                            const Icon(Icons.location_on_rounded, color: Colors.red, size: 25),
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
                              Text('Inicio', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 16),
                              Text(ruta.fin, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Fin', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
