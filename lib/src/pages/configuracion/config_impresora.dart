// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:embarques_tdp/src/providers/impresoraProvider.dart';
// import 'package:embarques_tdp/src/providers/providers.dart';
// import 'package:embarques_tdp/src/utils/app_colors.dart';
// import 'package:embarques_tdp/src/utils/app_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

// class ConfigImpresoraPage extends StatefulWidget {
//   const ConfigImpresoraPage({Key? key}) : super(key: key);
//   @override
//   _ConfigImpresoraPageState createState() => _ConfigImpresoraPageState();
// }

// class _ConfigImpresoraPageState extends State<ConfigImpresoraPage> {
//   BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
//   List<BluetoothDevice> _devices = [];
//   BluetoothDevice? _device;
//   bool _connected = false;

//   @override
//   void initState() {
//     super.initState();
//     initPlatformState();
//     ingreso("INGRESO A CONFIGURAR IMPRESORA");
//   }

//   ingreso(String Mensaje) async {
//     var usuarioLogin =
//         Provider.of<UsuarioProvider>(context, listen: false).usuario;
//     await AppDatabase.instance.NuevoRegistroBitacora(
//       context,
//       "${usuarioLogin.tipoDoc}-${usuarioLogin.numDoc}",
//       "${usuarioLogin.codOperacion}",
//       DateFormat('dd/MM/yyyy hh:mm:ss').format(DateTime.now()),
//       "Embarque ${usuarioLogin.perfil}: ${Mensaje}",
//       "Exitoso",
//     );
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
//           ingreso("estado del dispositivo bluetooth: conectado");

//           break;
//         case BlueThermalPrinter.DISCONNECTED:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: disconnected");
//           });

//           ingreso("estado del dispositivo bluetooth: desconectado");
//           break;
//         case BlueThermalPrinter.DISCONNECT_REQUESTED:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: disconnect requested");
//           });
//           ingreso("estado del dispositivo bluetooth: desconexión solicitada");

//           break;
//         case BlueThermalPrinter.STATE_TURNING_OFF:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth turning off");
//           });
//           ingreso("estado del dispositivo bluetooth: bluetooth apagado");

//           break;
//         case BlueThermalPrinter.STATE_OFF:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth off");
//           });

//           ingreso("estado del dispositivo bluetooth: bluetooth apagado");

//           break;
//         case BlueThermalPrinter.STATE_ON:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth on");
//           });

//           ingreso("estado del dispositivo bluetooth: bluetooth activado");

//           break;
//         case BlueThermalPrinter.STATE_TURNING_ON:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: bluetooth turning on");
//           });

//           ingreso("estado del dispositivo bluetooth: bluetooth encendido");
//           break;
//         case BlueThermalPrinter.ERROR:
//           setState(() {
//             _connected = false;
//             print("bluetooth device state: error");
//           });
//           ingreso("estado del dispositivo bluetooth: error");

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
//     BluetoothDevice? impresoraActual =
//         Provider.of<ImpresoraProvider>(context, listen: false)
//             .impresoraVinculada;

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             icon: Icon(
//               Icons.arrow_back_ios,
//               color: AppColors.blackColor,
//             )),
//         elevation: 0,
//         backgroundColor: AppColors.whiteColor,
//         title: Text(
//           'Configuración de la Impresora',
//           style: TextStyle(
//             fontSize: 17.5,
//             fontWeight: FontWeight.bold,
//             color: AppColors.blackColor,
//           ),
//         ),
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
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: <Widget>[
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.greenColor),
//                   onPressed: () {
//                     initPlatformState();
//                     ingreso("Actualizar lista impresoras");
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
//             const SizedBox(
//               height: 10,
//             ),
//             Row(
//               children: [
//                 Text(
//                     "Impresora actual: " + (impresoraActual?.name ?? "Ninguna"))
//               ],
//             )
//           ],
//         ),
//       ),
//     );
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

//   _connect() {
//     if (_device != null) {
//       bluetooth.isConnected.then((isConnected) {
//         if (isConnected == false) {
//           bluetooth.connect(_device!).catchError((error) {
//             setState(() => _connected = false);
//           });
//           setState(() => _connected = true);
//         }
//       });
//       Provider.of<ImpresoraProvider>(context, listen: false)
//           .actualizarImpresora(_device);
//       ingreso("impresora conectada");
//       setState(() {});
//     } else {
//       show('No se ha seleccionado un dispositivo.');
//     }
//   }

//   void _disconnect() async {
//     bluetooth.disconnect();
//     Provider.of<ImpresoraProvider>(context, listen: false)
//         .actualizarImpresora(null);
//     _connected = false;
//     ingreso("impresora desconectada");
//     setState(() {});
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
// }
