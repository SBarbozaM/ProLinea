import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:embarques_tdp/src/models/datos_vinculacion.dart';
import 'package:embarques_tdp/src/models/jornada.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/models/turno.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';
import 'package:embarques_tdp/src/utils/formatFecha.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

part 'jornada_event.dart';
part 'jornada_state.dart';

class JornadaBloc extends Bloc<JornadaEvent, JornadaState> {
  final AppDatabase _appDatabase;
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;
  JornadaBloc({
    required AppDatabase appDatabase,
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _appDatabase = appDatabase,
        _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(JornadaState()) {
    on<AddTripulante>(_AddTripulante);
    on<Iniciarjornada>(_IniciarJornada);
    on<FinalizarJornada>(_FinalizarJornada);
    on<Listarjornadas>(_ListarJornadas);
    on<ContinuarVinculacion>(_ContinuarVinculacion);

    on<resetJornadaActual>(
      (event, emit) => emit(
        state.copyWith(
          vinculacion: "",
          NombreJornadaActual: "",
          idJornadaActual: "",
          code: "0",
        ),
      ),
    );
  }

  _ListarJornadas(
    Listarjornadas event,
    Emitter<JornadaState> emit,
  ) async {
    final listaJornadaList = await _appDatabase.ListarJornada(event.nroViaje);
    final tripulante = listaJornadaList.firstWhereOrNull((element) => element.estado == "1");

    if (tripulante != null) {
      emit(state.copyWith(
        idJornadaActual: tripulante.viajDni,
        NombreJornadaActual: tripulante.viajNombre,
        code: "0",
      ));
    }
  }

  _ContinuarVinculacion(
    ContinuarVinculacion event,
    Emitter<JornadaState> emit,
  ) async {
    emit(
      state.copyWith(
        vinculacion: "",
        mensaje: "",
        code: "0",
      ),
    );

    for (var tripulante in event.list) {
      Response? res = await _embarquesSupScanerServicio.vincularInicioJornada_v2(
        event.numViaje.trim(),
        tripulante.numDoc.trim(),
        tripulante.orden.trim(),
        event.tDocUsuario.trim(),
        event.nDocUsuario.trim(),
        event.codOperacion.trim(),
        event.odometroInicio.trim(),
        event.coordenadas,
        'NOGPS',
      );

      if (res != null) {
        final data = json.decode(res.body);

        if (data["rpta"] != '0') {
          return emit(state.copyWith(
            vinculacion: "",
            mensaje: data["mensaje"],
            code: "500",
          ));
        }
      }
    }

    DatosVinculacion datosVinculacion = await _embarquesSupScanerServicio.obtenerDatosVinculacion(event.tDocUsuario, event.nDocUsuario, event.codOperacion);

    await _appDatabase.Update(
      table: "usuario",
      value: {"viajeEmp": datosVinculacion.viajeEmp, "unidadEmp": datosVinculacion.unidadEmp, "placaEmp": datosVinculacion.placaEmp, "fechaEmp": datosVinculacion.fechaEmp, "vinculacionActiva": datosVinculacion.viajeEmp == "" ? '0' : "1"},
      where: "numDoc = '${event.nDocUsuario.trim()}'",
    );

    await AppDatabase.instance.Update(
      table: "viaje",
      value: {
        "odometroInicial": '${event.odometroInicio.trim()}',
        "cordenadaInicial": "${event.coordenadas}",
      },
      where: "nroViaje = '${event.numViaje.trim()}'",
    );

    emit(state.copyWith(
      vinculacion: "activa",
      code: "5",
    ));
  }

  _IniciarJornada(
    Iniciarjornada event,
    Emitter<JornadaState> emit,
  ) async {
    // emit(state.copyWith(
    //   code: "0",
    // ));
    final listaJornada = await _appDatabase.ListarJornada(event.nrViaje);

    //VALIDA QUE LA JORNADA INICIADA LE PERTENESCA
    for (var element in listaJornada) {
      if (element.estado == "1" && element.viajDni != event.nDocConducto) {
        return emit(state.copyWith(
          code: "1",
          mensaje: "Exite una jornada iniciada y no le pertenece",
        ));
      }
      //FINALIZA LA JORNADA
      if (element.estado == "1" && element.viajDni == event.nDocConducto) {
        return add(FinalizarJornada(event.nDocConducto, event.nrViaje, event.cordenadas));
      }
    }

    final tripulante = listaJornada.lastWhereOrNull((element) => element.viajDni == event.nDocConducto);

    //VALIDA SI TIENE UNA JORNADA FINALIZADA
    if (tripulante != null && tripulante.estado == "2") {
      emit(state.copyWith(code: "0"));
      final DateTime IniDia = DateTime.parse("${DateFormat("yyyy-MM-dd").format(DateTime.now())} 06:00");
      final DateTime FinDia = DateTime.parse("${DateFormat("yyyy-MM-dd").format(DateTime.now())} 21:59");

      final DateTime IniJornada = DateTime.parse(tripulante.decoInicio);
      final DateTime FinJornada = DateTime.parse(tripulante.decoFin);

      int TramoMinutos = 0;

      if (FinJornada.compareTo(IniDia) >= 0 && FinJornada.compareTo(FinDia) <= 0) {
        TramoMinutos = 5 * 60;
      } else {
        TramoMinutos = 4 * 60;
      }
      final hourTr = DateTime.now()
          .subtract(
            Duration(
              days: IniJornada.day,
              hours: IniJornada.hour,
              minutes: IniJornada.minute,
            ),
          )
          .hour;
      final minutosTr = DateTime.now()
          .subtract(
            Duration(
              days: IniJornada.day,
              hours: IniJornada.hour,
              minutes: IniJornada.minute,
            ),
          )
          .minute;

      final minutosTrans = (hourTr * 60) + minutosTr;

      if (minutosTrans < TramoMinutos) {
        //SnackBar
        return emit(state.copyWith(
          idJornadaActual: "",
          code: "1",
          mensaje: "Aún no pasan ${(TramoMinutos / 60).round()} horas para iniciar su jornada. Última jornada finalizó: ${FinJornada.hour}:${FinJornada.minute} ",
        ));
      } else {
        //NuevaJornada
        int turno = listaJornada.where((c) => c.estado != "0").length;

        final fechaInicio = DateTime.now();

        await _appDatabase.GuardarJornada(
          {
            "VIAJ_Nro_Viaje": tripulante.viajNroViaje,
            "VIAJ_TipoDoc": tripulante.viajTipoDoc,
            "VIAJ_Dni": tripulante.viajDni,
            "VIAJ_NOMBRE": tripulante.viajNombre,
            "DEHO_Turno": (turno + 1).toString(),
            "DEHO_Usuario": event.usuarioLogeo,
            "DECO_Inicio": DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaInicio),
            "DEHO_Cordenadas_Inicio": event.cordenadas,
            "Estado": 1, // 0: no iniciada // 1: iniciada // 2: finalizada
          },
        );

        String status = "1";
        String llego = "";

        Response? response = await _embarquesSupScanerServicio.RegistarTurno(
          tripulante.viajNroViaje,
          (turno + 1).toString(),
          tripulante.viajDni,
          DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaInicio),
          "",
          event.cordenadas,
          tripulante.dehoCordenadasFin,
        );

        if (response != null && response.body != "500") {
          llego = response.body.split(",")[1];
          status = response.body.split(",")[0];
        }

        await _appDatabase.UpdateJornada(
          {
            "EstadoBDInicio": status, // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
          },
          "ID=${tripulante.id}",
        );

        emit(state.copyWith(
          idJornadaActual: tripulante.viajDni,
          NombreJornadaActual: tripulante.viajNombre,
          code: "2",
          mensaje: "Jornada iniciada con exito",
        ));

        final listaJornadaList = await _appDatabase.ListarJornada(event.nrViaje);
        return emit(state.copyWith(listJornada: listaJornadaList, code: "0"));
      }
    }

    // CUANDO NINGUNO A INICIADO UNA JORNADA
    if (tripulante != null && tripulante.estado == "0") {
      int turno = listaJornada.where((c) => c.estado != "0").length;
      final fecha = DateTime.now();

      await _appDatabase.UpdateJornada(
        {
          "DEHO_Turno": (turno + 1).toString(),
          "DEHO_Usuario": event.usuarioLogeo,
          "DECO_Inicio": DateFormat('yyyy-MM-dd HH:mm:ss').format(fecha),
          "DEHO_Cordenadas_Inicio": event.cordenadas,
          "Estado": 1, //INICIADO
        },
        "ID=${tripulante.id}",
      );
      String status = "1";
      String llego = "";

      Response? response = await _embarquesSupScanerServicio.RegistarTurno(
        tripulante.viajNroViaje,
        (turno + 1).toString(),
        tripulante.viajDni,
        DateFormat('dd/MM/yyyy HH:mm:ss').format(fecha),
        "",
        event.cordenadas,
        tripulante.dehoCordenadasFin,
      );

      if (response != null && response.body != "500") {
        llego = response.body.split(",")[1];
        status = response.body.split(",")[0];
      }

      await _appDatabase.UpdateJornada(
        {
          "EstadoBDInicio": status, // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
        },
        "ID=${tripulante.id}",
      );

      // if (llego == "1") {
      //   //LIMPIAMOS BD LOCAL
      //   await _appDatabase.EliminaJornadas();
      // }

      emit(state.copyWith(
        idJornadaActual: tripulante.viajDni,
        NombreJornadaActual: tripulante.viajNombre,
        code: "2",
        mensaje: "Jornada iniciada con exito",
      ));
    } else {
      emit(state.copyWith(
        idJornadaActual: "",
        code: "1",
        mensaje: "El conductor no se encuentra vinculado previamente",
      ));
    }

    final listaJornadaList = await _appDatabase.ListarJornada(event.nrViaje);
    emit(state.copyWith(listJornada: listaJornadaList, code: "0"));
  }

  _FinalizarJornada(
    FinalizarJornada event,
    Emitter<JornadaState> emit,
  ) async {
    final listaJornada = await _appDatabase.ListarJornada(event.nrViaje);

    final tripulante = listaJornada.firstWhereOrNull((element) => element.viajDni == event.nDocConducto);

    if (tripulante != null) {
      String status = "1";
      String llego = "";
      final fechaFin = DateTime.now();

      await _appDatabase.UpdateJornada(
        {
          "DECO_Fin": DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaFin),
          "DEHO_Cordenadas_Fin": event.cordenadas,
          "Estado": 2, //FINALIZADO
        },
        "ID=${tripulante.id}",
      );

      final tripulanteBD = listaJornada.firstWhereOrNull((element) => element.viajDni == event.nDocConducto);

      final fechainicio = DateTime.parse(tripulanteBD!.decoInicio);

      Response? response = await _embarquesSupScanerServicio.RegistarTurno(
        tripulanteBD.viajNroViaje,
        tripulanteBD.dehoTurno,
        tripulanteBD.viajDni,
        DateFormat('dd/MM/yyyy HH:mm:ss').format(fechainicio),
        DateFormat('dd/MM/yyyy HH:mm:ss').format(fechaFin),
        tripulanteBD.dehoCordenadasInicio,
        event.cordenadas,
      );

      if (response != null && response.body != "500") {
        llego = response.body.split(",")[1];
        status = response.body.split(",")[0];
      }

      await _appDatabase.UpdateJornada(
        {
          "EstadoBDFin": status, // 0: SINCRONIZADO CON BD 1: NO SINCRONIZADO CON BD
        },
        "ID=${tripulante.id}",
      );

      // if (llego == "1") {
      //   //LIMPIAMOS BD LOCAL
      //   await _appDatabase.EliminaJornadas();
      // }

      emit(state.copyWith(
        idJornadaActual: "",
        code: "3",
        mensaje: "Jornada finalizada con éxito",
      ));
    } else {
      emit(state.copyWith(
        idJornadaActual: "",
        code: "1",
        mensaje: "El conductor no se encuentra vinculado previamente",
      ));
    }
    final listaJornadaList = await _appDatabase.ListarJornada(event.nrViaje);
    emit(state.copyWith(listJornada: listaJornadaList, code: "0"));
  }

  _AddTripulante(
    AddTripulante event,
    Emitter<JornadaState> emit,
  ) async {
    List<Turno> listaTurnos = [];

    Response? responseTurnos = await _embarquesSupScanerServicio.ObtenerTurnoViajeVincualdo(event.nroViaje);

    List<Jornada> listJornada = await _appDatabase.ListarJornada(event.nroViaje);

    if (responseTurnos != null) {
      final decodeData = json.decode(responseTurnos.body) as List;
      final listaT = decodeData.map((e) => Turno.fromJson(e)).toList();
      for (var turno in listaT) {
        if (turno.viaJDni == event.nDocConducto) {
          listaTurnos.add(turno);
        }
      }
    }

    Jornada newJornada = Jornada.constructor(
      id: 0,
      viajNroViaje: event.nroViaje,
      dehoTurno: "",
      viajTipoDoc: event.tDocConducto,
      viajNombre: event.nombreConductor,
      viajDni: event.nDocConducto,
      decoInicio: "",
      decoFin: "",
      dehoCordenadasInicio: "",
      dehoCordenadasFin: "",
      dehoUsuario: "",
      dehoPc: "",
      dehoFecha: "",
      dehoTipo: "",
      estado: "0",
      estadobdinicio: "",
      estadobdfin: "",
    );

    bool guardar = true;

    for (var turno in listaTurnos) {
      final jornada = listJornada.firstWhereOrNull((jornada) => jornada.viajDni == turno.viaJDni && jornada.dehoTurno != turno.dehOTurno);
      if (jornada == null) {
        newJornada.dehoTurno = turno.dehOTurno;
        newJornada.decoInicio = turno.dehOInicio;
        newJornada.decoFin = turno.dehOFin;
        newJornada.dehoCordenadasInicio = turno.dehOCordenadasInicio;
        newJornada.dehoCordenadasFin = turno.dehOCordenadasFin;
        newJornada.estado = turno.dehOCordenadasInicio == ""
            ? "0"
            : turno.dehOCordenadasFin == ""
                ? "1"
                : "2";
        newJornada.estadobdinicio = "0";
        newJornada.estadobdfin = "0";
        guardar = false;
        await _appDatabase.GuardarJornada(
          {
            "VIAJ_Nro_Viaje": newJornada.viajNroViaje,
            "DEHO_Turno": newJornada.dehoTurno,
            "VIAJ_TipoDoc": newJornada.viajTipoDoc,
            "VIAJ_NOMBRE": newJornada.viajNombre,
            "VIAJ_Dni": newJornada.viajDni,
            "DECO_Inicio": newJornada.decoInicio,
            "DECO_Fin": newJornada.decoFin,
            "DEHO_Cordenadas_Inicio": newJornada.dehoCordenadasInicio,
            "DEHO_Cordenadas_Fin": newJornada.dehoCordenadasFin,
            "Estado": newJornada.estado, // 0: no iniciada // 1: iniciada // 2: finalizada
            "EstadoBDInicio": newJornada.estadobdinicio,
            "EstadoBDFin": newJornada.estadobdfin
          },
        );
      }
    }

    if (guardar) {
      await _appDatabase.GuardarJornada(
        {
          "VIAJ_Nro_Viaje": newJornada.viajNroViaje,
          "DEHO_Turno": newJornada.dehoTurno,
          "VIAJ_TipoDoc": newJornada.viajTipoDoc,
          "VIAJ_NOMBRE": newJornada.viajNombre,
          "VIAJ_Dni": newJornada.viajDni,
          "DECO_Inicio": newJornada.decoInicio,
          "DECO_Fin": newJornada.decoFin,
          "DEHO_Cordenadas_Inicio": newJornada.dehoCordenadasInicio,
          "DEHO_Cordenadas_Fin": newJornada.dehoCordenadasFin,
          "Estado": newJornada.estado, // 0: no iniciada // 1: iniciada // 2: finalizada
          "EstadoBDInicio": newJornada.estadobdinicio,
          "EstadoBDFin": newJornada.estadobdfin
        },
      );
    }

    final listaJornadaList = await _appDatabase.ListarJornada(event.nroViaje);
    emit(state.copyWith(listJornada: listaJornadaList, code: "0"));
  }
}
