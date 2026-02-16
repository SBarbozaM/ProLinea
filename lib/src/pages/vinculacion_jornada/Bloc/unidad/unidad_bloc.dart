import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:embarques_tdp/src/models/tripulante.dart';
import 'package:embarques_tdp/src/services/embarques_sup_scaner_servicio.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

part 'unidad_event.dart';
part 'unidad_state.dart';

class UnidadBloc extends Bloc<UnidadEvent, UnidadState> {
  final EmbarquesSupScanerServicio _embarquesSupScanerServicio;
  UnidadBloc({
    required EmbarquesSupScanerServicio embarquesSupScanerServicio,
  })  : _embarquesSupScanerServicio = embarquesSupScanerServicio,
        super(UnidadInitial()) {
    on<resetEstadoUnidadInitial>((event, emit) => emit(UnidadInitial()));
    on<ResetListTripulantes>((event, emit) => emit(
          UnidadInitial(),
        ));
    on<EscanearUnidadJornada>(_escanearUnidad);
    on<SetStateUnidadSuccess>(
      (event, emit) => emit(
        UnidadSuccess(
          numConductor: "0",
          numViaje: event.numViaje,
          codUnidad: event.codUnidad,
          placa: event.placa,
          rpta: "",
          listTripulante: [],
        ),
      ),
    );
  }

  _escanearUnidad(
    EscanearUnidadJornada event,
    Emitter<UnidadState> emit,
  ) async {
    emit(UnidadProgress());

    Response? response = await _embarquesSupScanerServicio.ScanearUnidadJornada(
        event.textQR, event.codigoOperacion);

    if (response != null) {
      final data = json.decode(response.body);
      print(data);
      if (data["rpta"] == '0') {
        List<Tripulante> listaTripulante = [];

        if (data["numeroC1"].toString().trim().length > 0) {
          listaTripulante.add(
            Tripulante(
              tipoDoc: data["tipoDocC1"],
              numDoc: data["numeroC1"],
              nombres: data["nombreC1"],
              nroViaje: data["nroViaje"],
              tipo: "",
              orden: "1",
            ),
          );
        }

        if (data["numeroC2"].toString().trim().length > 0) {
          listaTripulante.add(
            Tripulante(
              tipoDoc: data["tipoDocC2"],
              numDoc: data["numeroC2"],
              nombres: data["nombreC2"],
              nroViaje: data["nroViaje"],
              tipo: "",
              orden: "2",
            ),
          );
        }

        if (data["numeroC3"].toString().trim().length > 0) {
          listaTripulante.add(
            Tripulante(
              tipoDoc: data["tipoDocC3"],
              numDoc: data["numeroC3"],
              nombres: data["nombreC3"],
              nroViaje: data["nroViaje"],
              tipo: "",
              orden: "3",
            ),
          );
        }

        if (data["numeroAy"].toString().trim().length > 0) {
          listaTripulante.add(
            Tripulante(
              tipoDoc: data["tipoDocAy"],
              numDoc: data["numeroAy"],
              nombres: data["nombreAy"],
              nroViaje: data["nroViaje"],
              tipo: "",
              orden: "4",
            ),
          );
        }

        bool UsuarioauthEsTripulante = false;

        for (var tripulante in listaTripulante) {
          if (tripulante.numDoc.trim() == event.usuarioAuth.trim()) {
            UsuarioauthEsTripulante = true;
          }
        }

        if (UsuarioauthEsTripulante) {
          emit(
            UnidadSuccess(
              numConductor: data["conductores"],
              numViaje: data["nroViaje"],
              codUnidad: data["codUnidad"],
              placa: data["placa"],
              rpta: data["rpta"],
              listTripulante: listaTripulante,
            ),
          );
        } else {
          emit(UnidadFailure("0", "0", "9",
              "No se encuentra en los tripulantes de este viaje"));
        }
      } else {
        emit(UnidadFailure(data["conductores"] ?? "", data["nroViaje"] ?? "",
            data["rpta"], data["mensaje"]));
      }
    } else {
      emit(UnidadFailure("0", "0", "9", "No tiene conexión a internet"));
    }
  }
}
