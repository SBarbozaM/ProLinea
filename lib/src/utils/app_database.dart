import 'package:embarques_tdp/src/models/Copiloto/geocera_ordenada_model.dart';
import 'package:embarques_tdp/src/models/Copiloto/geocerca_model.dart';
import 'package:embarques_tdp/src/models/Copiloto/grocerca_ruta_model.dart';
import 'package:embarques_tdp/src/models/Copiloto/operacion_model.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/logger_model.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/usuario.dart';
import 'package:embarques_tdp/src/providers/providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pasajero_habilitado.dart';
import '../models/punto_embarque.dart';
import '../models/viaje.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  AppDatabase() {}
  AppDatabase._init();
  static Database? _database;
  //NOMBRE DE LAS TABLAS
  final String tablaUsuario = 'usuario';
  final String tablaViaje = 'viaje';
  final String tablaViajeDomicilio = 'viaje_domicilio';
  final String tablaPasajero = 'pasajero';
  final String tablaPasajeroDomicilio = 'pasajero_domicilio';
  final String tablaPosiblesPasajeroDomicilio = 'posibles_pasajero_domicilio';
  final String tablaPasajeroHabilitado = 'pasajero_habilitado';
  final String tablaPuntoEmbarque = 'punto_embarque';
  final String tablaTripulante = 'tripulante';
  final String tablaPrereserva = 'prereserva';
  final String tablaBitacora = 'bitacora';
  final String tablaParada = 'parada';
  final String tablaParadero = 'paradero';
  final String tablaJornada = 'jornada';
  final String tablaAccionUsuario = 'accionesUsuario';
  final String tablaGeocerca = 'geocerca';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('AppBusBD.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 12,
      onCreate: _onCreateDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (newVersion < 10) {
          await db.execute('''
            CREATE TABLE operaciones (
              idOperacion TEXT PRIMARY KEY,
              nombre TEXT
            )
          ''');
        }
        if (newVersion < 11) {
          await db.execute('''
          CREATE TABLE geocercas_rutas (
            orden INTEGER ,
            idGeocerca TEXT,
            rutaCod TEXT
          )
          ''');
        }
        // if (newVersion < 12) {
        //   await db.execute('''
        //     CREATE TABLE operaciones (
        //       idOperacion TEXT PRIMARY KEY,
        //       nombre TEXT
        //     )
        //   ''');
        // }

        // if (oldVersion < newVersion) {
        //   await db.execute('''
        //     CREATE TABLE geocerca (
        //       idGeocerca TEXT PRIMARY KEY,
        //       nombre TEXT,
        //       vMaximaBuses INTEGER,
        //       vMaximaCagueros INTEGER,
        //       tipo INTEGER,
        //       fechaRegistro TEXT
        //     );
        //   ''');
        //   await db.execute('''
        //     CREATE TABLE geocerca_detalle (
        //       id INTEGER PRIMARY KEY,
        //       idGeocerca TEXT,
        //       latitud REAL,
        //       longitud REAL,
        //       radio INTEGER,
        //       fechaRegistro TEXT,
        //       FOREIGN KEY (idGeocerca) REFERENCES geocerca(idGeocerca)
        //     );
        //   ''');
        //   await db.execute('''
        //     CREATE TABLE ubicacion_velocidad (
        //       id INTEGER PRIMARY KEY AUTOINCREMENT,
        //       latitud REAL,
        //       longitud REAL,
        //       velocidad REAL,
        //       fechaRegistro TEXT
        //     );
        //   ''');
        // }
      },
    );
  }

  Future _onCreateDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaUsuario(
        idUsuario INTEGER PRIMARY KEY AUTOINCREMENT,
        tipoDoc TEXT,
        numDoc TEXT,
        usuarioId TEXT,
        apellidoPat TEXT,
        apellidoMat TEXT,
        nombres TEXT,
        perfil TEXT,
        codOperacion TEXT,
        nombreOperacion TEXT,
        viajeEmp TEXT,
        unidadEmp TEXT,
        placaEmp TEXT,
        fechaEmp TEXT,
        domicilio TEXT,
        idperfil TEXT,
        vinculacionActiva TEXT,
        sesionActiva TEXT,
        sesionSincronizada TEXT,
        logSincronizado TEXT,
        Log TEXT,
        equipo TEXT,
        claveMaestra TEXT
      )
    ''');

    await db.execute('''
    CREATE TABLE $tablaViaje(
      nroViaje TEXT,
      codRuta TEXT,
      codOperacion TEXT,
      subOperacionId TEXT,
      subOperacionNombre TEXT,
      origen TEXT,
      destino TEXT,
      fechaSalida TEXT,
      horaSalida TEXT,
      servicio TEXT,
      unidad TEXT,
      cantAsientos INTEGER,
      cantReservados INTEGER,
      cantDisponibles INTEGER,
      cantEmbarcados INTEGER,
      estadoEmbarque INTEGER,
      porSincronizar INTEGER,
      ruc TEXT,
      razonSocial TEXT,
      telefono TEXT,
      direccion TEXT,
      caracterSplit TEXT,
      indexLectura TEXT,
      corteLadoLectura TEXT,
      odometroInicial INTEGER,
      cordenadaInicial TEXT,
      odometroFinal INTEGER,
      cordenadaFinal TEXT,
      seleccionado TEXT,
      estadoViaje TEXT,
      estadoInicioViaje TEXT,
      fechaConsultada TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaViajeDomicilio(
      nroViaje TEXT,
      codRuta TEXT,
      codOperacion TEXT,
      origen TEXT,
      destino TEXT,
      fechaSalida TEXT,
      horaSalida TEXT,
      servicio TEXT,
      unidad TEXT,
      cantAsientos INTEGER,
      cantReservados INTEGER,
      cantDisponibles INTEGER,
      cantEmbarcados INTEGER,
      estadoEmbarque INTEGER,
      porSincronizar INTEGER,
      ruc TEXT,
      razonSocial TEXT,
      telefono TEXT,
      direccion TEXT,
      sentido TEXT,
      horaLlegada TEXT,
      odometroInicial INTEGER,
      cordenadaInicial TEXT,
      odometroFinal INTEGER,
      cordenadaFinal TEXT,
      seleccionado TEXT,
      estadoViaje TEXT,
      estadoInicioViaje TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaPuntoEmbarque(
      id TEXT,
      nombre TEXT,
      nroViaje TEXT,
      eliminado INTEGER,
      sincronizado TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaAccionUsuario(
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      accion TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaTripulante(
      tipoDoc TEXT,
      numDoc TEXT,
      nombres TEXT,
      nroViaje TEXT,
      tipo TEXT,
      orden TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaPasajero(
      tipoDoc TEXT,
      numDoc TEXT,
      numeroDoc TEXT,
      apellidos TEXT,
      nombres TEXT,
      nroViaje TEXT,
      asiento INTEGER,
      embarcado INTEGER,
      idEmbarque TEXT,
      lugarEmbarque TEXT,
      fechaEmbarque TEXT,
      fechaViaje TEXT,
      idEmbarqueReal TEXT,
      idDesembarque TEXT,
      lugarDesembarque TEXT,
      fechaDesembarque TEXT,
      idDesembarqueReal TEXT,
      idServicio TEXT,
      servicio TEXT,
      idRuta TEXT,
      ruta TEXT,
      origen TEXT,
      destino TEXT,
      unidad TEXT,
      estado TEXT,
      coordenadas TEXT,
      embarcadoPor TEXT,
      sincronizar TEXT   
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaPasajeroDomicilio(
      nroViaje TEXT,
      tipoDoc TEXT,
      numDoc TEXT,
      apellidos TEXT,
      nombres TEXT,
      asiento TEXT,
      embarcado INTEGER,
      fechaViaje TEXT,
      fechaEmbarque TEXT,
      fechaDesembarque TEXT,
      estado TEXT,
      horaRecojo TEXT,
      direccion TEXT,
      distrito TEXT,
      coordenadas TEXT,
      fechaArriboUnidad TEXT,
      idEmbarqueReal TEXT,
      idDesembarqueReal TEXT,
      embarcadoAux INTEGER,
      coordenadasParadero TEXT,
      modificado INTEGER,
      modificadoFechaArribo INTEGER,
      modificadoAccion INTEGER,
      nuevo TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaPosiblesPasajeroDomicilio(
    nroViaje TEXT,
      tipoDoc TEXT,
      numDoc TEXT,
      apellidos TEXT,
      nombres TEXT,
      asiento TEXT,
      embarcado INTEGER,
      fechaViaje TEXT,
      fechaEmbarque TEXT,
      fechaDesembarque TEXT,
      estado TEXT,
      horaRecojo TEXT,
      direccion TEXT,
      distrito TEXT,
      coordenadas TEXT,
      fechaArriboUnidad TEXT,
      idEmbarqueReal TEXT,
      idDesembarqueReal TEXT,
      embarcadoAux INTEGER,
      coordenadasParadero TEXT,
      modificado INTEGER,
      modificadoFechaArribo INTEGER,
      modificadoAccion INTEGER,
      nuevo TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaParada(
      nroViaje TEXT,
      direccion TEXT,
      distrito TEXT,
      coordenadas TEXT,
      horaRecojo TEXT,
      orden TEXT,
      recojoTaxi TEXT,
      estado TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaParadero(
      id TEXT,
      nombre TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaPasajeroHabilitado(
      tipoDoc TEXT,
      numDoc TEXT,
      apellidos TEXT,
      nombres TEXT,
      nroViaje TEXT,
      fechaViaje TEXT,
      origen TEXT,
      destino TEXT,
      unidad TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaPrereserva(
      tipoDoc TEXT,
      numDoc TEXT,
      numeroDoc TEXT,
      apellidos TEXT,
      nombres TEXT,
      nroViaje TEXT,
      asiento INTEGER,
      embarcado INTEGER,
      idEmbarque TEXT,
      lugarEmbarque TEXT,
      fechaEmbarque TEXT,
      fechaViaje TEXT,
      idEmbarqueReal TEXT,
      idDesembarque TEXT,
      lugarDesembarque TEXT,
      fechaDesembarque TEXT,
      idDesembarqueReal TEXT,
      idServicio TEXT,
      servicio TEXT,
      idRuta TEXT,
      ruta TEXT,
      origen TEXT,
      destino TEXT,
      unidad TEXT,
      estado TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaBitacora(
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      ID_Dispositivo TEXT,
      NumDoc TEXT,
      CodOperacion TEXT,
      Fecha TEXT,
      Accion TEXT,
      Estado TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE $tablaJornada(
      ID INTEGER PRIMARY KEY AUTOINCREMENT,
      VIAJ_Nro_Viaje TEXT,
      DEHO_Turno TEXT,
      VIAJ_TipoDoc TEXT,
      VIAJ_NOMBRE TEXT,
      VIAJ_Dni TEXT,
      DECO_Inicio TEXT,
      DECO_Fin TEXT,
      DEHO_Cordenadas_Inicio TEXT,
      DEHO_Cordenadas_Fin TEXT,
      DEHO_Usuario TEXT,
      DEHO_PC TEXT,
      DEHO_Fecha TEXT,
      DEHO_Tipo TEXT,
      Estado TEXT,
      EstadoBDInicio TEXT,
      EstadoBDFin TEXT
    )
    ''');
    await db.execute('''
    CREATE TABLE geocerca (
      idGeocerca TEXT PRIMARY KEY,  
      nombre TEXT,                 
      vMaximaBuses INTEGER,        
      vMaximaCagueros INTEGER,      
      tipo INTEGER,                
      fechaRegistro TEXT          
    );
  ''');

    await db.execute('''
    CREATE TABLE geocerca_detalle (
      id INTEGER PRIMARY KEY,  -- ID único del detalle
      idGeocerca TEXT,                       -- Relación con la geocerca
      latitud REAL,                           -- Latitud del detalle
      longitud REAL,                          -- Longitud del detalle
      radio INTEGER,                             -- Radio de la geocerca
      fechaRegistro TEXT,                    -- Fecha de registro del detalle
      FOREIGN KEY (idGeocerca) REFERENCES geocerca(idGeocerca)  -- Relación con la tabla geocerca
    );
  ''');

    await db.execute('''
    CREATE TABLE ubicacion_velocidad (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitud REAL,
      longitud REAL,
      velocidad REAL,
      fechaRegistro TEXT
    );
  ''');

    await db.execute('''
            CREATE TABLE operaciones (
              idOperacion TEXT PRIMARY KEY,
              nombre TEXT
            )
          ''');

    await db.execute('''
    CREATE TABLE geocercas_rutas (
      orden INTEGER  ,
      idGeocerca TEXT,
      rutaCod TEXT
    )
    ''');
  }

  Future<int> insertGeocercaRuta(GeocercaRuta geocercaRuta) async {
    final db = await instance.database;

    // Verificamos si ya existe un registro con el mismo idGeocerca y rutaCod
    // final existing = await db.query(
    //   'geocercas_rutas',
    //   where: 'idGeocerca = ? AND rutaCod = ?',
    //   whereArgs: [geocercaRuta.idGeocerca, geocercaRuta.rutaCod],
    // );

    //if (existing.isEmpty) {
    // Si no existe, insertamos el nuevo registro
    return await db.insert('geocercas_rutas', geocercaRuta.toMap());
    // } else {
    //   // Si ya existe, no insertamos nada y retornamos 0
    //   return 0;
    // }
  }

  Future<void> insertOperacion(Operacion operacion) async {
    final db = await instance.database;

    await db.insert(
      'operaciones',
      operacion.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Esto reemplazará si ya existe un idOperacion
    );
  }

  Future<List<Operacion>> getOperacionesFromDB() async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query('operaciones');

    return List.generate(maps.length, (i) {
      return Operacion.fromJson(maps[i]);
    });
  }

  Future<void> insertarUbicacionVelocidad(Position position) async {
    final db = await instance.database;

    // Crear el mapa de los datos que se van a insertar
    Map<String, dynamic> data = {
      'latitud': position.latitude,
      'longitud': position.longitude,
      'velocidad': position.speed.round(), // Velocidad en metros por segundo
      'fechaRegistro': DateTime.now().toIso8601String(),
    };

    // Insertar los datos en la tabla ubicacion_velocidad
    await db.insert(
      'ubicacion_velocidad',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerUbicacionesVelocidad() async {
    final db = await instance.database;

    // Consultar todos los registros en la tabla ubicacion_velocidad
    final List<Map<String, dynamic>> result = await db.query('ubicacion_velocidad');

    return result;
  }

  /*** TABLA  USUARIO ***/

  Future<void> insertarUsuario(Usuario usuario) async {
    final db = await instance.database;
    await db.delete(tablaUsuario);
    await db.delete(tablaAccionUsuario);

    //Verificamos que no exista el usuario registrado
    // List<Map<String, dynamic>> existeUsuario = await db.query(tablaUsuario, where: "tipoDoc = ? and numDoc = ?", whereArgs: [usuario.tipoDoc.trim(), usuario.numDoc.trim()]);

    await db.insert(tablaUsuario, usuario.toMapDatabase());
  }

  // Insertar una geocerca
  Future<void> insertarGeocerca(Geocerca geocerca) async {
    final db = await instance.database;
    await db.insert(
      tablaGeocerca,
      geocerca.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Geocerca>> obtenerGeocercas() async {
    final db = await instance.database;

    // Obtener todas las geocercas
    final List<Map<String, dynamic>> maps = await db.query('geocerca');

    // Crear una lista de objetos Geocerca a partir de los resultados
    return List.generate(maps.length, (i) {
      // Cada objeto Geocerca es creado desde el mapa obtenido de la base de datos
      return Geocerca.fromJson(maps[i]);
    });
  }

  Future<List<Geocerca>> obtenerGeocercasPorTipo(int tipo, String idGeocerca) async {
    final db = await instance.database;

    String whereClause = 'idGeocerca LIKE ?';
    List<dynamic> whereArgs = ['%$idGeocerca%'];

    if (tipo != 0) {
      whereClause += ' AND tipo = ?';
      whereArgs.add(tipo);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'geocerca',
      where: whereClause,
      whereArgs: whereArgs,
    );

    // final List<Map<String, dynamic>> maps = await db.query(
    //   'geocerca',
    //   where: 'idGeocerca LIKE ? AND tipo = ?',
    //   whereArgs: ['%$idGeocerca%', tipo],
    // );

    return List.generate(maps.length, (i) {
      return Geocerca.fromJson(maps[i]);
    });
  }

  Future<List<GeocercaOrdenada>> obtenerGeocercasOrdenRuta(String ruta) async {
    final db = await instance.database;

    // Realizamos la consulta JOIN con el formato adecuado
    final result = await db.rawQuery('''
    SELECT 
      GR.Orden, 
      G.idGeocerca, 
      G.nombre, 
      G.vMaximaBuses, 
      G.tipo, 
      GR.rutaCod
    FROM 
      geocerca G
    INNER JOIN 
      geocercas_rutas GR
    ON 
      G.idGeocerca = GR.idGeocerca
    WHERE 
      GR.rutaCod = ?
    ORDER BY 
      GR.Orden ASC
  ''', [ruta]);

    List<GeocercaOrdenada> geocercasOrdenadas = result.map((data) {
      return GeocercaOrdenada.fromMap(data);
    }).toList();

    return geocercasOrdenadas;
  }

  Future<Geocerca?> obtenerGeocercaPorId(String idGeocerca) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'geocerca',
      where: 'idGeocerca = ?',
      whereArgs: [idGeocerca],
    );

    if (maps.isNotEmpty) {
      return Geocerca.fromJson(maps.first);
    }
    return null;
  }

  Future<GeocercaOrdenada?> obtenerGeocercaOrdenadaPorId(String idGeocerca) async {
    final db = await instance.database;

    // Hacemos la consulta a la base de datos uniendo las tablas 'geocerca' y 'geocercas_rutas'
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        GR.Orden, 
        G.idGeocerca, 
        G.nombre, 
        G.vMaximaBuses, 
        G.tipo, 
        GR.rutaCod
      FROM 
        geocerca G
      INNER JOIN 
        geocercas_rutas GR
      ON 
        G.idGeocerca = GR.idGeocerca
      WHERE 
        G.idGeocerca = ?
    ''', [idGeocerca]);

    if (maps.isNotEmpty) {
      return GeocercaOrdenada.fromMap(maps.first); // Convertimos el primer resultado en un GeocercaOrdenada
    }
    return null; // Si no se encuentra, retornamos null
  }

  Future<GeocercaOrdenada?> obtenerGeocercaOrdenadaProxima(int orden, String rutaCod) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        GR.Orden, 
        G.idGeocerca, 
        G.nombre, 
        G.vMaximaBuses, 
        G.tipo, 
        GR.rutaCod
      FROM 
        geocerca G
      INNER JOIN 
        geocercas_rutas GR
      ON 
        G.idGeocerca = GR.idGeocerca
      WHERE 
        GR.Orden = ?
    ''', [orden]);

    if (maps.isNotEmpty) {
      return GeocercaOrdenada.fromMap(maps.first); // Convertimos el primer resultado en un GeocercaOrdenada
    }
    return null; // Si no se encuentra, retornamos null
  }

  Future<List<GeocercaDetalle>> obtenerDetallesGeocerca() async {
    final db = await instance.database;

    // Obtener los detalles de la geocerca por ID
    final List<Map<String, dynamic>> maps = await db.query('geocerca_detalle');

    // Crear una lista de objetos GeocercaDetalle a partir de los resultados
    return List.generate(maps.length, (i) {
      return GeocercaDetalle.fromJson(maps[i]);
    });
  }

  Future<List<GeocercaDetalle>> obtenerDetallesGeocercaPorId(String idGeocerca) async {
    final db = await instance.database;

    // Obtener los detalles de la geocerca por ID
    final List<Map<String, dynamic>> maps = await db.query(
      'geocerca_detalle',
      where: 'idGeocerca = ?',
      whereArgs: [idGeocerca],
      orderBy: 'radio ASC',
    );

    // Crear una lista de objetos GeocercaDetalle a partir de los resultados
    return List.generate(maps.length, (i) {
      return GeocercaDetalle.fromJson(maps[i]);
    });
  }

  Future<void> eliminarGeocerca(String idGeocerca) async {
    final db = await instance.database;
    await db.delete(
      tablaGeocerca,
      where: 'idGeocerca = ?',
      whereArgs: [idGeocerca],
    );
  }

  Future<void> insertarActualizarGeocerca(Geocerca geocerca) async {
    final db = await instance.database;

    // Verificar si ya existe una geocerca con todos los valores iguales
    List<Map<String, dynamic>> geocercaExistente = await db.query(
      'geocerca',
      where: '''
    idGeocerca = ? AND 
    nombre = ? AND 
    vMaximaBuses = ? AND 
    vMaximaCagueros = ? AND 
    tipo = ? 
    ''',
      whereArgs: [geocerca.idGeocerca, geocerca.nombre, geocerca.vMaximaBuses, geocerca.vMaximaCagueros, geocerca.tipo],
    );

    if (geocercaExistente.isEmpty) {
      // Si no existe una geocerca con estos valores, revisa solo el ID
      List<Map<String, dynamic>> existeIdGeocerca = await db.query(
        'geocerca',
        where: 'idGeocerca = ?',
        whereArgs: [geocerca.idGeocerca],
      );

      if (existeIdGeocerca.isEmpty) {
        // Si el ID de la geocerca no existe, insertar como nueva entrada
        await db.insert('geocerca', geocerca.toMap());
      } else {
        // Si existe el ID pero con valores diferentes, actualiza
        await db.update(
          'geocerca',
          geocerca.toMap(),
          where: 'idGeocerca = ?',
          whereArgs: [geocerca.idGeocerca],
        );
      }
    } else {
      // Si ya existe una geocerca con todos los valores iguales, no hacer nada
      print('La geocerca ya existe con todos los mismos valores.');
    }
  }

  Future<void> insertarActualizarGeocercaDetalle(GeocercaDetalle detalle) async {
    final db = await instance.database;

    // Verificar si ya existe un detalle de geocerca con los mismos valores
    List<Map<String, dynamic>> detalleExistente = await db.query(
      'geocerca_detalle',
      where: '''
    id = ? AND 
    idGeocerca = ? AND 
    latitud = ? AND 
    longitud = ? AND 
    radio = ?
    ''',
      whereArgs: [
        detalle.id,
        detalle.idGeocerca,
        detalle.latitud,
        detalle.longitud,
        detalle.radio,
      ],
    );

    if (detalleExistente.isEmpty) {
      // Si no existe el detalle, insertarlo
      await db.insert('geocerca_detalle', detalle.toMap());
    } else {
      // Si existe un detalle, actualizarlo
      await db.update(
        'geocerca_detalle',
        detalle.toMap(),
        where: 'id = ?',
        whereArgs: [detalle.id],
      );
    }
  }

  Future<void> eliminarDatosDeTablasGeocercas() async {
    final db = await instance.database;

    try {
      // Eliminar todos los registros de la tabla 'geocerca_detalle'
      await db.execute('DELETE FROM geocerca_detalle');
      await db.execute('DELETE FROM geocerca');
      await db.execute('DELETE FROM geocercas_rutas');

      print("Datos de las tablas eliminados con éxito.");
    } catch (e) {
      print("Error al eliminar los datos: $e");
    }
  }

  /*** TABLA  VIAJE ***/

  Future<void> insertarViaje(Viaje viaje) async {
    final db = await instance.database;

    List<Map<String, dynamic>> existeViaje = await db.query(tablaViaje, where: "nroViaje = ? AND estadoEmbarque = ?", whereArgs: [viaje.nroViaje, 0]);

    if (existeViaje.isEmpty) {
      await db.insert(tablaViaje, viaje.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(tablaViaje, viaje.toMapDatabase(), where: "nroViaje = ?", whereArgs: [viaje.nroViaje]);
    }

    if (viaje.pasajeros.length > 0) {
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        await insertarActualizarPasajero(viaje.pasajeros[i]);
      }
    }

    if (viaje.puntosEmbarque.length > 0) {
      for (int i = 0; i < viaje.puntosEmbarque.length; i++) {
        await insertarPuntoEmbarque(viaje.puntosEmbarque[i]);
      }
    }

    if (viaje.tripulantes.length > 0) {
      for (int i = 0; i < viaje.tripulantes.length; i++) {
        await insertarTripulante(viaje.tripulantes[i]);
      }
    }
  }

  Future<void> actualizarSoloViaje(Viaje viaje) async {
    final db = await instance.database;

    await db.update(tablaViaje, viaje.toMapDatabase(), where: "nroViaje = ? AND codOperacion = ?", whereArgs: [viaje.nroViaje, viaje.codOperacion]);
  }

  Future<List<Viaje>> obtenerViaje() async {
    final db = await instance.database;
    List<Map<String, dynamic>> viajes = await db.query(tablaViaje, where: "estadoEmbarque = ?", whereArgs: [0], limit: 1);

    return List.generate(viajes.length, (i) {
      return Viaje.constructor(
        nroViaje: viajes[i]['nroViaje'],
        codRuta: viajes[i]['codRuta'],
        codOperacion: viajes[i]['codOperacion'],
        subOperacionId: viajes[i]['subOperacionId'],
        subOperacionNombre: viajes[i]['subOperacionNombre'],
        origen: viajes[i]['origen'],
        destino: viajes[i]['destino'],
        fechaSalida: viajes[i]['fechaSalida'],
        horaSalida: viajes[i]['horaSalida'],
        servicio: viajes[i]['servicio'],
        unidad: viajes[i]['unidad'],
        cantAsientos: viajes[i]['cantAsientos'],
        cantReservados: viajes[i]['cantReservados'],
        cantDisponibles: viajes[i]['cantDisponibles'],
        cantEmbarcados: viajes[i]['cantEmbarcados'],
        estadoEmbarque: viajes[i]['estadoEmbarque'],
        porSincronizar: viajes[i]['porSincronizar'],
        ruc: viajes[i]['ruc'],
        razonSocial: viajes[i]['razonSocial'],
        telefono: viajes[i]['telefono'],
        direccion: viajes[i]['direccion'],
        caracterSplit: viajes[i]['caracterSplit'],
        indexLectura: viajes[i]['indexLectura'],
        corteLadoCantidad: viajes[i]['corteLadoLectura'],
        cordenadaInicial: "",
        cordenadaFinal: "",
      );
    });
  }

  Future<List<Viaje>> obtenerTodosViajes() async {
    final db = await instance.database;
    List<Map<String, dynamic>> viajes = await db.query(tablaViaje);

    return List.generate(viajes.length, (i) {
      return Viaje.constructor(
        nroViaje: viajes[i]['nroViaje'],
        codRuta: viajes[i]['codRuta'],
        codOperacion: viajes[i]['codOperacion'],
        subOperacionId: viajes[i]['subOperacionId'],
        subOperacionNombre: viajes[i]['subOperacionNombre'],
        origen: viajes[i]['origen'],
        destino: viajes[i]['destino'],
        fechaSalida: viajes[i]['fechaSalida'],
        horaSalida: viajes[i]['horaSalida'],
        servicio: viajes[i]['servicio'],
        unidad: viajes[i]['unidad'],
        cantAsientos: viajes[i]['cantAsientos'],
        cantReservados: viajes[i]['cantReservados'],
        cantDisponibles: viajes[i]['cantDisponibles'],
        cantEmbarcados: viajes[i]['cantEmbarcados'],
        estadoEmbarque: viajes[i]['estadoEmbarque'],
        porSincronizar: viajes[i]['porSincronizar'],
        ruc: viajes[i]['ruc'],
        razonSocial: viajes[i]['razonSocial'],
        telefono: viajes[i]['telefono'],
        direccion: viajes[i]['direccion'],
        caracterSplit: viajes[i]['caracterSplit'],
        indexLectura: viajes[i]['indexLectura'],
        corteLadoCantidad: viajes[i]['corteLadoLectura'],
        cordenadaInicial: "",
        cordenadaFinal: "",
      );
    });
  }

  Future<void> eliminarTodoDeUnViaje(String nroViaje) async {
    final db = await instance.database;

    //Eliminamos los puntos de embarque
    await db.delete(tablaPuntoEmbarque, where: "nroViaje = ?", whereArgs: [nroViaje]);
    //Eliminamos los tripulantes
    await db.delete(tablaTripulante, where: "nroViaje = ?", whereArgs: [nroViaje]);

    //Eliminamos los pasajers
    await db.delete(tablaPasajero, where: "nroViaje = ?", whereArgs: [nroViaje]);

    //Eliminamos el viaje
    await db.delete(tablaViaje, where: "nroViaje = ?", whereArgs: [nroViaje]);

    //Eliminamos los Pasajeros habilitas
    await db.delete(tablaPasajeroHabilitado);
  }

  /*** TABLA  PASAJERO ***/

  Future<void> insertarActualizarPasajero(Pasajero pasajero) async {
    final db = await instance.database;

    List<Map<String, dynamic>> existePasajero = await db.query(tablaPasajero, where: "tipoDoc = ? AND numDoc = ? AND nroViaje = ?", whereArgs: [pasajero.tipoDoc, pasajero.numDoc, pasajero.nroViaje]);

    if (existePasajero.isEmpty) {
      await db.insert(tablaPasajero, pasajero.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(tablaPasajero, pasajero.toMapDatabase(), where: "tipoDoc = ? AND numDoc = ? AND nroViaje = ?", whereArgs: [pasajero.tipoDoc, pasajero.numDoc, pasajero.nroViaje]);
    }
  }

  Future<List<Pasajero>> obtenerTodosPasajeros() async {
    final db = await instance.database;
    List<Map<String, dynamic>> pasajeros = await db.query(tablaPasajero);

    return List.generate(pasajeros.length, (i) {
      return Pasajero.constructor(
        nroViaje: pasajeros[i]['nroViaje'],
        tipoDoc: pasajeros[i]['tipoDoc'],
        numDoc: pasajeros[i]['numDoc'],
        numeroDoc: pasajeros[i]['codExterno'],
        apellidos: pasajeros[i]['apellidos'],
        nombres: pasajeros[i]['nombres'],
        asiento: pasajeros[i]['asiento'],
        embarcado: pasajeros[i]['embarcado'],
        idEmbarque: pasajeros[i]['idEmbarque'],
        lugarEmbarque: pasajeros[i]['lugarEmbarque'],
        fechaEmbarque: pasajeros[i]['fechaEmbarque'],
        fechaViaje: pasajeros[i]['fechaViaje'],
        idEmbarqueReal: pasajeros[i]['idEmbarqueReal'],
        estado: pasajeros[i]['estado'],
        idDesembarque: pasajeros[i]['idDesembarque'],
        lugarDesembarque: pasajeros[i]['lugarDesembarque'],
        fechaDesembarque: pasajeros[i]['fechaDesembarque'],
        idDesembarqueReal: pasajeros[i]['idDesembarqueReal'],
        embarcadoPor: pasajeros[i]['embarcadoPor'],
        coordenadas: pasajeros[i]['coordenadas'],
      );
    });
  }

  Future<List<Pasajero>> obtenerTodosPasajerosDeUnViaje(String nroViaje) async {
    final db = await instance.database;
    List<Map<String, dynamic>> pasajeros = await db.query(tablaPasajero, where: "nroViaje = ?", whereArgs: [nroViaje]);

    return List.generate(pasajeros.length, (i) {
      return Pasajero.constructor(
        nroViaje: pasajeros[i]['nroViaje'],
        tipoDoc: pasajeros[i]['tipoDoc'],
        numDoc: pasajeros[i]['numDoc'],
        numeroDoc: pasajeros[i]['codExterno'],
        apellidos: pasajeros[i]['apellidos'],
        nombres: pasajeros[i]['nombres'],
        asiento: pasajeros[i]['asiento'],
        embarcado: pasajeros[i]['embarcado'],
        idEmbarque: pasajeros[i]['idEmbarque'],
        lugarEmbarque: pasajeros[i]['lugarEmbarque'],
        fechaEmbarque: pasajeros[i]['fechaEmbarque'],
        fechaViaje: pasajeros[i]['fechaViaje'],
        idEmbarqueReal: pasajeros[i]['idEmbarqueReal'],
        estado: pasajeros[i]['estado'],
        idDesembarque: pasajeros[i]['idDesembarque'],
        lugarDesembarque: pasajeros[i]['lugarDesembarque'],
        fechaDesembarque: pasajeros[i]['fechaDesembarque'],
        idDesembarqueReal: pasajeros[i]['idDesembarqueReal'],
        embarcadoPor: pasajeros[i]['embarcadoPor'],
        coordenadas: pasajeros[i]['coordenadas'],
      );
    });
  }

  Future<void> eliminarPasajero(Pasajero pasajero) async {
    final db = await instance.database;

    await db.delete(tablaPasajero, where: "tipoDoc = ? AND numDoc = ? AND nroViaje = ?", whereArgs: [pasajero.tipoDoc, pasajero.numDoc, pasajero.nroViaje]);
  }

  /*** TABLA  PUNTO EMBARQUE ***/
  Future<void> insertarPuntoEmbarque(PuntoEmbarque puntoEmbarque) async {
    final db = await instance.database;

    List<Map<String, dynamic>> existePuntoEmbarque = await db.query(tablaPuntoEmbarque, where: "id = ? AND nroViaje = ?", whereArgs: [puntoEmbarque.id, puntoEmbarque.nroViaje]);

    if (existePuntoEmbarque.isEmpty) {
      await db.insert(tablaPuntoEmbarque, puntoEmbarque.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> actualizarPuntoEmbarque(PuntoEmbarque puntoEmbarque) async {
    final db = await instance.database;

    await db.update(tablaPuntoEmbarque, puntoEmbarque.toMapDatabase(), where: "id = ? AND nroViaje = ?", whereArgs: [puntoEmbarque.id, puntoEmbarque.nroViaje]);
  }

  Future<List<PuntoEmbarque>> obtenerTodosPuntosEmbarque() async {
    final db = await instance.database;
    List<Map<String, dynamic>> puntos = await db.query(tablaPuntoEmbarque);

    return List.generate(puntos.length, (i) {
      return PuntoEmbarque(nroViaje: puntos[i]['nroViaje'], id: puntos[i]['id'], nombre: puntos[i]['nombre'], eliminado: puntos[i]['eliminado']);
    });
  }

  Future<List<PuntoEmbarque>> obtenerTodosPuntosEmbarqueDeViaje(Viaje viaje) async {
    final db = await instance.database;
    List<Map<String, dynamic>> puntos = await db.query(tablaPuntoEmbarque, where: "nroViaje = ?", whereArgs: [viaje.nroViaje]);

    return List.generate(puntos.length, (i) {
      return PuntoEmbarque(nroViaje: puntos[i]['nroViaje'], id: puntos[i]['id'], nombre: puntos[i]['nombre'], eliminado: puntos[i]['eliminado']);
    });
  }

  Future<List<PuntoEmbarque>> obtenerTodosPuntosEmbarqueDeViajeDisponibles(Viaje viaje) async {
    final db = await instance.database;
    List<Map<String, dynamic>> puntos = await db.query(tablaPuntoEmbarque, where: "nroViaje = ? AND eliminado = ?", whereArgs: [viaje.nroViaje, 0]);

    return List.generate(puntos.length, (i) {
      return PuntoEmbarque(nroViaje: puntos[i]['nroViaje'], id: puntos[i]['id'], nombre: puntos[i]['nombre'], eliminado: puntos[i]['eliminado']);
    });
  }

  /*** TABLA  TRIPULANTE ***/
  Future<void> insertarTripulante(Tripulante tripulante) async {
    final db = await instance.database;

    List<Map<String, dynamic>> existeTripulante = await db.query(tablaTripulante, where: "tipoDoc = ? AND numDoc = ? AND nroViaje = ? AND orden = ?", whereArgs: [tripulante.tipoDoc, tripulante.numDoc, tripulante.nroViaje, tripulante.orden]);

    if (existeTripulante.isEmpty) {
      await db.insert(tablaTripulante, tripulante.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(tablaTripulante, tripulante.toMapDatabase(), where: "tipoDoc = ? AND numDoc = ? AND nroViaje = ? AND orden = ?", whereArgs: [tripulante.tipoDoc, tripulante.numDoc, tripulante.nroViaje, tripulante.orden]);
    }
  }

  Future<List<Tripulante>> obtenerTodosTripulantes() async {
    final db = await instance.database;
    List<Map<String, dynamic>> tripulantes = await db.query(tablaTripulante);

    return List.generate(tripulantes.length, (i) {
      return Tripulante(nroViaje: tripulantes[i]['nroViaje'], tipoDoc: tripulantes[i]['tipoDoc'], numDoc: tripulantes[i]['numDoc'], nombres: tripulantes[i]['nombres'], tipo: tripulantes[i]['tipo'], orden: tripulantes[i]['orden']);
    });
  }

  /*** TABLA  PASAJERO HABILITADO***/

  Future<void> insertarPasajerosHabilitados(List<PasajeroHabilitado> pasajerosHabilitados) async {
    if (pasajerosHabilitados.isNotEmpty) {
      final db = await instance.database;

      await db.delete(tablaPasajeroHabilitado);

      for (int i = 0; i < pasajerosHabilitados.length; i++) {
        //await insertarPasajeroHabilitado(pasajerosHabilitados[i]);

        await db.insert(tablaPasajeroHabilitado, pasajerosHabilitados[i].toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> insertarPasajeroHabilitado(PasajeroHabilitado pasajeroHabilitado) async {
    final db = await instance.database;

    await db.insert(tablaPasajeroHabilitado, pasajeroHabilitado.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PasajeroHabilitado>> obtenerTodosPasajerosHabilitados() async {
    final db = await instance.database;
    List<Map<String, dynamic>> pasajerosHabilitados = await db.query(tablaPasajeroHabilitado);

    return List.generate(pasajerosHabilitados.length, (i) {
      return PasajeroHabilitado(nroViaje: pasajerosHabilitados[i]['nroViaje'], tipoDoc: pasajerosHabilitados[i]['tipoDoc'], numDoc: pasajerosHabilitados[i]['numDoc'], apellidos: pasajerosHabilitados[i]['apellidos'], nombres: pasajerosHabilitados[i]['nombres'], fechaViaje: pasajerosHabilitados[i]['fechaViaje'], origen: pasajerosHabilitados[i]['origen'], destino: pasajerosHabilitados[i]['destino'], unidad: pasajerosHabilitados[i]['unidad']);
    });
  }

  /*** TABLA  PRERESERVA ***/

  Future<void> insertarActualizarPrereserva(Pasajero prereserva) async {
    final db = await instance.database;

    List<Map<String, dynamic>> existePrereserva = await db.query(tablaPrereserva, where: "tipoDoc = ? AND numDoc = ? AND nroViaje = ?", whereArgs: [prereserva.tipoDoc, prereserva.numDoc]);

    if (existePrereserva.isEmpty) {
      await db.insert(tablaPrereserva, prereserva.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(tablaPrereserva, prereserva.toMapDatabase(), where: "tipoDoc = ? AND numDoc = ?", whereArgs: [prereserva.tipoDoc, prereserva.numDoc]);
    }
  }

  Future<void> insertarPrereserva(Pasajero prereserva) async {
    final db = await instance.database;

    await db.insert(tablaPrereserva, prereserva.toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertarPrereservas(List<Pasajero> listaPrereservas) async {
    if (listaPrereservas.isNotEmpty) {
      final db = await instance.database;

      await db.delete(tablaPrereserva);

      for (int i = 0; i < listaPrereservas.length; i++) {
        //await insertarPasajeroHabilitado(pasajerosHabilitados[i]);

        await db.insert(tablaPrereserva, listaPrereservas[i].toMapDatabase(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<List<Pasajero>> obtenerTodasLasPrereservas() async {
    final db = await instance.database;
    List<Map<String, dynamic>> prereservas = await db.query(tablaPrereserva);

    return List.generate(prereservas.length, (i) {
      return Pasajero.constructor(
        nroViaje: prereservas[i]['nroViaje'],
        tipoDoc: prereservas[i]['tipoDoc'],
        numDoc: prereservas[i]['numDoc'],
        numeroDoc: prereservas[i]['codExterno'],
        apellidos: prereservas[i]['apellidos'],
        nombres: prereservas[i]['nombres'],
        asiento: prereservas[i]['asiento'],
        embarcado: prereservas[i]['embarcado'],
        idEmbarque: prereservas[i]['idEmbarque'],
        lugarEmbarque: prereservas[i]['lugarEmbarque'],
        fechaEmbarque: prereservas[i]['fechaEmbarque'],
        fechaViaje: prereservas[i]['fechaViaje'],
        idEmbarqueReal: prereservas[i]['idEmbarqueReal'],
        estado: prereservas[i]['estado'],
        idDesembarque: prereservas[i]['idDesembarque'],
        lugarDesembarque: prereservas[i]['lugarDesembarque'],
        fechaDesembarque: prereservas[i]['fechaDesembarque'],
        idDesembarqueReal: prereservas[i]['idDesembarqueReal'],
        embarcadoPor: prereservas[i]['embarcadoPor'],
        coordenadas: prereservas[i]['coordenadas'],
      );
    });
  }

  Future<void> eliminarTodasLasPrereservas() async {
    final db = await instance.database;
    await db.delete(tablaPrereserva);
  }

  Future<void> eliminarPrereserva(Pasajero prereserva) async {
    final db = await instance.database;

    await db.delete(tablaPrereserva, where: "tipoDoc = ? AND numDoc = ?", whereArgs: [prereserva.tipoDoc, prereserva.numDoc]);
  }

  // BUTACORA

  NuevoRegistroBitacora(
    BuildContext context,
    String numDoc,
    String codOperacion,
    String fecha,
    String accion,
    String estado,
  ) async {
    String idDis = Provider.of<UsuarioProvider>(context, listen: false).idDispositivo;
    Usuario usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    LoggerModel logger = LoggerModel(
      idDispositivo: idDis,
      numDoc: numDoc,
      codOperacion: codOperacion,
      fecha: fecha,
      accion: accion,
      estado: estado,
    );

    if (usuario.Log == "1") {
      await InsertBitacora(logger.toJson());
    }
  }

  Future<int> InsertBitacora(Map<String, dynamic> value) async {
    final db = await instance.database;
    int status = await db.insert("$tablaBitacora", value);
    return status;
  }

  Future<List<LoggerModel>> ListarBitacora() async {
    final db = await instance.database;
    List<Map<String, Object?>> listaBitacora = await db.query("$tablaBitacora");
    List<LoggerModel> listaModel = listaBitacora.map((e) => LoggerModel.fromJson(e)).toList();
    return listaModel;
  }

  EliminarRegistrosBitacora() async {
    final db = await instance.database;
    await db.delete(tablaBitacora);
  }

  EliminarUsuarios() async {
    final db = await instance.database;
    await db.delete(tablaUsuario);
  }

  Future<List<Usuario>> ObtenerUsuarioSesionActiva() async {
    final db = await instance.database;
    List<Map<String, Object?>> result = await db.query(tablaUsuario, where: "sesionActiva='1'");
    List<Usuario> listaModel = result.map((e) => Usuario.fromJsonBDLocal(e)).toList();

    return listaModel;
  }

  Future<List<Usuario>> ObtenerUltimoUsuarioSincronziar() async {
    final db = await instance.database;
    List<Map<String, Object?>> result = await db.query(tablaUsuario, where: "sesionSincronizada='1'");
    List<Usuario> listaModel = result.map((e) => Usuario.fromJsonBDLocal(e)).toList();

    return listaModel;
  }

  Future<List<Usuario>> ObtenerUsuarioLogSincronizar() async {
    final db = await instance.database;
    List<Map<String, Object?>> result = await db.query(tablaUsuario, where: "logSincronizado='1'");
    List<Usuario> listaModel = result.map((e) => Usuario.fromJsonBDLocal(e)).toList();

    return listaModel;
  }

  //Jornada
  Future<int> GuardarJornada(Map<String, dynamic> value) async {
    final db = await instance.database;
    int status = await db.insert("$tablaJornada", value);
    return status;
  }

  Future<int> UpdateJornada(Map<String, dynamic> value, String where) async {
    final db = await instance.database;
    int status = await db.update("$tablaJornada", value, where: where);
    return status;
  }

  Future<List<Jornada>> ListarJornada(String nroViaje) async {
    final db = await instance.database;
    List<Map<String, Object?>> listaJornada = await db.query("$tablaJornada", where: "VIAJ_Nro_Viaje = ${nroViaje}");
    List<Jornada> listaModel = listaJornada.map((e) => Jornada.fromJson(e)).toList();
    return listaModel;
  }

  Future<List<Jornada>> ListarJornadas() async {
    final db = await instance.database;
    List<Map<String, Object?>> listaJornada = await db.query("$tablaJornada");
    List<Jornada> listaModel = listaJornada.map((e) => Jornada.fromJson(e)).toList();
    return listaModel;
  }

  Future<void> EliminaJornadas() async {
    final db = await instance.database;
    await db.delete(tablaJornada);
  }

  Future<void> EliminaJornada(String where) async {
    final db = await instance.database;
    await db.delete(tablaJornada, where: where);
  }
  /*  CAMBIOS DOMICILIO  */

  Future<List<Map<String, Object?>>> Listar({required String tabla, String? where}) async {
    final db = await instance.database;
    List<Map<String, Object?>> lista = await db.query("$tabla", where: where);
    return lista;
  }

  Future<int> Guardar({
    required String tabla,
    required Map<String, dynamic> value,
  }) async {
    final db = await instance.database;
    int status = await db.insert("$tabla", value);
    return status;
  }

  Future<int> Update({
    required String table,
    required Map<String, dynamic> value,
    required String where,
  }) async {
    final db = await instance.database;
    int status = await db.update("$table", value, where: where);
    return status;
  }

  Future<void> Eliminar({required String tabla}) async {
    final db = await instance.database;
    await db.delete(tabla);
  }

  Future<int> EliminarUno({required String tabla, required String where}) async {
    final db = await instance.database;
    int status = await db.delete(tabla, where: where);
    return status;
  }
}
