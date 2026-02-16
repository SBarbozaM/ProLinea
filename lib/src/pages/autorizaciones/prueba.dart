// import 'package:flutter/material.dart';
// import '../../services/onesignal_service.dart';



class OneSignalService { 
  init() async {
    
  }

}
// class NotificationPage extends StatefulWidget {
//   @override
//   _NotificationPageState createState() => _NotificationPageState();
// }

// class _NotificationPageState extends State<NotificationPage> {
//   final String playerId = "04a00b46-16a7-4abb-a7e7-0b157ea1fd09"; // Reemplaza con el Player ID real
//   final String title = "Hola";
//   final String message = "Holiunfuu";

//   @override
//   void initState() {
//     super.initState();
//     _sendNotification();
//   }

//   Future<void> _sendNotification() async {
//     await sendNotification(playerId, title, message);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Autorizaciones'),
//         //  backgroundColor: AppColors.mainBlueColor,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.of(context).pushNamedAndRemoveUntil('inicio', (Route<dynamic> route) => false);
//           },
//           icon: const Icon(Icons.arrow_back_ios_new_rounded),
//         ),
//       ),
//       body: Center(
//         child: Text('La notificación ha sido enviada.'),
//       ),
//     );
//   }
// }
