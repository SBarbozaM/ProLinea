// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:embarques_tdp/src/providers/providers.dart';
// import 'package:embarques_tdp/src/utils/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:diacritic/diacritic.dart';
// import '../../models/pasajero.dart';
// import '../../models/viaje.dart';

// class ViajeBolsaImprimirPage extends StatefulWidget {
//   const ViajeBolsaImprimirPage({Key? key}) : super(key: key);
//   @override
//   _ViajeBolsaImprimirPageState createState() => _ViajeBolsaImprimirPageState();
// }

// class _ViajeBolsaImprimirPageState extends State<ViajeBolsaImprimirPage> {
//   BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
//   List<BluetoothDevice> _devices = [];
//   BluetoothDevice? _device;
//   bool _connected = false;
//   Viaje _viaje = new Viaje();

//   @override
//   void initState() {
//     super.initState();
//     _viaje = Provider.of<ViajeProvider>(context, listen: false).viaje;
//     initPlatformState();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   Future<void> initPlatformState() async {
//     bool? isConnected = await bluetooth.isConnected;
//     List<BluetoothDevice> devices = [];
//     try {
//       devices = await bluetooth.getBondedDevices();
//     } on PlatformException {}

//     bluetooth.onStateChanged().listen((state) {
//       switch (state) {
//         case BlueThermalPrinter.CONNECTED:
//           setState(() {
//             _connected = true;
//             print("bluetooth device state: connected");
//           });
//           break;
//         case BlueThermalPrinter.DISCONNECTED:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: disconnected");
//           });
//           break;
//         case BlueThermalPrinter.DISCONNECT_REQUESTED:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: disconnect requested");
//           });
//           break;
//         case BlueThermalPrinter.STATE_TURNING_OFF:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth turning off");
//           });
//           break;
//         case BlueThermalPrinter.STATE_OFF:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth off");
//           });
//           break;
//         case BlueThermalPrinter.STATE_ON:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth on");
//           });
//           break;
//         case BlueThermalPrinter.STATE_TURNING_ON:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth turning on");
//           });
//           break;
//         case BlueThermalPrinter.ERROR:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: error");
//           });
//           break;
//         default:
//           break;
//       }
//     });

//     if (!mounted) return;
//     setState(() {
//       _devices = devices;
//     });

//     if (isConnected != null) {
//       if (isConnected) {
//         setState(() {
//           _connected = true;
//         });
//       }
//     }

//     {
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     Intl.defaultLocale = 'es';
//     initializeDateFormatting();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Imprimir Manifiesto"),
//         backgroundColor: AppColors.mainBlueColor,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: ListView(
//           children: [
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 const SizedBox(
//                   width: 10,
//                 ),
//                 const Text(
//                   'Dispositivo: ',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(
//                   width: 30,
//                 ),
//                 Expanded(
//                   child: DropdownButton(
//                     hint: _devices.isEmpty
//                         ? Text("No hay dispositivos")
//                         : Text("Ninguno"),
//                     items: _getDeviceItems(),
//                     isExpanded: true,
//                     onChanged: (BluetoothDevice? value) =>
//                         setState(() => _device = value),
//                     value: _device,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: <Widget>[
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.greenColor),
//                   onPressed: () {
//                     initPlatformState();
//                   },
//                   child: const Text(
//                     'Actualizar',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 const SizedBox(width: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: _connected
//                           ? AppColors.redColor
//                           : AppColors.mainBlueColor),
//                   onPressed: _connected ? _disconnect : _connect,
//                   child: Text(
//                     _connected ? 'Desconectar' : 'Conectar',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//             Padding(
//               padding: const EdgeInsets.only(left: 15, right: 15, top: 25),
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.mainBlueColor),
//                 onPressed: () async {
//                   String nombreLugarEmbarque = "";

//                   String fechaHoraActual =
//                       DateFormat.yMd().add_Hms().format(new DateTime.now());
//                   String idPuntoEmbarque =
//                       Provider.of<ViajeProvider>(context, listen: false)
//                           .idPuntoEmbarque;
//                   Provider.of<PasajeroProvider>(context, listen: false)
//                       .agregarPasajeros(_viaje.pasajeros);
//                   List<Pasajero> pasajeros =
//                       Provider.of<PasajeroProvider>(context, listen: false)
//                           .pasajeros;
//                   pasajeros.sort((a, b) => a.nombres.compareTo(b.nombres));

//                   if (idPuntoEmbarque != '-1') {
//                     for (int i = 0; i < _viaje.puntosEmbarque.length; i++) {
//                       if (_viaje.puntosEmbarque[i].id == idPuntoEmbarque) {
//                         nombreLugarEmbarque = _viaje.puntosEmbarque[i].nombre;
//                         break;
//                       }
//                     }
//                   }

//                   /// DATOS DE LINEA ///
//                   bluetooth.printCustom(
//                       removeDiacritics("MANIFIESTO DE PASAJEROS"), 2, 1);
//                   bluetooth.printNewLine();
//                   bluetooth.printCustom(
//                       "RUC: " + removeDiacritics((_viaje.ruc ?? "")), 0, 0);
//                   bluetooth.printCustom(
//                       "Razon Social: " +
//                           removeDiacritics((_viaje.razonSocial ?? "")),
//                       0,
//                       0);
//                   bluetooth.printCustom(
//                     "Direccion: " +
//                         removeDiacritics(
//                             (_viaje.direccion?.toUpperCase() ?? "")),
//                     0,
//                     0,
//                   );
//                   bluetooth.printCustom(
//                       "Telefono: " + (_viaje.telefono ?? ""), 0, 0);
//                   //bluetooth.printNewLine();

//                   /// INFORMACION DEL VIAJE ///

//                   //bluetooth.printCustom("INFORMACION DEL VIAJE", 1, 1);
//                   bluetooth.printNewLine();
//                   bluetooth.printCustom(
//                       "Ruta: " +
//                           removeDiacritics(_viaje.origen) +
//                           " - " +
//                           removeDiacritics(_viaje.destino),
//                       1,
//                       0);
//                   if (nombreLugarEmbarque != "") {
//                     bluetooth.printCustom(
//                         "Embarque en: " + removeDiacritics(nombreLugarEmbarque),
//                         1,
//                         0);
//                   }
//                   bluetooth.printCustom(
//                       "Fecha: " +
//                           _viaje.fechaSalida +
//                           " "
//                               "Hora: " +
//                           _viaje.horaSalida,
//                       1,
//                       0);
//                   /*bluetooth.printLeftRight("Fecha: " + _viaje.fechaSalida,
//                       "Hora: " + _viaje.horaSalida, 0);*/

//                   bluetooth.printCustom("Unidad/Placa: " + _viaje.unidad, 1, 0);

//                   bluetooth.printNewLine();

//                   for (int i = 0; i < _viaje.tripulantes.length; i++) {
//                     bluetooth.printCustom(
//                         _viaje.tripulantes[i].tipo +
//                             " " +
//                             _viaje.tripulantes[i].orden +
//                             ": " +
//                             removeDiacritics(_viaje.tripulantes[i].tipoDoc +
//                                 " " +
//                                 _viaje.tripulantes[i].numDoc +
//                                 " " +
//                                 _viaje.tripulantes[i].nombres),
//                         1,
//                         0);
//                   }
//                   bluetooth.printNewLine();

//                   /// PASAJEROS ///
//                   bluetooth.printCustom(
//                       "------------------------------------------------------------------------------------------",
//                       0,
//                       0);
//                   bluetooth.printCustom("PASAJEROS", 2, 1);
//                   bluetooth.printNewLine();
//                   bluetooth.printCustom(
//                       "Pasajero" + "  /  " + "Desembarque", 1, 0);
//                   bluetooth.printNewLine();
//                   for (int i = 0; i < pasajeros.length; i++) {
//                     if (idPuntoEmbarque == '-1')
//                       _imprimirDatosPasajero(pasajeros[i], (i + 1));
//                     else if (idPuntoEmbarque == pasajeros[i].idEmbarque)
//                       _imprimirDatosPasajero(pasajeros[i], (i + 1));
//                   }

//                   bluetooth.printNewLine();
//                   bluetooth.printNewLine();

//                   bluetooth.printCustom(
//                       "-------------------------        --------------------------",
//                       1,
//                       1);
//                   bluetooth.printCustom(
//                       "Firma Conductor                   Firma Supervisor",
//                       1,
//                       1);

//                   bluetooth.printNewLine();

//                   bluetooth.printCustom(
//                       "Fecha de impresion: " + fechaHoraActual, 1, 1);
//                   bluetooth.paperCut();
//                 },
//                 child: const Text('IMPRIMIR',
//                     style: TextStyle(color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   _imprimirDatosPasajero(Pasajero pasajero, int orden) {
//     bluetooth.printCustom(
//         orden.toString() +
//             ". " +
//             pasajero.tipoDoc +
//             " " +
//             pasajero.numDoc +
//             " " +
//             removeDiacritics(pasajero.nombres) +
//             "  /  " +
//             removeDiacritics(pasajero.lugarDesembarque),
//         1,
//         0);

//     bluetooth.printNewLine();
//   }

//   List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
//     List<DropdownMenuItem<BluetoothDevice>> items = [];
//     if (_devices.isEmpty) {
//       items.add(DropdownMenuItem(
//         child: Text('Ninguno'),
//       ));
//     } else {
//       _devices.forEach((device) {
//         items.add(DropdownMenuItem(
//           child: Text(device.name ?? ""),
//           value: device,
//         ));
//       });
//     }
//     return items;
//   }

//   void _connect() {
//     if (_device != null) {
//       bluetooth.isConnected.then((isConnected) {
//         if (isConnected == false) {
//           bluetooth.connect(_device!).catchError((error) {
//             setState(() => _connected = false);
//           });
//           setState(() => _connected = true);
//         }
//       });
//     } else {
//       show('No device selected.');
//     }
//   }

//   void _disconnect() {
//     bluetooth.disconnect();
//     setState(() => _connected = false);
//   }

//   Future show(
//     String message, {
//     Duration duration = const Duration(seconds: 3),
//   }) async {
//     await new Future.delayed(new Duration(milliseconds: 100));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(color: Colors.white),
//         ),
//         duration: duration,
//       ),
//     );
//   }

// /***************** ESC_POS_BLUETOOTH *****************/
// /*
//   PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
//   List<PrinterBluetooth> _devices = [];
//   String _devicesMsg = "";

//   @override
//   void initState() {
//     initPrinter();
//     super.initState();
//   }

//   void initPrinter() {
//     _printerManager.startScan(Duration(seconds: 2));
//     _printerManager.scanResults.listen((val) {
//       if (!mounted) return;

//       setState(() {
//         _devices = val;
//       });

//       if (_devices.isEmpty)
//         setState(() {
//           _devicesMsg = "No hay impresoras disponibles";
//         });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('PRINT'),
//       ),
//       body: _devices.isEmpty
//           ? Center(
//               child: Text(_devicesMsg),
//             )
//           : ListView.builder(
//               itemCount: _devices.length,
//               itemBuilder: (c, i) {
//                 return ListTile(
//                   leading: Icon(Icons.print),
//                   title: Text(_devices[i].name ?? ''),
//                   subtitle: Text(_devices[i].address ?? ''),
//                   onTap: () {
//                     _startPrint(_devices[i]);
//                   },
//                 );
//               }),
//     );
//   }

//   Future<void> _startPrint(PrinterBluetooth printer) async {
//     _printerManager.selectPrinter(printer);
//     final result =
//         await _printerManager.printTicket(await _ticket(PaperSize.mm80));
//   }

//   Future<List<int>> _ticket(PaperSize paper) async {
//     final profile = await CapabilityProfile.load();
//     final generator = Generator(paper, profile);
//     List<int> bytes = [];

//     bytes += generator.text(
//         'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');
//     bytes += generator.feed(2);
//     bytes += generator.cut();
//     return bytes;
//   }*/
// }
