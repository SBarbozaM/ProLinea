import 'package:embarques_tdp/src/pages/Incidentes/incidentes_page.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/autorizacion_1.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/autorizaciones_page.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/list_docsAuth_page.dart';
import 'package:embarques_tdp/src/pages/autorizaciones/sub_subAcciones_auth_page.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/main/checklista_main.dart';
import 'package:embarques_tdp/src/pages/checklist_mantenimiento/new/checklist_mantenimiento.dart';
import 'package:embarques_tdp/src/pages/colaborador/colaborador.dart';
import 'package:embarques_tdp/src/pages/control_asistencia/control_asistencia.dart';
import 'package:embarques_tdp/src/pages/control_ingreso/control_ingreso.dart';
import 'package:embarques_tdp/src/pages/control_ingreso/control_ingreso_lista.dart';
import 'package:embarques_tdp/src/pages/control_salida/control_salida_lista.dart';
import 'package:embarques_tdp/src/pages/control_vehicular/control_vehicular.dart';
import 'package:embarques_tdp/src/pages/documentos/documentosPage.dart';
import 'package:embarques_tdp/src/pages/documentos_laborales/documento.dart';
import 'package:embarques_tdp/src/pages/documentos_laborales/documentosDetalle.dart';
import 'package:embarques_tdp/src/pages/documentos_laborales/documentos_laborales.dart';
import 'package:embarques_tdp/src/pages/embarque_sup_mult/embarque_multiple_supervisor.dart';
import 'package:embarques_tdp/src/pages/embarques_sup/embarques_sup.dart';
import 'package:embarques_tdp/src/pages/embarques_sup/embarques_sup_scaner.dart';
import 'package:embarques_tdp/src/pages/finalizar_viaje/finalizar_viaje.dart';
import 'package:embarques_tdp/src/pages/inicio.dart';
import 'package:embarques_tdp/src/pages/jornada/jornada_page.dart';
import 'package:embarques_tdp/src/pages/orden_servicio/scan_unidad_orden_servicio_mantenimiento.dart';
import 'package:embarques_tdp/src/pages/orden_servicio/scan_unidad_orden_servicio_jefatura.dart';
import 'package:embarques_tdp/src/pages/perfil/perfilPage.dart';
import 'package:embarques_tdp/src/pages/programacion/programacion_page.dart';
import 'package:embarques_tdp/src/pages/rutas/rutas_page.dart';
import 'package:embarques_tdp/src/pages/splash/splash_page.dart';
import 'package:embarques_tdp/src/pages/control_salida/control_salida.dart';
import 'package:embarques_tdp/src/pages/vehiculo-geop/vehiculo-geop.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_bolsa.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_domicilio.dart';
import 'package:embarques_tdp/src/pages/vinculacion_jornada/vinculacion_jornadaPage.dart';
import 'package:embarques_tdp/src/pages/manifiesto/manifiesto_lista_viajes.dart';
import 'package:embarques_tdp/src/pages/login.dart';
import 'package:embarques_tdp/src/pages/manifiesto/manifiesto_viaje.dart';
import 'package:embarques_tdp/src/pages/emparejar/emparejar_qr.dart';
import 'package:embarques_tdp/src/pages/viaje_bolsa/viaje_bolsa_imprimir.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_navigation.dart';
import 'package:embarques_tdp/src/pages/viaje_domicilio/viaje_domicilio_recojo.dart';
import 'package:flutter/material.dart';

import '../pages/configuracion/config_impresora.dart';
import '../pages/configuracion/configuracion.dart';
import '../pages/manifiesto/manifiesto_imprimir.dart';
import '../pages/viaje_bolsa/viaje_bolsa_navigation.dart';
import '../pages/viaje_domicilio/viaje_domicilio_navigation_recojo.dart';
import '../pages/viaje_domicilio/viaje_domicilio_navigation_reparto.dart';
import '../pages/viaje_domicilio/viaje_domicilio_reparto.dart';
import '../pages/autorizaciones/prueba.dart';

Map<String, WidgetBuilder> obtenerRutas() {
  return <String, WidgetBuilder>{
    '/': (BuildContext context) => const SplashPage(),
    'login': (BuildContext context) => const LoginPage(),
    'inicio': (BuildContext context) => const InicioPage(),
    'listaViajes': (BuildContext context) => const ListaViajesPage(),
    'manifiestoViaje': (BuildContext context) => const ManifiestoViajePage(),
    // 'manifiestoImprimir': (BuildContext context) => const ManifiestoImprimirPage(),
    'navigationBolsaViaje': (BuildContext context) => const ViajeBolsaNavigationBar(),
    'navigationDomicilioViaje': (BuildContext context) => const ViajeDomicilioNavigationBar(),
    'navigationDomicilioRecojo': (BuildContext context) => const ViajeDomicilioNavigationRecojo(),
    'navigationDomicilioReparto': (BuildContext context) => const ViajeDomicilioNavigationReparto(),
    'recojo': (BuildContext context) => const ViajeDomicilioRecojoPage(),
    'reparto': (BuildContext context) => const ViajeDomicilioRepartoPage(),
    // 'imprimirPage': (BuildContext context) => const ViajeBolsaImprimirPage(),
    'emparejarQR': (BuildContext context) => const EmparejarQrPage(),
    'documentosPage': (BuildContext context) => const DocumentosPage(),
    'finalizarViajePage': (BuildContext context) => const FinalizarViaje(),
    'embarquesSupervisor': (BuildContext context) => const EmbarquesSupervisor(),
    'embarquesSupervisorScaner': (BuildContext context) => const EmbarquesSupervisorScaner(),
    'embarqueMultipleSupervisor': (BuildContext context) => const EmbarquesMultiplePage_Supervisor(),
    'configuracion': (BuildContext context) => const ConfiguracionPage(),
    // 'configImpresora': (BuildContext context) => const ConfigImpresoraPage(),
    'vinculacionJornada': (BuildContext context) => const VinculacionJornadaPage(),
    'vinculacionDomicilio': (BuildContext context) => const VinculacionDomicilio(),
    'vinculacionBolsa': (BuildContext context) => const VinculacionBolsa(),
    'jornada': (BuildContext context) => const JornadaPage(),
    'controlSalida': (BuildContext context) => const ControlSalidaPage(),
    'controlSalidaLista': (BuildContext context) => const ControlSalidaLista(),
    'controlAsistencia': (BuildContext context) => const ControlAsistenciaPage(),
    'controlIngreso': (BuildContext context) => const ControlIngresoPage(),
    'controlIngresoLista': (BuildContext context) => const ControlIngresoLista(),
    'controlVehicular': (BuildContext context) => const ControlVehicularPage(),
    'colaboradorPage': (BuildContext context) => const ColaboradorPage(),
    'padronVehicularGeop': (BuildContext context) => const VehiculoGeopPage(),
    'checklistMain': (BuildContext context) => const CheckListMainPage(),
    // 'checklistMantenimiento': (BuildContext context) => const ChecklistMantenimientoPage(),
    'ordenServicioTaller': (BuildContext context) => const ScanUnidadOrdenMantenimientoPage(),
    'ordenServicioTalleres': (BuildContext context) => const ScanUnidadOrdenServicioJefaturaPage(),
    'listarProgramacion': (BuildContext context) => const ProgramacionPage(),
    'darAutorizaciones': (BuildContext context) => const AutorizacionesPage(), //  NotificationPage(),
    'verDocLaborales': (BuildContext context) => const DocumentosLaboralesPage(), //  NotificationPage(),
    'listarSubAutorizaciones': (BuildContext context) => const SubAutorizacionesPage(),
    'irListaDocsAuth': (BuildContext context) => const ListDocsPage(),
    'irToggle': (BuildContext context) => const TriStateToggleSwitch(),
    'irVerIncidentes': (BuildContext context) => IncidentesPage(),
    'irVerRutas': (BuildContext context) => const RutaListPage(),
    'documentosDetalle': (_) => const DocumentosDetallePage(),
    'documento-viewer': (_) => const DocumentoViewerPage(),
    // 'irCopiloto': (BuildContext context) => MapaPage(), //SpeedTracker  GeocercaListPage(),
    // 'irListaGeocerecas': (BuildContext context) => GeocercaListPage(), //SpeedTracker  GeocercaListPage(),
    // 'irCopiAndriod': (BuildContext context) => SpeedTrackingPage(), //SpeedTracker  GeocercaListPage(),

    //'registrarDocumentos': (BuildContext context) => DocumentosRegistrados(),
    //'auth1': (BuildContext context) => const Autorizacion1(),
    /*'prueba': (BuildContext context) => const PruebaPage(),*/
  };
}
