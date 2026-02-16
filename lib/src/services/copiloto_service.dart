import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:embarques_tdp/src/connection/conexion.dart';
import 'package:embarques_tdp/src/models/Copiloto/grocerca_ruta_model.dart';
import 'package:embarques_tdp/src/models/Copiloto/operacion_model.dart';
import 'package:embarques_tdp/src/utils/app_database.dart';

import '../models/Copiloto/geocerca_model.dart';
import 'package:http/http.dart' as http;

class GeocercaService {
  static String _url = Conexion.apiUrl;

  Future<void> fetchAndSaveGeocercas() async {
    final url = _url + 'GetListaGeocercas';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> geocercasJson = data['geocercas'];
        List<dynamic> geocercasDetalleJson = data['geocercaDetalle'];

        for (var geocercaJson in geocercasJson) {
          Geocerca geocerca = Geocerca.fromJson(geocercaJson);
          await AppDatabase.instance.insertarActualizarGeocerca(geocerca);
        }

        // Guardar los detalles de las Geocercas en la base de datos
        for (var detalleJson in geocercasDetalleJson) {
          GeocercaDetalle detalle = GeocercaDetalle.fromJson(detalleJson);
          await AppDatabase.instance.insertarActualizarGeocercaDetalle(detalle);
        }
      } else {
        throw Exception('Error al cargar las geocercas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Operacion>> fetchOperaciones() async {
    final url = _url + 'GetListaOperaciones';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Asegúrate de que 'data' sea una lista de objetos
        List<dynamic> operacionesJson = data;

        // Usamos 'fromJson' para convertir cada item de la respuesta en una instancia de 'Operacion'
        List<Operacion> operaciones = operacionesJson.map((operacionJson) {
          return Operacion.fromJson(operacionJson);
        }).toList();

        for (var operacion in operaciones) {
          await AppDatabase.instance.insertOperacion(operacion);
        }

        return operaciones;
      } else {
        throw Exception('Error al cargar las operaciones');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<bool> fetchGeocercasRutas() async {
    final url = _url + 'GetListaGeosRutas'; // Asegúrate de cambiar la URL

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> geocercasRutasJson = data;

        List<GeocercaRuta> geocercasRutas = geocercasRutasJson.map((geocercaRutaJson) {
          return GeocercaRuta.fromJson(geocercaRutaJson);
        }).toList();

        for (var geocercaRuta in geocercasRutas) {
          await AppDatabase.instance.insertGeocercaRuta(geocercaRuta);
        }

        // Si todo fue bien, devolvemos true
        return true;
      } else {
        throw Exception('Error al cargar las geocercas rutas');
      }
    } catch (e) {
      // Si ocurre un error, imprimimos el error y devolvemos false
      print('Error: $e');
      return false;
    }
  }

  static Future<void> enviarDatosGps(
    double latitud,
    double longitud,
    int velocidad,
    int velocidadGeocerca,
    int alerta,
    int idUsuario,
    String fechaRegistro,
    String igGeocerca,
  ) async {
    final url = _url + 'InsertarGPSCopilotoPosition'; // Concatenar la URL base con el endpoint específico
    final urlFinal = Uri.parse(url); // Convertir la URL final a un objeto Uri

    // Datos que se enviarán en el cuerpo de la solicitud
    final Map<String, dynamic> data = {
      'Latitud': latitud,
      'Longitud': longitud,
      'Velocidad': velocidad,
      'VelocidadGeocerca': velocidadGeocerca,
      'Alerta': alerta,
      'IdUsuario': idUsuario,
      'FechaRegistro': fechaRegistro,
      'IdGeocerca': igGeocerca,
    };

    // Realizar la solicitud POST
    try {
      final response = await http.post(
        urlFinal,
        headers: {
          'Content-Type': 'application/json', // Especificamos que los datos son JSON
        },
        body: json.encode(data), // Convertir el Map a formato JSON
      );

      if (response.statusCode == 200) {
        // La5 solicitud fue exitosa
        print('Datos GPS enviados correctamente');
      } else {
        // Error al enviar los datos
        print('Error al enviar los datos GPS: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al hacer la solicitud: $e');
    }
  }

  Future<String> obtenerCodigoRuta(String tdoc, String ndoc) async {
    final url = Uri.parse(_url + 'obtener_ruta_condutor');

    try {
      Map<String, String> body = {
        'Tdoc': tdoc,
        'Ndoc': ndoc,
      };

      final response = await http.post(url, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ruta'] ?? '';
      } else {
        throw Exception('Error al cargar las operaciones: Código de respuesta ${response.statusCode}');
      }
    } on SocketException {
      print('No hay conexión a Internet');
      return '';
    } catch (e) {
      print('Error desconocido: $e');
      return '';
    }
  }

  Future<int> traerParametroProximaGeocerca() async {
    final url = Uri.parse(_url + 'Traer_Parametro_ProximaGeocerca'); // URL sin parámetros

    try {
      final response = await http.get(url); // Realizas una solicitud GET

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valor'] ?? 0; // Devuelves el valor obtenido de la respuesta
      } else {
        throw Exception('Error al cargar los parámetros: Código de respuesta ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return 0; // Devuelves 0 en caso de error
    }
  }
}




// Future<void> guardarGeocercasEnDB(List<Geocerca> geocercas) async {
//     for (Geocerca geocerca in geocercas) {
//       await AppDatabase.instance.insertarActualizarGeocerca(geocerca);
//     }
//   }