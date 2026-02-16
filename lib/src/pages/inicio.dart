import 'package:embarques_tdp/src/pages/home.dart';
import 'package:embarques_tdp/src/pages/perfil/perfilPage.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({Key? key}) : super(key: key);

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int indexActual = 0;
  final paginas = [const HomePage(), const PerfilPage()];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body: paginas[indexActual],
      body: IndexedStack(
        index: indexActual,
        children: paginas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.whiteColor,
        selectedItemColor: AppColors.redColor,
        unselectedItemColor: AppColors.greyColor,
        iconSize: 25,
        unselectedIconTheme: const IconThemeData(size: 23),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        selectedFontSize: 14,
        unselectedFontSize: 13,
        showUnselectedLabels: true,
        currentIndex: indexActual,
        onTap: (index) {
          setState(() {
            indexActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_sharp),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

// class ScaffoldAntiguo extends StatelessWidget {
//   const ScaffoldAntiguo({
//     super.key,
//     required this.usuarioActual,
//     required this.width,
//   });
//
//   final Usuario usuarioActual;
//   final double width;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: const MyDrawer(),
//       appBar: AppBar(
//         title: const Text('Inicio'),
//         backgroundColor: AppColors.mainBlueColor,
//       ),
//       body: Center(
//         child: Column(
//           children: [
//             Spacer(),
//             Padding(
//               padding: EdgeInsets.only(left: 15, right: 15),
//               child: Center(
//                 child: Text("¡Bienvenido " + usuarioActual.nombres + "!",
//                     style: TextStyle(
//                         color: AppColors.mainBlueColor,
//                         fontSize: 25,
//                         fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center),
//               ),
//             ),
//             Center(
//               child: Container(
//                 /*child: Image(
//                   image:
//                       const AssetImage("assets/images/appBus_inicio_3.png"),
//                   //height: height,
//                   width: width * 0.9,
//                   fit: BoxFit.contain,
//                 ),*/

//                 child: Image.network(
//                   Conexion.urlRecursos + "/images/inicioAppBus.png",
//                   width: width * 0.9,
//                   //height: height * 0.5,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//             SizedBox(
//               height: 25,
//             ),
//             /*Container(
//               padding: EdgeInsets.only(left: 25, right: 25),
//               child: Text(
//                 "AppBus",
//                 style: TextStyle(
//                     color: AppColors.mainBlueColor,
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//             ),*/
//             Spacer(),
//             WarningWidgetInternet(),
//           ],
//         ),
//       ),
//     );
//   }
// }
