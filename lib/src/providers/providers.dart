import 'dart:async';
import 'dart:convert';

import 'package:embarques_tdp/main.dart';
import 'package:embarques_tdp/src/models/Autorizaciones/AuthUsuario.dart';
import 'package:embarques_tdp/src/models/documento_vehiculo.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/pasajero.dart';
import 'package:embarques_tdp/src/models/punto_embarque.dart';
import 'package:embarques_tdp/src/models/viaje.dart';
import 'package:embarques_tdp/src/models/viaje_domicilio/viaje_domicilio.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/services/documento_servicio.dart';
import 'package:embarques_tdp/src/services/pasajero_servicio.dart';
import 'package:embarques_tdp/src/services/ruta_servicio.dart';
import 'package:embarques_tdp/src/services/tipo_documento_servicio.dart';
import 'package:embarques_tdp/src/services/auth_usuario_service.dart';
import 'package:embarques_tdp/src/utils/Log.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/pasajero_habilitado.dart';
import '../models/ruta.dart';
import '../models/tipo_documento.dart';
import '../models/usuario.dart';
import '../models/viaje_domicilio/parada.dart';
import '../models/viaje_domicilio/pasajero_domicilio.dart';
import '../services/pto_embarque_servicio.dart';
import '../services/viaje_servicio.dart';

/*** USUARIO PROVIDER ***/
class UsuarioProvider extends ChangeNotifier {
  Usuario _usuario = new Usuario(tipoDoc: "", numDoc: "", rpta: "", clave: "", usuarioId: "0", apellidoPat: "", apellidoMat: "", nombres: "", perfil: "", codOperacion: "", nombreOperacion: "", Log: "", equipo: "", claveMaestra: "", tipoListSelected: 0);

  String _idDispositivo = "";

  String get idDispositivo => _idDispositivo;

  asignarIdDispositivo(String id) {
    _idDispositivo = id;
    notifyListeners();
  }

  int? get tipoListSelected => _usuario.tipoListSelected;
  Usuario get usuario => _usuario;
  
  void setTipoListSelected(int value) {
    _usuario.tipoListSelected = value;
    notifyListeners();
  }

  Future<void> usuarioActual({required Usuario usuario}) async {
    _usuario = usuario;
    notifyListeners();
  }

  Future<void> emparejar(String viaje, String unidad, String placa, String fecha, String? vinculacionActiva) async {
    _usuario.viajeEmp = viaje;
    _usuario.unidadEmp = unidad;
    _usuario.placaEmp = placa;
    _usuario.fechaEmp = fecha;
    _usuario.vinculacionActiva = vinculacionActiva == "" ? '1' : vinculacionActiva!;
    notifyListeners();
  }
}

// class AuthUsuarioProvider extends ChangeNotifier {
//   AuthUsuarioModel _authUsuario = AuthUsuarioModel(
//     rpta: "",
//     mensaje: "",
//     // tipoDoc: "",
//     // numDoc: "",
//     // authAcciones: [],
//   );

//   AuthUsuarioModel get authUsuario => _authUsuario;

//   // Método para obtener y procesar los datos desde el servicio
//   Future<void> fetchAuthUsuario(String tipoDoc, String numDoc) async {
//     try {
//       // Llama a tu servicio para obtener los datos
//       AuthUsuarioServicio servicio = AuthUsuarioServicio();
//       AuthUsuarioModel resultado = await servicio.traerListaAuthUsuario(tipoDoc, numDoc);

//       // Actualiza el estado del proveedor con los datos obtenidos
//       _authUsuario = resultado;

//       // Notifica a los escuchadores que los datos han sido actualizados
//       notifyListeners();
//     } catch (e) {
//       // Maneja cualquier error que ocurra durante la obtención de los datos
//       print('Error fetching data: $e');
//     }
//   }
// }

/*** TIPO DE DOCUMENTO PROVIDER ***/
class TipoDocumentoProvider extends ChangeNotifier {
  List<TipoDocumento> _tiposDocumento = [];

  List<DocumentoVehiculo> _documentosVehiculo = [];

  TipoDocumento _tipoDocumento = new TipoDocumento(codigo: "", nombre: "");

  List<TipoDocumento> get tiposDocumento {
    return [..._tiposDocumento];
  }

  List<DocumentoVehiculo> get documentosVehiculo {
    return [..._documentosVehiculo];
  }

  TipoDocumento get tipoDocumento => _tipoDocumento;

  Future<void> tipoDocumentoActual({required TipoDocumento tipoDocumento}) async {
    _tipoDocumento = tipoDocumento;
    notifyListeners();
  }

  Future<void> obtenerTiposDocumento() async {
    var servicio = TipoDocumentoServicio();
    _tiposDocumento = await servicio.obtenerTiposDocumento();
    notifyListeners();
  }
}

/*** VIAJE PROVIDER ***/
class ViajeProvider extends ChangeNotifier {
  //List<PuntoEmbarque> _puntosEmbarqueViaje = [];
  String _idPuntoEmbarque = '-1';

  String _numDocRegistrar = "";

  String _opcSeleccionadaEmbarqueManifiesto = "-1";

  String _puntoDeEmbarque = "";
  String _NombrepuntoDeEmbarque = "";
  String get puntoDeEmbarque => _puntoDeEmbarque;
  String get nombrepuntoDeEmbarque => _NombrepuntoDeEmbarque;

  Viaje _viaje = new Viaje();

  Viaje _viajeManifiesto = new Viaje();

  Viaje get viaje => _viaje;
  Viaje get viajeManifiesto => _viajeManifiesto;
  List<Pasajero> get pasajeros => _viaje.pasajeros;
  List<PuntoEmbarque> get puntosEmbarque => _viaje.puntosEmbarque;

  List<Viaje> get GetListViaje => _GetListViaje;
  List<Viaje> _GetListViaje = [];
  List<Viaje> _ListViaje = [];

  AsignarPuntoEmbarque(String punto, String nombrePunto) {
    _puntoDeEmbarque = punto;
    _NombrepuntoDeEmbarque = nombrePunto;
    notifyListeners();
  }

  ListarViajes(String impreso) {
    List<Viaje> listaViajeFiltrada = [];

    for (int i = 0; i < _ListViaje.length; i++) {
      if (impreso.trim() == _ListViaje[i].impresoEmbarque.trim()) listaViajeFiltrada.add(_ListViaje[i]);
    }
    _GetListViaje = listaViajeFiltrada;
    notifyListeners();
  }

  cambiarEstadoImpreso(String nroViaje) {
    Viaje viaje = _ListViaje.firstWhere((element) => element.nroViaje == nroViaje);
    viaje.impresoEmbarque = '1';
    // ListarViajes(viaje.impresoEmbarque == '0' ? '1' : '0');
    notifyListeners();
  }

  limpiarLista() {
    _GetListViaje = [];
    notifyListeners();
  }

  //List<PuntoEmbarque> get puntosEmbarqueViaje => _puntosEmbarqueViaje;

  //TODO: FINALIZAR VIAJE FORZANDDO

  DateTime _fechaSelecionadaFV = DateTime.now();
  DateTime get getfechaSelecionadaFV => _fechaSelecionadaFV;

  setfechaSelecionadaFV(DateTime value) {
    _fechaSelecionadaFV = value;
    notifyListeners();
  }

  TimeOfDay _timeSelecionadaFV = TimeOfDay.now();
  TimeOfDay get gettimeSelecionadaFV => _timeSelecionadaFV;

  settimeSelecionadaFV(TimeOfDay value) {
    _timeSelecionadaFV = value;
    notifyListeners();
  }

  ///

  String get opcSeleccionadaEmbarqueManifiesto => _opcSeleccionadaEmbarqueManifiesto;

  String get idPuntoEmbarque => _idPuntoEmbarque;
  String get numDocReg => _numDocRegistrar;

  Future<void> reiniciarProvider() async {
    _idPuntoEmbarque = '-1';

    _numDocRegistrar = "";

    _opcSeleccionadaEmbarqueManifiesto = "-1";
    //_puntosEmbarqueViaje = [];
    _viaje = new Viaje();

    _viajeManifiesto = new Viaje();
  }

  AsignarListaViaje(List<Viaje> listViaje) {
    _GetListViaje = listViaje;
    notifyListeners();
  }

  Future<void> ListarAPIMonaifiesto(
    String ptoEmbarque,
    String fecha,
    Usuario usuario,
    String impreso,
  ) async {
    ViajeServicio servicio = new ViajeServicio();
    List<Viaje> viajesBusqueda = await servicio.obtenerViajesManifiesto(
      ptoEmbarque,
      fecha,
      usuario,
      impreso,
    );

    _GetListViaje = viajesBusqueda;
    notifyListeners();
  }

  cambiarEstado(String nroViaje, int estadoEmbarque) {
    Viaje viaje = _GetListViaje.firstWhere((element) => element.nroViaje == nroViaje);
    print(viaje);
    viaje.estadoEmbarque = estadoEmbarque;
    notifyListeners();
  }

  Future<void> viajeActual({required Viaje viaje}) async {
    _viaje = viaje;
    _viaje.pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));
    notifyListeners();
  }

  Future<void> viajeManifiestoActual({required Viaje viaje}) async {
    _viajeManifiesto = viaje;
    _viajeManifiesto.pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));
    notifyListeners();
  }

  Future<void> puntosEmbarqueViajeActuales({required List<PuntoEmbarque> puntosEmbarque}) async {
    _viaje.puntosEmbarque = puntosEmbarque;
    notifyListeners();
  }

  Future<void> actualizarPuntoEmbarque(String idPuntoEmbarque) async {
    _idPuntoEmbarque = idPuntoEmbarque;
    notifyListeners();
  }

  Future<void> actualizarNumDocRegistrar(String numDocRegistrar) async {
    _numDocRegistrar = numDocRegistrar;
    notifyListeners();
  }

  Future<void> actualizarSeleccionadaEmbarqueManifiestor(String opcSeleccionadaEmbarqueManifiesto) async {
    _opcSeleccionadaEmbarqueManifiesto = opcSeleccionadaEmbarqueManifiesto;
    notifyListeners();
  }

  //OBTENER VIAJE DE BD
  Future<void> obtenerViajeConductorBD(String tipoDoc, String numDoc, String nroViaje) async {
    var servicio = new ViajeServicio();

    _viaje = await servicio.obtenerViajeConductor(tipoDoc, numDoc, nroViaje);
    notifyListeners();
  }

  Future<void> sincronizacionContinuaDeViaje(String tipoDoc, String numDoc) async {
    PasajeroServicio pasajeroServicio = new PasajeroServicio();

    int numeroPasajerosPorSincronizar = 0;

    List<Pasajero> pasajerosEliminar = [];

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].modificado == 0) {
        //datosPorSincronizar = true;
        String rpta = await pasajeroServicio.cambiarEstadoEmbarquePasajero(_viaje.pasajeros[i], _viaje.codOperacion);
        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            _viaje.pasajeros[i].modificado = 1;
            //Actualizamos en la BD local
            await AppDatabase.instance.insertarActualizarPasajero(_viaje.pasajeros[i]);
            break;
          case "1":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            //datosPorSincronizar = false;
            break;
          case "2":
          case "9":
            //datosPorSincronizar = true;
            break;
          default:
        }
      }
    }

    for (Pasajero pEliminar in pasajerosEliminar) {
      await AppDatabase.instance.eliminarPasajero(pEliminar);
      _viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].modificado == 0) numeroPasajerosPorSincronizar += 1;
    }

    if (numeroPasajerosPorSincronizar > 0) {
      datosPorSincronizar = true;
    } else {
      datosPorSincronizar = false;
    }

    notifyListeners();
    //await sincronizarViajeNuevosPasajeros(tipoDoc, numDoc);
  }

  //SINCRONIZACION CONTINUA BOLSA
  Future<void> sincronizacionContiniaDeViajeBolsaDesdeHome(String tipoDoc, String numDoc, String codOperacion, BuildContext context, Viaje viaje) async {
    bool usuarioSesionSincronizada = false;

    for (var i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].sincronizar == "1") {
        usuarioSesionSincronizada = true;
      }
    }
    for (var i = 0; i < viaje.puntosEmbarque.length; i++) {
      if (viaje.puntosEmbarque[i].sincronizado == "1") {
        usuarioSesionSincronizada = true;
      }
    }
    if (viaje.estadoViaje == "1") {
      usuarioSesionSincronizada = true;
    }

    if (usuarioSesionSincronizada) {
      await AppDatabase.instance.Update(
        table: "usuario",
        value: {
          "sesionSincronizada": "1",
        },
        where: "numDoc = '${numDoc}'",
      );
    }

    if (viaje.estadoInicioViaje == '1') {
      bool sincronizacionInicioViaje = true;

      final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();

      for (var i = 0; i < viaje.tripulantes.length; i++) {
        Response? res = await _embarquesSupScanerServicio.vincularInicioJornada_v2(
          viaje.nroViaje.trim(),
          viaje.tripulantes[i].numDoc.trim(),
          "1",
          tipoDoc.trim(),
          numDoc.trim(),
          codOperacion.trim(),
          viaje.odometroInicial.toString().trim(),
          viaje.cordenadaInicial.toString(),
          'NOGPS',
        );

        if (res != null) {
          final data = json.decode(res.body);

          if (data["rpta"] == "0") {
            sincronizacionInicioViaje = true;
          }

          if (data["rpta"] != '0') {
            sincronizacionInicioViaje = false;
          }
        }

        await AppDatabase.instance.Update(
          table: "viaje",
          value: {
            "estadoInicioViaje": sincronizacionInicioViaje ? '0' : '1',
            "cordenadaInicial": "${viaje.cordenadaInicial.toString()}",
          },
          where: "nroViaje = '${viaje.nroViaje}'",
        );
      }
    }

    if (viaje.pasajeros.isNotEmpty) {
      for (var i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].sincronizar == "1") {
          bool responseSuccess = false;
          PasajeroServicio servicio = new PasajeroServicio();
          Response? resp = await servicio.cambiarEstadoPrereservaV5(
            viaje.pasajeros[i],
            codOperacion,
            viaje.pasajeros[i].nroViaje,
            viaje.pasajeros[i].tipoDoc + viaje.pasajeros[i].numDoc,
            viaje.nroViaje,
          );

          if (resp != null) {
            final decodeData = json.decode(resp.body);
            if (decodeData["rpta"] == "0") {
              responseSuccess = true;
            } else {
              responseSuccess = false;
            }
          } else {
            responseSuccess = false;
          }

          //UPDATE
          await AppDatabase.instance.Update(
            table: "pasajero",
            value: {
              "sincronizar": responseSuccess ? "0" : "1",
            },
            where: "numDoc ='${viaje.pasajeros[i].numDoc}' AND idRuta='${viaje.pasajeros[i].idRuta}'",
          );
        }
      }
    }

    if (viaje.puntosEmbarque.isNotEmpty) {
      for (int i = 0; i < viaje.puntosEmbarque.length; i++) {
        if (viaje.puntosEmbarque[i].sincronizado == "1") {
          bool responseSuccess = false;

          ViajeServicio viajeServicio = new ViajeServicio();
          Response? resp = await viajeServicio.cambiarEstadoPuntoEmbarqueV2(viaje.puntosEmbarque[i], tipoDoc, numDoc, _viaje);

          if (resp != null) {
            if (resp.body == "0") {
              responseSuccess = true;
            } else {
              responseSuccess = false;
            }
          } else {
            responseSuccess = false;
          }

          await AppDatabase.instance.Update(
            table: "punto_embarque",
            value: {"sincronizado": responseSuccess ? "0" : "1"},
            where: "id = '${viaje.puntosEmbarque[i].id}' AND nroViaje='${viaje.puntosEmbarque[i].nroViaje}'",
          );
        }
      }
    }

    if (viaje.estadoViaje == "1") {
      if (await Permission.location.request().isGranted) {}

      String posicionActual;
      try {
        Position posicionActualGPS = await Geolocator.getCurrentPosition();
        posicionActual = posicionActualGPS.latitude.toString() + "," + posicionActualGPS.longitude.toString();
      } catch (e) {
        posicionActual = "0, 0-Error no controlado";
      }

      List<Usuario> listausuario = await AppDatabase.instance.ObtenerUltimoUsuarioSincronziar();
      if (listausuario.isNotEmpty) {
        ViajeServicio servicio = new ViajeServicio();
        final rpta = await servicio.finalizarViajeV5(
          viaje.nroViaje,
          viaje.codOperacion,
          listausuario[0],
          viaje.odometroFinal.toString(),
          posicionActual.toString(),
          'NOGPS',
        );

        if (rpta == "0" || rpta == "1") {
          await AppDatabase.instance.EliminarUno(tabla: "viaje", where: "nroViaje = '${viaje.nroViaje}'");
          await AppDatabase.instance.EliminarUno(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");
          await AppDatabase.instance.EliminarUno(tabla: "pasajero", where: "nroViaje = '${viaje.nroViaje}'");
          await AppDatabase.instance.EliminarUno(tabla: "punto_embarque", where: "nroViaje = '${viaje.nroViaje}'");
          await AppDatabase.instance.EliminarUno(tabla: "jornada", where: "VIAJ_Nro_Viaje = '${viaje.nroViaje}'");
          // await AppDatabase.instance.EliminarUno(tabla: "paradero", where: "");

          await AppDatabase.instance.Update(
            table: "usuario",
            value: {"viajeEmp": "", "unidadEmp": "", "placaEmp": "", "fechaEmp": "", "vinculacionActiva": "0"},
            where: "numDoc = '${listausuario[0].numDoc}'",
          );
        }
      }
    }
  }

  Future<void> sincronizacionContinuaDeViajeBolsa(String tipoDoc, String numDoc, BuildContext context) async {
    PasajeroServicio pasajeroServicio = new PasajeroServicio();
    ViajeServicio viajeServicio = new ViajeServicio();
    int numeroPasajerosPorSincronizar = 0;
    int puntosEmbarquePorSincronizar = 0;
    List<Pasajero> pasajerosEliminar = [];

    Usuario _usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    for (int i = 0; i < _viaje.puntosEmbarque.length; i++) {
      if (_viaje.puntosEmbarque[i].modificado == 0) {
        String rpta = await viajeServicio.cambiarEstadoPuntoEmbarque(_viaje.puntosEmbarque[i], _usuario, _viaje);

        if (rpta == "0") {
          _viaje.puntosEmbarque[i].modificado = 1;
        } else {
          _viaje.puntosEmbarque[i].modificado = 0;
        }
      }
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      String nuevoNroViaje = "0";

      if (_viaje.pasajeros[i].modificado == 0 || _viaje.pasajeros[i].modificado == 2) {
        //datosPorSincronizar = true;

        if (_viaje.pasajeros[i].embarcado == 0)
          nuevoNroViaje = "0";
        else
          nuevoNroViaje = _viaje.nroViaje;

        String rpta = await pasajeroServicio.cambiarEstadoPrereservaV2(_viaje.pasajeros[i], _viaje.codOperacion, nuevoNroViaje, _usuario.tipoDoc + _usuario.numDoc);
        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            _viaje.pasajeros[i].modificado = 1;
            if (_viaje.pasajeros[i].embarcado == 0) {
              await Provider.of<PrereservaProvider>(context, listen: false).agregarPrereserva(_viaje.pasajeros[i]);
              pasajerosEliminar.add(_viaje.pasajeros[i]);
            }

            //Actualizamos en la BD local
            await AppDatabase.instance.insertarActualizarPasajero(_viaje.pasajeros[i]);
            break;
          case "1":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            break;
          case "2":
          case "4":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            break;
          case "9":
            break;
          default:
        }
      }
    }

    for (Pasajero pEliminar in pasajerosEliminar) {
      await AppDatabase.instance.eliminarPasajero(pEliminar);
      _viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].modificado == 0) numeroPasajerosPorSincronizar += 1;
    }

    for (int i = 0; i < _viaje.puntosEmbarque.length; i++) {
      if (_viaje.puntosEmbarque[i].modificado == 0) puntosEmbarquePorSincronizar++;
    }

    if (numeroPasajerosPorSincronizar == 0 && puntosEmbarquePorSincronizar == 0) {
      datosPorSincronizar = false;
    } else {
      datosPorSincronizar = true;
    }

    notifyListeners();
    //await sincronizarViajeNuevosPasajeros(tipoDoc, numDoc);
  }

  Future<void> sincronizarViajeNuevosPasajeros(String tipoDoc, String numDoc) async {
    var servicio = new ViajeServicio();
    Viaje viajeAux = await servicio.obtenerViajeConductor(tipoDoc, numDoc, _viaje.nroViaje);

    if (viajeAux.rpta == "0") {
      await removerPasajerosEliminado(viajeAux.pasajeros);

      if (viajeAux.pasajeros.isNotEmpty) {
        for (int i = 0; i < viajeAux.pasajeros.length; i++) {
          if (!_verificarPasajeroEnLista(viajeAux.pasajeros[i])) {
            //Insertamos el pasajero en la BD local
            await _verificarPuntoEmbarqueCerrado(viajeAux.pasajeros[i]);
            await AppDatabase.instance.insertarActualizarPasajero(viajeAux.pasajeros[i]);
            _viaje.pasajeros.add(viajeAux.pasajeros[i]);
            //notifyListeners();
          }
        }
        _viaje.pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));

        if (viajeAux.puntosEmbarque.isNotEmpty) {
          for (int i = 0; i < viajeAux.puntosEmbarque.length; i++) {
            if (!_verificarPuntoEmbarqueEnLista(viajeAux.puntosEmbarque[i])) {
              await AppDatabase.instance.insertarPuntoEmbarque((viajeAux.puntosEmbarque[i]));
              _viaje.puntosEmbarque.add(viajeAux.puntosEmbarque[i]);
            }
          }
        }

        /*_puntosEmbarqueViaje = await AppDatabase.instance
            .obtenerTodosPuntosEmbarqueDeViaje(_viaje);*/

        notifyListeners();
      }
    }
  }

  Future<void> sincronizarViajeNuevosPasajerosBolsa(String tipoDoc, String numDoc, String nroViaje, BuildContext context) async {
    var servicio = new ViajeServicio();
    Viaje viajeAux = await servicio.obtenerViajeVinculadoBolsaSupervisor_v4(tipoDoc, numDoc, nroViaje);
    //TODO: CAMBIE EL obtenerViajeConductor a obtenerViajeVinculadoBolsaSupervisor
    var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;

    if (viajeAux.rpta == "0") {
//TODO:LOGGER
      await AppDatabase.instance.NuevoRegistroBitacora(
        context,
        "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
        "${usuarioLogin.codOperacion}",
        DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
        "Embarque ${usuarioLogin.perfil} Obtener Viaje: ${viaje.nroViaje}",
        "Exitoso",
      );

      var viajeServicio = new ViajeServicio();
      final puntosEmabarque = await viajeServicio.ListarPuntosEmbarqueXRuta(
        viaje.nroViaje,
        viaje.codOperacion,
      );
      viajeAux.puntosEmbarque = puntosEmabarque;

      Provider.of<ViajeProvider>(context, listen: false).viajeActual(viaje: viajeAux);

      await removerPasajerosEliminado(viajeAux.pasajeros);

      if (viajeAux.pasajeros.isNotEmpty) {
        for (int i = 0; i < viajeAux.pasajeros.length; i++) {
          if (!_verificarPasajeroEnLista(viajeAux.pasajeros[i])) {
            //Insertamos el pasajero en la BD local
            await _verificarPuntoEmbarqueCerrado(viajeAux.pasajeros[i]);
            await AppDatabase.instance.insertarActualizarPasajero(viajeAux.pasajeros[i]);
            _viaje.pasajeros.add(viajeAux.pasajeros[i]);
            //notifyListeners();
          }
        }
        _viaje.pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));
      }

      if (viajeAux.puntosEmbarque.isNotEmpty) {
        /*for (int i = 0; i < viajeAux.puntosEmbarque.length; i++) {
          if (!_verificarPuntoEmbarqueEnLista(viajeAux.puntosEmbarque[i])) {
            await AppDatabase.instance
                .insertarPuntoEmbarque((viajeAux.puntosEmbarque[i]));
            _viaje.puntosEmbarque.add(viajeAux.puntosEmbarque[i]);
          }
        }*/
        _viaje.puntosEmbarque = viajeAux.puntosEmbarque;
      }

      /*_puntosEmbarqueViaje = await AppDatabase.instance
            .obtenerTodosPuntosEmbarqueDeViaje(_viaje);*/

      PasajeroServicio servicioPasajero = new PasajeroServicio();
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false).usuario;

      List<Pasajero> listadoPrereservasAux = await servicioPasajero.obtener_prereservas(
        _viaje.nroViaje,
        usuarioProvider.tipoDoc,
        usuarioProvider.numDoc,
        _viaje.subOperacionId,
      );

      await AppDatabase.instance.NuevoRegistroBitacora(
        context,
        "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
        "${usuarioLogin.codOperacion}",
        DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
        "Embarque ${usuarioLogin.perfil} Obtener Prereservas: Existen ${listadoPrereservasAux.length}",
        "Exitoso",
      );

      if (listadoPrereservasAux.isNotEmpty) {
        List<Pasajero> prereservasAInsertar = [];
        if (_viaje.pasajeros.isNotEmpty) {
          for (int i = 0; i < listadoPrereservasAux.length; i++) {
            //primero verificamos que la prereserva no este en la lista de pasajeros actuales
            if (!_verificarPasajeroEnLista(listadoPrereservasAux[i])) {
              prereservasAInsertar.add(listadoPrereservasAux[i]);
            }
          }
        } else {
          prereservasAInsertar = listadoPrereservasAux;
        }

        await Provider.of<PrereservaProvider>(context, listen: false).insertarActualizarNuevasPrereservas(context, prereservasAInsertar);
      }

      notifyListeners();
    }
  }

  Future<void> removerPasajerosEliminado(List<Pasajero> pasajerosAux) async {
    bool encontrado = false;

    List<Pasajero> pasajerosAEliminar = [];

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      encontrado = false;
      for (int j = 0; j < pasajerosAux.length; j++) {
        if (_viaje.pasajeros[i].tipoDoc == pasajerosAux[j].tipoDoc && _viaje.pasajeros[i].numDoc == pasajerosAux[j].numDoc) {
          encontrado = true;
          break;
        }
      }

      if (!encontrado) {
        pasajerosAEliminar.add(_viaje.pasajeros[i]);
      }
    }

    for (Pasajero pEliminar in pasajerosAEliminar) {
      /*Eliminarde la bd local */
      await AppDatabase.instance.eliminarPasajero(pEliminar);
      _viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);
    }

    notifyListeners();
  }

  Future<void> _verificarPuntoEmbarqueCerrado(Pasajero pasajeroNuevo) async {
    String puntoEmbarquePasajeroNuevo = pasajeroNuevo.idEmbarque;
    for (int i = 0; i < _viaje.puntosEmbarque.length; i++) {
      if (_viaje.puntosEmbarque[i].id == puntoEmbarquePasajeroNuevo && _viaje.puntosEmbarque[i].eliminado == 1) {
        _viaje.puntosEmbarque[i].eliminado = 0;
        //Editamos el estado de la BD Local
        await AppDatabase.instance.actualizarPuntoEmbarque(_viaje.puntosEmbarque[i]);
      }
    }

    notifyListeners();
  }

  bool _verificarPasajeroEnLista(Pasajero pasajeroBus) {
    if (_viaje.pasajeros.isNotEmpty) {
      for (int i = 0; i < _viaje.pasajeros.length; i++) {
        if (_viaje.pasajeros[i].tipoDoc == pasajeroBus.tipoDoc && _viaje.pasajeros[i].numDoc == pasajeroBus.numDoc) {
          return true;
        }
      }
    }

    return false;
  }

  bool _verificarPuntoEmbarqueEnLista(PuntoEmbarque pEmbarque) {
    if (_viaje.puntosEmbarque.isNotEmpty) {
      for (int i = 0; i < _viaje.puntosEmbarque.length; i++) {
        if (_viaje.puntosEmbarque[i].id == pEmbarque.id) {
          return true;
        }
      }
    }
    return false;
  }

  ///JS 18/07/2023

  Future<void> embarcarPasajero(Pasajero pasajero) async {
    for (var i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].numDoc == pasajero.numDoc) {
        _viaje.pasajeros[i] = pasajero;
      }
    }
    notifyListeners();
  }

  Future<void> desembarcarPasajero(Pasajero pasajero) async {
    for (var i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].numDoc == pasajero.numDoc) {
        _viaje.pasajeros[i] = pasajero;
      }
    }
    notifyListeners();
  }
}

/*** PUNTO EMBARQUE PROVIDER ***/
class PuntoEmbarqueProvider extends ChangeNotifier {
  PuntoEmbarque _puntoEmbarque = new PuntoEmbarque(id: "", nombre: "", nroViaje: "", eliminado: 1);

  List<PuntoEmbarque> _puntosEmbarque = [];
  PuntoEmbarque get puntoEmbarque => _puntoEmbarque;
  List<PuntoEmbarque> get puntosEmbarque {
    return [..._puntosEmbarque];
  }

  Future<void> puntoEmbarqueViajeActual({required PuntoEmbarque puntoEmbarqueViaje}) async {
    //_puntoEmbarqueViaje = puntoEmbarqueViaje;
    notifyListeners();
  }

  Future<void> obtenerPuntosEmbarque(String codOperacion) async {
    var servicio = PuntoEmbarqueServicio();
    _puntosEmbarque = await servicio.obtenerPuntoEmbarque(codOperacion);
    notifyListeners();
  }
}

class PasajeroProvider extends ChangeNotifier {
  Pasajero _pasajero = new Pasajero();

  List<Pasajero> _pasajeros = [];

  Pasajero get pasajero => _pasajero;

  List<Pasajero> get pasajeros {
    return [..._pasajeros];
  }

  Future<void> agregarPasajeros(List<Pasajero> pasajeros) async {
    _pasajeros = pasajeros;
    //notifyListeners();
  }

  Future<void> reiniciarProvider() async {
    _pasajeros = [];
  }
}

class PasajeroHabilitadoProvider extends ChangeNotifier {
  PasajeroHabilitado _pasajeroHabilitado = new PasajeroHabilitado(tipoDoc: "", numDoc: "", apellidos: "", nombres: "", nroViaje: "", fechaViaje: "", origen: "", destino: "", unidad: "");

  List<PasajeroHabilitado> _pasajerosHabilitados = [];

  PasajeroHabilitado get pasajeroHabilitado => _pasajeroHabilitado;

  List<PasajeroHabilitado> get pasajerosHabilitados {
    return [..._pasajerosHabilitados];
  }

  Future<void> reiniciarProvider() async {
    _pasajeroHabilitado = new PasajeroHabilitado(tipoDoc: "", numDoc: "", apellidos: "", nombres: "", nroViaje: "", fechaViaje: "", origen: "", destino: "", unidad: "");
    _pasajerosHabilitados = [];
  }

  Future<void> pasajerosHabilitadosActuales({required List<PasajeroHabilitado> pasajerosHabilitados}) async {
    _pasajerosHabilitados = pasajerosHabilitados;
    notifyListeners();
  }

  //OBTENER PASAJEROS HABILITADOS DE BD
  Future<void> obtenerPasajerosHabilitadosBD(String nroViaje, String codOperacion) async {
    var servicio = new PasajeroServicio();

    _pasajerosHabilitados = await servicio.obtenerPasajerosHabilitados(nroViaje, codOperacion);
    notifyListeners();
  }
}

class PrereservaProvider extends ChangeNotifier {
  Pasajero _prereserva = new Pasajero();

  List<Pasajero> _listadoPrereservas = [];

  Pasajero get prereserva => _prereserva;

  List<Pasajero> get listdoPrereservas {
    return [..._listadoPrereservas];
  }

  Future<void> reiniciarProvider() async {
    _prereserva = new Pasajero();

    _listadoPrereservas = [];
  }

  Future<void> insertarActualizarNuevasPrereservas(BuildContext context, List<Pasajero> prereservasAux) async {
    bool encontrado = false;
    for (int i = 0; i < prereservasAux.length; i++) {
      encontrado = false;
      for (int j = 0; j < _listadoPrereservas.length; j++) {
        if (prereservasAux[i].tipoDoc == _listadoPrereservas[j].tipoDoc && prereservasAux[i].numDoc == _listadoPrereservas[j].numDoc) {
          //Reemplazamos los datos de la prereserva;
          _listadoPrereservas[j] = prereservasAux[i];
          await AppDatabase.instance.insertarActualizarPrereserva(prereservasAux[i]);
          var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
          await AppDatabase.instance.NuevoRegistroBitacora(
            context,
            "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
            "${usuarioLogin.codOperacion}",
            DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
            "Embarque ${usuarioLogin.perfil}: Reemplazamos los datos de la prereserva",
            "Exitoso",
          );
          encontrado = true;
          break;
        }
      }

      if (!encontrado) {
        //Añadimos la nueva prereserva;
        Provider.of<ViajeProvider>(context, listen: false)._verificarPuntoEmbarqueCerrado(prereservasAux[i]);
        _listadoPrereservas.add(prereservasAux[i]);

        await AppDatabase.instance.insertarActualizarPrereserva(prereservasAux[i]);
        var usuarioLogin = Provider.of<UsuarioProvider>(context, listen: false).usuario;
        // await AppDatabase.instance.NuevoRegistroBitacora(
        //   context,
        //   "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
        //   "${usuarioLogin.codOperacion}",
        //   DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
        //   "Embarque ${usuarioLogin.perfil}: Añadimos la nueva prereserva",
        //   "Exitoso",
        // );

        await AppDatabase.instance.insertarActualizarPrereserva(prereservasAux[i]);
      }
    }

    notifyListeners();
  }

  Future<void> actualizarListadoPrereservas({required List<Pasajero> listadoPrereservas}) async {
    _listadoPrereservas = listadoPrereservas;
    notifyListeners();
  }

  Future<void> eliminarPrereservaDelListado(Pasajero prereserva) async {
    _listadoPrereservas.removeWhere((element) => (element.tipoDoc == prereserva.tipoDoc && element.numDoc == prereserva.numDoc));
    notifyListeners();
  }

  Future<void> agregarPrereserva(Pasajero prereserva) async {
    bool encontrado = false;
    for (int j = 0; j < _listadoPrereservas.length; j++) {
      encontrado = false;
      if (prereserva.tipoDoc == _listadoPrereservas[j].tipoDoc && prereserva.numDoc == _listadoPrereservas[j].numDoc) {
        //Reemplazamos los datos de la prereserva;
        _listadoPrereservas[j] = prereserva;
        await AppDatabase.instance.insertarActualizarPrereserva(prereserva);
        encontrado = true;
        break;
      }
    }

    if (!encontrado) {
      _listadoPrereservas.add(prereserva);

      await AppDatabase.instance.insertarActualizarPrereserva(prereserva);
    }

    notifyListeners();
  }

  //OBTENER PRERESERVAS DE BD
  Future<void> obtenerListadoPrereservasBD(String nroViaje, String tDocUsuario, String nDocUsuario, String codOperacion) async {
    var servicio = new PasajeroServicio();

    _listadoPrereservas = await servicio.obtener_prereservas(nroViaje, tDocUsuario, nDocUsuario, codOperacion);
    notifyListeners();
  }
}

/*** RUTAS PROVIDER ***/
class RutasProvider extends ChangeNotifier {
  List<Ruta> _rutas = [];
  List<Ruta> _rutasEmbarquesHoy = [];
  Ruta _ruta = new Ruta(ruta: "", idOrigen: "", idDestino: "", origen: "", destino: "", codRuta: "");

  List<Ruta> get rutas {
    return [..._rutas];
  }

  List<Ruta> get rutasEmbarquesHoy {
    return [..._rutasEmbarquesHoy];
  }

  Ruta get ruta => _ruta;

  Future<void> tipoDocumentoActual({required Ruta ruta}) async {
    _ruta = ruta;
    notifyListeners();
  }

  Future<void> obtenerRutas(String codOperacion) async {
    var servicio = RutaServicio();
    _rutas = await servicio.obtenerRutas(codOperacion);
    notifyListeners();
  }

  Future<void> obtenerRutasSupervisor(String codOperacion) async {
    var servicio = EmbarquesSupScanerServicio();
    _rutasEmbarquesHoy = await servicio.obtenerRutaSupervisor(codOperacion);
    notifyListeners();
  }
}

/**** DOMICILIO PROVIDER ****/
class DomicilioProvider extends ChangeNotifier {
  ViajeDomicilio _viaje = new ViajeDomicilio();
  Parada _paradaActual = new Parada();
  PasajeroDomicilio _pasajeroMostrar = new PasajeroDomicilio();
  bool _actualizarMapa = false;
  Parada _paradaRecojoMostrar = new Parada();
  Parada _paradaRepartoMostrar = new Parada();

  ViajeDomicilio get viaje => _viaje;
  List<PasajeroDomicilio> get pasajeros => _viaje.pasajeros;
  PasajeroDomicilio get pasajeroMostrar => _pasajeroMostrar;
  bool get actualizarMapa => _actualizarMapa;
  Parada get paradaActual => _paradaActual;
  Parada get paradaRecojoMostrar => _paradaRecojoMostrar;
  Parada get paradaRepartoMostrar => _paradaRepartoMostrar;

  //GERMA: INTEGRACION 12/7/23
  List<PasajeroDomicilio> _posiblesPasajeros = [];
  List<PasajeroDomicilio> get posiblesPasajeros => _posiblesPasajeros;
  Future<void> asignarPosiblesPasajeros(List<PasajeroDomicilio> posiblesPasajeros) async {
    _posiblesPasajeros = posiblesPasajeros;

    notifyListeners();
  }

  ///
  cambiarEsEmbarque(bool esEmbarque) {}

  Future<void> reiniciarProvider() async {
    _viaje = new ViajeDomicilio();
    _pasajeroMostrar = new PasajeroDomicilio();
  }

  Future<void> actualizarViaje(ViajeDomicilio viaje) async {
    _viaje = viaje;

    notifyListeners();
  }

  Future<void> actualizarPasajero(PasajeroDomicilio pasajero) async {
    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].numDoc == pasajero.numDoc) {
        _viaje.pasajeros[i] = pasajero;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> sincronizacionContinuaDeViajeDomicilio(String u_tipoDoc, String u_numDoc, BuildContext context) async {
    // Log.insertarLogDomicilio(context: context, mensaje: "Inicia Sincronización en pantalla de RECOJO ${_viaje.nroViaje}", rpta: "OK");

    PasajeroServicio pasajeroServicio = new PasajeroServicio();
    int numeroPasajerosPorSincronizar = 0;
    List<PasajeroDomicilio> pasajerosEliminar = [];

    bool notificar = false;

    if (_viaje.estadoInicioViaje == '1') {
      bool sincronizadoInicioViaje = false;

      final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();

      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando el inicio de viaje REPARTO #${_viaje.nroViaje} -> PA:VincularInicioJornada", rpta: "OK");

      Response? res = await _embarquesSupScanerServicio.vincularInicioJornada_v2(
        _viaje.nroViaje.trim(),
        u_numDoc.trim(),
        "1",
        u_tipoDoc.trim(),
        u_numDoc.trim(),
        _viaje.codOperacion.trim(),
        _viaje.odometroInicial.toString().trim(),
        _viaje.cordenadaInicial.toString(),
        'NOGPS',
      );

      if (res != null) {
        final data = json.decode(res.body);
        if (data["rpta"] == '0') {
          sincronizadoInicioViaje = true;
        }

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando el inicio de viaje REPARTO  #${_viaje.nroViaje} -> PA:VincularInicioJornada", rpta: "${sincronizadoInicioViaje ? "OK" : "ERROR->${data["Mensaje"]}"}");
      }

      int status = await AppDatabase.instance.Update(
        table: "viaje_domicilio",
        value: {
          "estadoInicioViaje": sincronizadoInicioViaje ? '0' : '1',
          "cordenadaInicial": "${_viaje.cordenadaInicial.toString()}",
        },
        where: "nroViaje = '${_viaje.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el inicio de viaje REPARTO en BDLocal #${_viaje.nroViaje} -> TBL:viaje_domicilio", rpta: "${status > 0 ? "OK" : "ERROR->${status}"}");
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].modificado == 0) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_v3", rpta: "OK");

        String rpta = await pasajeroServicio.cambiarEstadoEmbarquePasajeroDomicilio_v2(_viaje.pasajeros[i], _viaje.codOperacion, u_tipoDoc + u_numDoc);
        //String rpta = "";
        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_v3", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            _viaje.pasajeros[i].modificado = 1;

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: _viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero nuevo en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;

            break;
          case "1":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            notificar = true;
            break;
          case "2":
          case "9":
            break;
          default:
        }
      }

      if (_viaje.pasajeros[i].modificado == 2) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

        String rpta = await pasajeroServicio.registrarDesembarquePasajeroDomicilio(_viaje.pasajeros[i], _viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            _viaje.pasajeros[i].modificado = 1;
            viaje.pasajeros[i].estadoDesem = "1"; //0 <-- desembarque

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: _viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${_viaje.pasajeros[i].numDoc}' AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero nuevo en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;

            break;
          case "1":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            notificar = true;
            break;
          case "2":
          case "9":
            break;
          default:
        }
      }

      if (_viaje.pasajeros[i].modificadoFechaArribo == 0) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando fecha llegada unidad #${_viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

        String rpta2 = await pasajeroServicio.registrarFechaLlegadaUnidadDomicilio(_viaje.pasajeros[i], _viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando fecha llegada unidad #${_viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta2 == "0" ? "OK" : "ERROR-> ${rpta2}"}");

        switch (rpta2) {
          case "0":
          case "1":
            _viaje.pasajeros[i].modificadoFechaArribo = 1;

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: _viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${_viaje.pasajeros[i].numDoc}' AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza fecha llegada unidad en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;
            break;
          case "2":
          case "3":
          case "9":
            break;
          default:
        }
      }
    }

    for (PasajeroDomicilio pEliminar in pasajerosEliminar) {
      //AppDatabase.instance.eliminarPasajero(pEliminar);
      _viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);

      //DELETE PASAJERO BD LOCAL
      int status = await AppDatabase.instance.EliminarUno(
        tabla: "pasajero_domicilio",
        where: "numDoc = '${pEliminar.numDoc}'  AND nroViaje = '${pEliminar.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Eliminar pasajero en BDLocal #${pEliminar.numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].modificado == 0 || _viaje.pasajeros[i].modificado == 2 || _viaje.pasajeros[i].modificadoFechaArribo == 0) numeroPasajerosPorSincronizar += 1;
    }

    if (numeroPasajerosPorSincronizar == 0) {
      datosPorSincronizar = false;
    } else {
      datosPorSincronizar = true;
    }

    // Log.insertarLogDomicilio(context: context, mensaje: "Finaliza Sincronización en pantalla de RECOJO ${_viaje.nroViaje}", rpta: "OK");

    if (notificar) {
      notifyListeners();
    }

    //await sincronizarViajeNuevosPasajeros(tipoDoc, numDoc);
  }

  Future<void> sincronizacionContinuaDeViajeDomicilioDesdeHome(String u_tipoDoc, String u_numDoc, BuildContext context, ViajeDomicilio viaje) async {
    // Log.insertarLogDomicilio(context: context, mensaje: "Inicia Sincronización viaje RECOJO ${viaje.nroViaje}", rpta: "OK");
    PasajeroServicio pasajeroServicio = new PasajeroServicio();
    int numeroPasajerosPorSincronizar = 0;
    List<PasajeroDomicilio> pasajerosEliminar = [];

    bool notificar = false;

    if (viaje.estadoInicioViaje == '1') {
      bool sincronizadoInicioViaje = false;

      final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();

      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando el inicio de viaje RECOJO #${viaje.nroViaje} -> PA:IniciarViaje", rpta: "OK");

      Response? res = await _embarquesSupScanerServicio.IniciarViaje(
        viaje.nroViaje.trim(),
        u_numDoc.trim(),
        "1",
        u_tipoDoc.trim(),
        u_numDoc.trim(),
        viaje.codOperacion.trim(),
        viaje.odometroInicial.toString().trim(),
        viaje.cordenadaInicial.toString().trim(),
      );

      if (res != null) {
        final data = json.decode(res.body);
        if (data["rpta"] == '0') {
          sincronizadoInicioViaje = true;
        }
        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando el inicio de viaje RECOJO #${viaje.nroViaje} -> PA:IniciarViaje", rpta: "${sincronizadoInicioViaje ? "OK" : "ERROR->${data["Mensaje"]}"}");
      }

      int status = await AppDatabase.instance.Update(
        table: "viaje_domicilio",
        value: {"estadoInicioViaje": sincronizadoInicioViaje ? '0' : '1'},
        where: "nroViaje = '${viaje.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el inicio de viaje RECOJO en BDLocal #${viaje.nroViaje} -> TBL:viaje_domicilio", rpta: "${status > 0 ? "OK" : "ERROR->${status}"}");
    }

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].modificado == 0) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_v3", rpta: "OK");

        String rpta = await pasajeroServicio.cambiarEstadoEmbarquePasajeroDomicilio_v2(viaje.pasajeros[i], viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_v3", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            viaje.pasajeros[i].modificado = 1;

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${viaje.pasajeros[i].numDoc}' AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;

            break;
          case "1":
            pasajerosEliminar.add(viaje.pasajeros[i]);
            notificar = true;
            break;
          case "2":
          case "9":
            break;
          default:
        }
      }

      if (viaje.pasajeros[i].modificado == 2) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

        String rpta = await pasajeroServicio.registrarDesembarquePasajeroDomicilio(viaje.pasajeros[i], viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            viaje.pasajeros[i].modificado = 1;
            viaje.pasajeros[i].estadoDesem = "1"; //0 <-- desembarque

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${viaje.pasajeros[i].numDoc}' AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;

            break;
          case "1":
            pasajerosEliminar.add(viaje.pasajeros[i]);
            notificar = true;
            break;
          case "2":
          case "9":
            break;
          default:
        }
      }

      if (viaje.pasajeros[i].modificadoFechaArribo == 0) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando fecha llegada unidad #${viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

        String rpta2 = await pasajeroServicio.registrarFechaLlegadaUnidadDomicilio(viaje.pasajeros[i], viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición:  Sincronizando fecha llegada unidad #${viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta2 == "0" ? "OK" : "ERROR-> ${rpta2}"}");

        switch (rpta2) {
          case "0":
          case "1":
            viaje.pasajeros[i].modificadoFechaArribo = 1;

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${viaje.pasajeros[i].numDoc}' AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza fecha llegada unidad en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;
            break;
          case "2":
          case "3":
          case "9":
            break;
          default:
        }
      }
    }

    for (PasajeroDomicilio pEliminar in pasajerosEliminar) {
      //AppDatabase.instance.eliminarPasajero(pEliminar);
      viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);

      //DELETE PASAJERO BD LOCAL
      int status = await AppDatabase.instance.EliminarUno(
        tabla: "pasajero_domicilio",
        where: "numDoc = '${pEliminar.numDoc}' AND nroViaje = '${pEliminar.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Eliminar pasajero en BDLocal #${pEliminar.numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
    }

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].modificado == 0 || viaje.pasajeros[i].modificado == 2 || viaje.pasajeros[i].modificadoFechaArribo == 0) numeroPasajerosPorSincronizar += 1;
    }

    if (numeroPasajerosPorSincronizar == 0) {
      if (viaje.estadoViaje == "1") {
        SincronizarJornadasBD(context);

        List<Usuario> listausuario = await AppDatabase.instance.ObtenerUltimoUsuarioSincronziar();

        if (listausuario.isNotEmpty) {
          ViajeServicio servicio = new ViajeServicio();

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando finalizar viaje RECOJO #${viaje.nroViaje} -> PA:finalizar_viaje_v4", rpta: "OK");

          final rpta = await servicio.finalizarViajeV4(
            viaje.nroViaje,
            viaje.codOperacion,
            listausuario[0],
            viaje.odometroFinal.toString().trim(),
            viaje.cordenadaFinal.toString().trim(),
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando  finalizar viaje RECOJO #${viaje.nroViaje} -> PA:finalizar_viaje_v4", rpta: "${rpta == "0" || rpta == "1" ? "OK" : "ERROR-> ${rpta}"}");

          if (rpta == "0" || rpta == "1") {
            await AppDatabase.instance.EliminarUno(tabla: "pasajero_domicilio", where: "nroViaje = '${viaje.nroViaje}'");
            await AppDatabase.instance.EliminarUno(tabla: "viaje_domicilio", where: "nroViaje = '${viaje.nroViaje}'");
            await AppDatabase.instance.EliminarUno(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");
            await AppDatabase.instance.EliminarUno(tabla: "parada", where: "nroViaje = '${viaje.nroViaje}'");
            // await AppDatabase.instance.EliminarUno(tabla: "paradero", where: "");

            int status = await AppDatabase.instance.Update(
              table: "usuario",
              value: {"viajeEmp": "", "unidadEmp": "", "placaEmp": "", "fechaEmp": "", "vinculacionActiva": "0"},
              where: "numDoc = '${listausuario[0].numDoc}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Desemparejado al usuario del viaje -> TBL: usuario", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
          }
        }
      }
      datosPorSincronizar = false;
    } else {
      datosPorSincronizar = true;
    }

    if (notificar) {
      notifyListeners();
    }
    // Log.insertarLogDomicilio(context: context, mensaje: "Finaliza Sincronización viaje RECOJO ${viaje.nroViaje}", rpta: "OK");

    //await sincronizarViajeNuevosPasajeros(tipoDoc, numDoc);
  }

  SincronizarJornadasBD(BuildContext context) async {
    Log.insertarLogDomicilio(context: context, mensaje: "Inicia Sincronización Jornada", rpta: "OK");

    EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();
    List<Jornada> ListaPendiente = [];

    AppDatabase _appDatabase = AppDatabase();
    List<Jornada> listJornadas = await _appDatabase.ListarJornadas();

    for (var jornada in listJornadas) {
      if (jornada.estadobdfin == "1" || jornada.estadobdinicio == "1") {
        ListaPendiente.add(jornada);
      }
    }

    Log.insertarLogDomicilio(context: context, mensaje: "Lista Jornadas pendientes  de sincronización ${ListaPendiente.length} -> TBL: jornada", rpta: "OK");

    for (var pendiente in ListaPendiente) {
      String fechaInicioBD = "";
      String fechaFinBD = "";
      if (pendiente.decoInicio.trim().length > 0) {
        final fechaInicio = DateTime.parse(pendiente.decoInicio);
        fechaInicioBD = DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaInicio);
      }

      if (pendiente.decoInicio.trim().length > 0) {
        final fechaFin = DateTime.parse(pendiente.decoFin);
        fechaFinBD = DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaFin);
      }

      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando registrar turno jornada #${pendiente.dehoTurno} - ${pendiente.viajDni} -${pendiente.viajNroViaje} -> PA:RegistrarTurno", rpta: "OK");

      Response? resp = await _embarquesSupScanerServicio.RegistarTurno(
        pendiente.viajNroViaje,
        pendiente.dehoTurno,
        pendiente.viajDni,
        fechaInicioBD,
        fechaFinBD,
        pendiente.dehoCordenadasInicio,
        pendiente.dehoCordenadasFin,
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando registrar turno jornada #${pendiente.dehoTurno} - ${pendiente.viajDni} -${pendiente.viajNroViaje} -> PA:RegistrarTurno", rpta: resp != null && resp.body.split(",")[0] == "0" ? "OK" : "ERROR");

      if (resp != null && resp.body.split(",")[0] == "0") {
        await _appDatabase.UpdateJornada(
          {
            "EstadoBDInicio": "0", // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
            "EstadoBDFin": "0", // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
          },
          "ID=${pendiente.id}",
        );
      }
    }

    Log.insertarLogDomicilio(context: context, mensaje: "Finaliza Sincronización Jornada", rpta: "OK");
  }

  Future<void> sincronizarNuevosPasajerosDomicilio(String tipoDoc, String numDoc, BuildContext context) async {
    var servicio = new ViajeServicio();
    ViajeDomicilio viajeAux = await servicio.obtenerViajeConductorDomicilio(tipoDoc, numDoc, _viaje.nroViaje);

    if (viajeAux.rpta == "0") {
      await removerPasajerosEliminado(viajeAux.pasajeros);

      if (viajeAux.pasajeros.isNotEmpty) {
        for (int i = 0; i < viajeAux.pasajeros.length; i++) {
          bool encontrado = false;

          for (int j = 0; j < _viaje.pasajeros.length; j++) {
            if (_viaje.pasajeros[j].tipoDoc == viajeAux.pasajeros[i].tipoDoc && _viaje.pasajeros[j].numDoc == viajeAux.pasajeros[i].numDoc) {
              encontrado = true;
              //Si encuentra al pasajero actualiza los datos del recojo por si hubo cambios
              _viaje.pasajeros[j].embarcado = viajeAux.pasajeros[i].embarcado;
              _viaje.pasajeros[j].horaRecojo = viajeAux.pasajeros[i].horaRecojo;
              _viaje.pasajeros[j].direccion = viajeAux.pasajeros[i].direccion;
              _viaje.pasajeros[j].distrito = viajeAux.pasajeros[i].distrito;
              _viaje.pasajeros[j].coordenadas = viajeAux.pasajeros[i].coordenadas;
              _viaje.pasajeros[j].fechaArriboUnidad = viajeAux.pasajeros[i].fechaArriboUnidad;
              break;
            }
          }

          if (!encontrado) {
            _viaje.pasajeros.add(viajeAux.pasajeros[i]);
          }
        }

        /*for (int i = 0; i < viajeAux.pasajeros.length; i++) {
          if (!_verificarPasajeroEnLista(viajeAux.pasajeros[i])) {

            _viaje.pasajeros.add(viajeAux.pasajeros[i]);
          } else {}
        }*/

        _viaje.pasajeros.sort((a, b) => a.horaRecojo.compareTo(b.horaRecojo));

        await Provider.of<DomicilioProvider>(context, listen: false).actualizarViaje(viajeAux);

        actualizarMarkerMostrar();
        actualizarEstadoParadasRecojo();
        notifyListeners();
      }
      notifyListeners();
    }
  }

  Future<void> removerPasajerosEliminado(List<PasajeroDomicilio> pasajerosAux) async {
    bool encontrado = false;

    List<PasajeroDomicilio> pasajerosAEliminar = [];

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      encontrado = false;
      for (int j = 0; j < pasajerosAux.length; j++) {
        if (_viaje.pasajeros[i].tipoDoc == pasajerosAux[j].tipoDoc && _viaje.pasajeros[i].numDoc == pasajerosAux[j].numDoc) {
          encontrado = true;
          break;
        }
      }

      if (!encontrado) {
        pasajerosAEliminar.add(_viaje.pasajeros[i]);
      }
    }

    for (PasajeroDomicilio pEliminar in pasajerosAEliminar) {
      /*Eliminarde la bd local */
      /*AppDatabase.instance.eliminarPasajero(pEliminar);*/
      _viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);
    }

    notifyListeners();
  }

  Future<void> actualizarMarkerMostrar() async {
    _pasajeroMostrar = new PasajeroDomicilio();
    bool encontrado = false;
    if (viaje.pasajeros.isNotEmpty) {
      _viaje.pasajeros.sort((a, b) => a.horaRecojo.compareTo(b.horaRecojo));
      for (int i = 0; i < viaje.pasajeros.length; i++) {
        if (viaje.pasajeros[i].embarcado == 2 && !encontrado) {
          viaje.pasajeros[i].tocaRecojo = true;
          viaje.pasajeros[i].mostrarMarker = true;
          _pasajeroMostrar = viaje.pasajeros[i];
          encontrado = true;
        } else {
          viaje.pasajeros[i].tocaRecojo = false;
        }
      }
      _actualizarMapa = true;
      notifyListeners();
    }
  }

  Future<void> actualizarRecojo(bool nuevoEstado) async {
    _pasajeroMostrar.tocaRecojo = nuevoEstado;
    notifyListeners();
  }

  Future<void> cambiarEstadoMostrar(bool nuevoEstado) async {
    _pasajeroMostrar.mostrarMarker = nuevoEstado;
  }

  Future<void> cambiarEstadoActualizarMapa(bool estado) async {
    _actualizarMapa = estado;
    notifyListeners();
  }

  Future<void> actualizarEstadoParadasRecojo() async {
    _viaje.paradas.sort((a, b) => a.orden.compareTo(b.orden));
    _viaje.pasajeros.sort((a, b) => a.horaRecojo.compareTo(b.horaRecojo));

    bool encontrado = false;
    int indexParada = -1;

    for (int i = 0; i < viaje.paradas.length; i++) {
      int totalPasajeros = 0;
      int totalEnEspera = 0;
      int totalRegistrados = 0;
      bool tieneFechaArriboRegistrada = false;

      for (int j = 0; j < viaje.pasajeros.length; j++) {
        if (viaje.paradas[i].direccion == viaje.pasajeros[j].direccion && viaje.paradas[i].distrito == viaje.pasajeros[j].distrito && viaje.paradas[i].horaRecojo == viaje.pasajeros[j].horaRecojo && viaje.paradas[i].coordenadas == viaje.pasajeros[j].coordenadas) {
          totalPasajeros++;
          if (viaje.pasajeros[j].embarcado == 2) {
            if (!encontrado) {
              encontrado = true;
              indexParada = i;
            }

            if (viaje.pasajeros[j].fechaArriboUnidad != "") {
              tieneFechaArriboRegistrada = true;
            }
            totalEnEspera++;
          } else {
            totalRegistrados++;
          }
        }
      }

      if (totalPasajeros == totalEnEspera) {
        if (indexParada == i) {
          if (tieneFechaArriboRegistrada) {
            _viaje.paradas[i].estado = "2";
          } else {
            _viaje.paradas[i].estado = "1";
          }
          _paradaRecojoMostrar = _viaje.paradas[i];
        } else {
          _viaje.paradas[i].estado = "0";
        }
      } else {
        if (totalPasajeros == totalRegistrados) {
          _viaje.paradas[i].estado = "3";
        } else {
          _viaje.paradas[i].estado = "2";
        }
      }

      //UPDATE BD LOCAL
      await AppDatabase.instance.Update(
        table: "parada",
        value: _viaje.paradas[i].toJson(),
        where: "orden = '${_viaje.paradas[i].orden}'  AND nroViaje = '${_viaje.paradas[i].nroViaje}'",
      );
    }

    _actualizarMapa = true;
    notifyListeners();
  }

  Future<void> actualizarEstadoParadasReparto(BuildContext context) async {
    _viaje.paradas.sort((a, b) => a.orden.compareTo(b.orden));
    _viaje.pasajeros.sort((a, b) => a.horaRecojo.compareTo(b.horaRecojo));

    //bool encontrado = false;
    //int indexParada = -1;

    for (int i = 0; i < viaje.paradas.length; i++) {
      int totalPasajerosEmbarcados = 0;
      int totalPasajerosNoDesembarcados = 0;
      int totalPasajerosDesembarcados = 0;
      bool tieneFechaArriboRegistrada = false;

      for (int j = 0; j < viaje.pasajeros.length; j++) {
        if (viaje.paradas[i].direccion == viaje.pasajeros[j].direccion && viaje.paradas[i].distrito == viaje.pasajeros[j].distrito && viaje.paradas[i].horaRecojo == viaje.pasajeros[j].horaRecojo && viaje.paradas[i].coordenadas == viaje.pasajeros[j].coordenadas && viaje.pasajeros[j].embarcado == 1) {
          totalPasajerosEmbarcados++;
          if (viaje.pasajeros[j].fechaDesembarque == "") {
            /*if (!encontrado) {
              encontrado = true;
              indexParada = i;
            }*/

            if (viaje.pasajeros[j].fechaArriboUnidad != "") {
              tieneFechaArriboRegistrada = true;
            }
            totalPasajerosNoDesembarcados++;
          } else {
            totalPasajerosDesembarcados++;
          }
        }
      }

      if (totalPasajerosEmbarcados == 0) {
        _viaje.paradas[i].estado = "4";
      } else {
        if (totalPasajerosEmbarcados == totalPasajerosNoDesembarcados) {
          //if (indexParada == i) {
          if (tieneFechaArriboRegistrada) {
            _viaje.paradas[i].estado = "2";
          } else {
            _viaje.paradas[i].estado = "1";
          }
          _paradaRepartoMostrar = _viaje.paradas[i];
          /* } else {
            _viaje.paradas[i].estado = "0";
          }*/
        } else {
          if (totalPasajerosEmbarcados == totalPasajerosDesembarcados) {
            _viaje.paradas[i].estado = "3";
          } else {
            _viaje.paradas[i].estado = "2";
          }
        }
      }
      //UPDATE BD LOCAL
      int status = await AppDatabase.instance.Update(
        table: "parada",
        value: _viaje.paradas[i].toJson(),
        where: "orden = ${_viaje.paradas[i].orden}  AND nroViaje = '${_viaje.paradas[i].nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Actualiza las paradas BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:parada", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
    }
    _actualizarMapa = true;
    notifyListeners();
  }

  Future<void> actualizarParada(Parada parada) async {
    _paradaActual = parada;
    notifyListeners();
  }

  /*bool _verificarPasajeroEnLista(PasajeroDomicilio pasajeroBus) {
    if (_viaje.pasajeros.isNotEmpty) {
      for (int i = 0; i < _viaje.pasajeros.length; i++) {
        if (_viaje.pasajeros[i].tipoDoc == pasajeroBus.tipoDoc &&
            _viaje.pasajeros[i].numDoc == pasajeroBus.numDoc) {
          return true;
        }
      }
    }

    return false;
  }*/

  Future<void> addNuevoPasajeroReparto(BuildContext context, PasajeroDomicilio nuevo) async {
    _viaje.pasajeros.add(nuevo);

    //ADD BD LOCAL
    int status = await AppDatabase.instance.Guardar(
      tabla: "pasajero_domicilio",
      value: nuevo.toJsonBDLocal(),
    );

    Log.insertarLogDomicilio(context: context, mensaje: "Agrega en nuevo pasajero en BDLocal #${nuevo.numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

    Parada nuevaParada = new Parada();

    nuevaParada.nroViaje = nuevo.nroViaje;
    nuevaParada.direccion = nuevo.direccion;
    nuevaParada.distrito = nuevo.distrito;
    nuevaParada.coordenadas = nuevo.coordenadas;
    nuevaParada.horaRecojo = nuevo.horaRecojo;

    await _addParada(nuevaParada);

    notifyListeners();
  }

  Future<void> _addParada(Parada parada) async {
    bool encontrado = false;
    for (int i = 0; i < _viaje.paradas.length; i++) {
      if (_viaje.paradas[i].direccion == parada.direccion && _viaje.paradas[i].distrito == parada.distrito && _viaje.paradas[i].coordenadas == parada.coordenadas && _viaje.paradas[i].horaRecojo == parada.horaRecojo) {
        encontrado = true;
        break;
      }
    }

    if (!encontrado) {
      _viaje.paradas.sort((a, b) => a.orden.compareTo(b.orden));

      Parada paradaAux = _viaje.paradas.last;

      int orden = int.parse(paradaAux.orden);

      parada.orden = (orden + 1).toString();

      parada.recojoTaxi = "0";

      _viaje.paradas.add(parada);

      //ADD BD LOCAL
      await AppDatabase.instance.Guardar(
        tabla: "parada",
        value: parada.toJson(),
      );

      notifyListeners();
    }
  }

  Future<void> sincronizacionContinuaDeViajeDomicilioRepartoDesdeHome(String u_tipoDoc, String u_numDoc, BuildContext context, ViajeDomicilio viaje) async {
    // Log.insertarLogDomicilio(context: context, mensaje: "Inicia Sincronización viaje REPARTO ${viaje.nroViaje}", rpta: "OK");

    PasajeroServicio pasajeroServicio = new PasajeroServicio();
    int numeroPasajerosPorSincronizar = 0;
    List<PasajeroDomicilio> pasajerosEliminar = [];

    bool notificar = false;

    if (viaje.estadoInicioViaje == '1') {
      bool sincronizadoInicioViaje = false;

      final EmbarquesSupScanerServicio _embarquesSupScanerServicio = EmbarquesSupScanerServicio();

      Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando el inicio de viaje REPARTO #${viaje.nroViaje} -> PA:VincularInicioJornada", rpta: "OK");

      Response? res = await _embarquesSupScanerServicio.vincularInicioJornada_v2(
        viaje.nroViaje.trim(),
        u_numDoc.trim(),
        "1",
        u_tipoDoc.trim(),
        u_numDoc.trim(),
        viaje.codOperacion.trim(),
        viaje.odometroInicial.toString().trim(),
        viaje.cordenadaInicial.toString(),
        'NOGPS',
      );

      if (res != null) {
        final data = json.decode(res.body);
        if (data["rpta"] == '0') {
          sincronizadoInicioViaje = true;
        }

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando el inicio de viaje REPARTO  #${viaje.nroViaje} -> PA:VincularInicioJornada", rpta: "${sincronizadoInicioViaje ? "OK" : "ERROR->${data["Mensaje"]}"}");
      }

      int status = await AppDatabase.instance.Update(
        table: "viaje_domicilio",
        value: {
          "estadoInicioViaje": sincronizadoInicioViaje ? '0' : '1',
          "cordenadaInicial": "${viaje.cordenadaInicial.toString()}",
        },
        where: "nroViaje = '${viaje.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Actualiza el inicio de viaje REPARTO en BDLocal #${viaje.nroViaje} -> TBL:viaje_domicilio", rpta: "${status > 0 ? "OK" : "ERROR->${status}"}");
    }

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      //REGISTRAR DESEMBARQUE
      if (viaje.pasajeros[i].modificado == 0) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "OK");

        String rpta = await pasajeroServicio.cambiarEstadoEmbarquePasajeroDomicilio_Reparto(viaje.pasajeros[i], viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        String nuevoNumDoc = "";
        String rptaAux = "";
        if (rpta[0] == '0') {
          rptaAux = '0';
        } else {
          rptaAux = rpta;
        }

        switch (rptaAux) {
          case "0":
            //Si es nuevo pasajero
            switch (viaje.pasajeros[i].nuevo) {
              case "1":
                List<String> aux = rpta.split('/');
                nuevoNumDoc = aux[1];

                String numDocLocal = viaje.pasajeros[i].numDoc;

                viaje.pasajeros[i].nuevo = '0';
                viaje.pasajeros[i].numDoc = nuevoNumDoc;

                int status = await AppDatabase.instance.Update(
                  table: "pasajero_domicilio",
                  value: viaje.pasajeros[i].toJsonBDLocal(),
                  where: "numDoc = '$numDocLocal'  AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
                );

                Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero nuevo en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

                break;
              case "2":
                viaje.pasajeros[i].nuevo = '0';
                break;
              default:
                break;
            }

            viaje.pasajeros[i].modificado = 1;

            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${viaje.pasajeros[i].numDoc}'  AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero existente en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;
            break;
          case "-1":
            pasajerosEliminar.add(viaje.pasajeros[i]);
            notificar = true;

            break;
          case "-4": //Cuando el pasajero ya se encuentra registrado en BD y tiene una reserva
            break;
          case "-2":
          case "-3": //Error en la transacción
          case "-9":
            break;
          default:
        }
      }

      //REGISTRAR FECHA ARRIBO UNIDAD
      if (viaje.pasajeros[i].modificadoFechaArribo == 0 && viaje.pasajeros[i].nuevo == "0") {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando fecha llegada unidad #${viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

        String rpta2 = await pasajeroServicio.registrarFechaLlegadaUnidadDomicilio(viaje.pasajeros[i], viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando fecha llegada unidad #${viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta2 == "0" ? "OK" : "ERROR-> ${rpta2}"}");

        switch (rpta2) {
          case "0":
          case "1":
            viaje.pasajeros[i].modificadoFechaArribo = 1;

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${viaje.pasajeros[i].numDoc}'  AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza fecha llegada unidad en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;
            break;
          case "2":
          case "3":
          case "9":
            break;
          default:
        }
      }

      //REGISTRAR REPARTO

      if (viaje.pasajeros[i].modificadoAccion == 0 && viaje.pasajeros[i].nuevo == "0") {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

        String rpta = await pasajeroServicio.registrarDesembarquePasajeroDomicilio(viaje.pasajeros[i], viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            viaje.pasajeros[i].modificadoAccion = 1;
            viaje.pasajeros[i].estadoDesem = "1"; //0 <-- desembarque

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${viaje.pasajeros[i].numDoc}'  AND nroViaje = '${viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero en BDLocal #${viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;

            break;
          case "1":
            pasajerosEliminar.add(viaje.pasajeros[i]);
            notificar = true;
            break;
          case "2":
          case "9":
            break;
          default:
        }
      }
    }

    for (PasajeroDomicilio pEliminar in pasajerosEliminar) {
      //AppDatabase.instance.eliminarPasajero(pEliminar);
      viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);

      //DELETE PASAJERO BD LOCAL
      int status = await AppDatabase.instance.EliminarUno(
        tabla: "pasajero_domicilio",
        where: "numDoc = '${pEliminar.numDoc}'  AND nroViaje = '${pEliminar.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Eliminar pasajero en BDLocal #${pEliminar.numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
    }

    for (int i = 0; i < viaje.pasajeros.length; i++) {
      if (viaje.pasajeros[i].modificado == 0 || viaje.pasajeros[i].modificadoAccion == 0 || viaje.pasajeros[i].modificadoFechaArribo == 0) numeroPasajerosPorSincronizar += 1;
    }

    if (numeroPasajerosPorSincronizar == 0) {
      if (viaje.estadoViaje == "1") {
        SincronizarJornadasBD(context);

        List<Usuario> listausuario = await AppDatabase.instance.ObtenerUltimoUsuarioSincronziar();

        if (listausuario.isNotEmpty) {
          ViajeServicio servicio = new ViajeServicio();

          Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando finalizar viaje REPARTO #${viaje.nroViaje} -> PA:finalizar_viaje_v4", rpta: "OK");

          final rpta = await servicio.finalizarViajeV4(
            viaje.nroViaje,
            viaje.codOperacion,
            listausuario[0],
            viaje.odometroFinal.toString(),
            viaje.cordenadaFinal.toString(),
          );

          Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando  finalizar viaje REPARTO #${viaje.nroViaje} -> PA:finalizar_viaje_v4", rpta: "${rpta == "0" || rpta == "1" ? "OK" : "ERROR-> ${rpta}"}");

          if (rpta == "0" || rpta == "1") {
            await AppDatabase.instance.EliminarUno(tabla: "pasajero_domicilio", where: "nroViaje = '${viaje.nroViaje}'");
            await AppDatabase.instance.EliminarUno(tabla: "viaje_domicilio", where: "nroViaje = '${viaje.nroViaje}'");
            await AppDatabase.instance.EliminarUno(tabla: "tripulante", where: "nroViaje = '${viaje.nroViaje}'");
            await AppDatabase.instance.EliminarUno(tabla: "parada", where: "nroViaje = '${viaje.nroViaje}'");
            // await AppDatabase.instance.EliminarUno(tabla: "paradero", where: "");

            int status = await AppDatabase.instance.Update(
              table: "usuario",
              value: {"viajeEmp": "", "unidadEmp": "", "placaEmp": "", "fechaEmp": "", "vinculacionActiva": "0"},
              where: "numDoc = '${listausuario[0].numDoc}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Desemparejado al usuario del viaje -> TBL: usuario", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
          }
        }
      }
      datosPorSincronizar = false;
    } else {
      datosPorSincronizar = true;
    }

    if (notificar) {
      notifyListeners();
    }

    // Log.insertarLogDomicilio(context: context, mensaje: "Finaliza Sincronización viaje REPARTO ${viaje.nroViaje}", rpta: "OK");

    //await sincronizarViajeNuevosPasajeros(tipoDoc, numDoc);
  }

  Future<void> sincronizacionContinuaDeViajeDomicilioReparto(String u_tipoDoc, String u_numDoc, BuildContext context) async {
    // Log.insertarLogDomicilio(context: context, mensaje: "Inicia Sincronización en pantalla de REPARTO ${_viaje.nroViaje}", rpta: "OK");

    PasajeroServicio pasajeroServicio = new PasajeroServicio();
    int numeroPasajerosPorSincronizar = 0;
    List<PasajeroDomicilio> pasajerosEliminar = [];

    bool notificar = false;

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      //REGISTRAR DESEMBARQUE
      if (_viaje.pasajeros[i].modificado == 0) {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "OK");

        String rpta = await pasajeroServicio.cambiarEstadoEmbarquePasajeroDomicilio_Reparto(_viaje.pasajeros[i], _viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:cambiar_estado_embarque_pasajero_domicilio_reparto", rpta: "${rpta == "0" ? "OK" : "ERROR-> ${rpta}"}");

        String nuevoNumDoc = "";
        String rptaAux = "";
        if (rpta[0] == '0') {
          rptaAux = '0';
        } else {
          rptaAux = rpta;
        }

        switch (rptaAux) {
          case "0":
            //Si es nuevo pasajero
            switch (_viaje.pasajeros[i].nuevo) {
              case "1":
                List<String> aux = rpta.split('/');
                nuevoNumDoc = aux[1];

                String numDocLocal = _viaje.pasajeros[i].numDoc;

                _viaje.pasajeros[i].nuevo = '0';
                _viaje.pasajeros[i].numDoc = nuevoNumDoc;

                int status = await AppDatabase.instance.Update(
                  table: "pasajero_domicilio",
                  value: _viaje.pasajeros[i].toJsonBDLocal(),
                  where: "numDoc = '$numDocLocal'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
                );

                Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero nuevo en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

                break;
              case "2":
                _viaje.pasajeros[i].nuevo = '0';
                break;
              default:
                break;
            }

            _viaje.pasajeros[i].modificado = 1;

            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: _viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza al pasajero existente en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;
            break;
          case "-1":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            notificar = true;

            break;
          case "-4": //Cuando el pasajero ya se encuentra registrado en BD y tiene una reserva
            break;
          case "-2":
          case "-3": //Error en la transacción
          case "-9":
            break;
          default:
        }
      }

      //REGISTRAR FECHA ARRIBO UNIDAD
      if (_viaje.pasajeros[i].modificadoFechaArribo == 0 && _viaje.pasajeros[i].nuevo == "0") {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando fecha llegada unidad #${_viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "OK");

        String rpta2 = await pasajeroServicio.registrarFechaLlegadaUnidadDomicilio(_viaje.pasajeros[i], _viaje.codOperacion, u_tipoDoc + u_numDoc);

        Log.insertarLogDomicilio(context: context, mensaje: "Finaliza petición: Sincronizando fecha llegada unidad #${_viaje.pasajeros[i].numDoc} -> PA:registrar_fechaLlegada_unidad_domicilio_v2", rpta: "${rpta2 == "0" ? "OK" : "ERROR-> ${rpta2}"}");

        switch (rpta2) {
          case "0":
          case "1":
            _viaje.pasajeros[i].modificadoFechaArribo = 1;

            //UPDATE PASAJERO BD LOCAL
            int status = await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: _viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
            );

            Log.insertarLogDomicilio(context: context, mensaje: "Actualiza fecha llegada unidad en BDLocal #${_viaje.pasajeros[i].numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");

            notificar = true;
            break;
          case "2":
          case "3":
          case "9":
            break;
          default:
        }
      }

      //REGISTRAR REPARTO

      if (_viaje.pasajeros[i].modificadoAccion == 0 && _viaje.pasajeros[i].nuevo == "0") {
        //datosPorSincronizar = true;

        Log.insertarLogDomicilio(context: context, mensaje: "Inicia petición: Sincronizando al pasajero #${_viaje.pasajeros[i].numDoc} -> PA:registrar_desembarque_pasajero_domicilio_v2", rpta: "OK");

        String rpta = await pasajeroServicio.registrarDesembarquePasajeroDomicilio(_viaje.pasajeros[i], _viaje.codOperacion, u_tipoDoc + u_numDoc);
        switch (rpta) {
          case "0":
            //datosPorSincronizar = false;
            _viaje.pasajeros[i].modificadoAccion = 1;
            viaje.pasajeros[i].estadoDesem = "1"; //0 <-- desembarque

            //UPDATE PASAJERO BD LOCAL
            await AppDatabase.instance.Update(
              table: "pasajero_domicilio",
              value: _viaje.pasajeros[i].toJsonBDLocal(),
              where: "numDoc = '${_viaje.pasajeros[i].numDoc}'  AND nroViaje = '${_viaje.pasajeros[i].nroViaje}'",
            );

            notificar = true;

            break;
          case "1":
            pasajerosEliminar.add(_viaje.pasajeros[i]);
            notificar = true;
            break;
          case "2":
          case "9":
            break;
          default:
        }
      }
    }

    for (PasajeroDomicilio pEliminar in pasajerosEliminar) {
      //AppDatabase.instance.eliminarPasajero(pEliminar);
      _viaje.pasajeros.removeWhere((element) => element.numDoc == pEliminar.numDoc);

      //DELETE PASAJERO BD LOCAL
      int status = await AppDatabase.instance.EliminarUno(
        tabla: "pasajero_domicilio",
        where: "numDoc = '${pEliminar.numDoc}'  AND nroViaje = '${pEliminar.nroViaje}'",
      );

      Log.insertarLogDomicilio(context: context, mensaje: "Eliminar pasajero en BDLocal #${pEliminar.numDoc} -> TBL:pasajero_domicilio", rpta: "${status > 0 ? "OK" : "ERROR-> ${status}"}");
    }

    for (int i = 0; i < _viaje.pasajeros.length; i++) {
      if (_viaje.pasajeros[i].modificado == 0 || _viaje.pasajeros[i].modificadoAccion == 0 || _viaje.pasajeros[i].modificadoFechaArribo == 0) numeroPasajerosPorSincronizar += 1;
    }

    if (numeroPasajerosPorSincronizar == 0) {
      datosPorSincronizar = false;
    } else {
      datosPorSincronizar = true;
    }

    // Log.insertarLogDomicilio(context: context, mensaje: "Inicia Sincronización en pantalla de REPARTO ${_viaje.nroViaje}", rpta: "OK");

    if (notificar) {
      notifyListeners();
    }

    //await sincronizarViajeNuevosPasajeros(tipoDoc, numDoc);
  }
}

class AuthIdModel extends ChangeNotifier {
  String _authId = '';
  String _authAccion = '';

  String get authId => _authId;
  String get authAccion => _authAccion;

  void updateAuthData(String newId, String newAccion) {
    _authId = newId;
    _authAccion = newAccion;
    notifyListeners();
  }
}

class docsIdModel extends ChangeNotifier {
  String _authId = '';
  String _authAccion = '';

  String get authId => _authId;
  String get authAccion => _authAccion;

  void updateAuthData(String newId, String newAccion) {
    _authId = newId;
    _authAccion = newAccion;
    notifyListeners();
  }
}


class SubAuthActionModel {
  final String id;
  final String action;
  final String orden;

  SubAuthActionModel(this.id, this.action, this.orden);
}

class SubAuthIdModel extends ChangeNotifier {
  SubAuthActionModel _subAuthAction = SubAuthActionModel('', '', '');

  SubAuthActionModel get subAuthAction => _subAuthAction;

  void updateAuthAction(SubAuthActionModel newAction) {
    _subAuthAction = newAction;
    notifyListeners();
  }
}

class NotificationProvider with ChangeNotifier {
  String? _notificationPage;

  String? get notificationPage => _notificationPage;

  void setNotificationPage(String page) {
    _notificationPage = page;
    notifyListeners();
  }
}
