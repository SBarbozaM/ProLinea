// import '../pages/autorizaciones/list_docsAuth_page.dart';
// import 'package:flutter/cupertino.dart';

// class Pages {
//   List<dynamic> listOfPages = [
//     {
//       "type": "lis_docs",
//       "page": ListDocsPage(),
//     },
    
//   ];

//   setToPage({String type, BuildContext context}) {
//     var _page =
//         listOfPages.where((element) => element["type"] == type).toList();

//     if (_page.isNotEmpty) {
//       AnimationRoutes.animationRoute(
//           context: context, widget: _page.first["page"]);
//     }
//   }

//   setToAction({
//     String type = '',
//     BuildContext context  ,
//     String url = '',
//     dynamic data,
//   }) async {
//     var isLogin = await Cookies.getSession();
//     DataProviderRoutes _dataroutes = DataProviderRoutes();
//     var user = isLogin
//         ? (await Cookies.getUser()).usuarioAutenticar
//         : UserModel().usuarioAutenticar;

//     if (type == "buy_travel") {
//       GlobalKey<State> _keyLoader = new GlobalKey<State>();
//       Dialogs.showLoadingDialog(
//         context: context,
//         key: _keyLoader,
//         title: 'Espere por favor',
//       );
//       var travelBloc = TravelBloc();
//       DateTime go = DateTime.parse(data["go"]);
//       DateTime lap = DateTime.parse(data["lap"]);
//       var rpt = await travelBloc.getTravelEvery(
//         destiny: data["destiny"],
//         origin: data["origin"],
//         go: go,
//         lap: lap,
//         isPoints: 0,
//         data: null,
//       );
//       if (rpt["success"] == null || !rpt["success"]) {
//         ModalLinea.showDialogMessage(message: rpt["message"], context: context);
//         return;
//       }
//       var _url = rpt["data"]["url"];
//       var id = rpt["data"]["id"];
//       Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
//       Functions.goToBuyTravel(
//         context: context,
//         id: id,
//         url: _url,
//         subTitle: "PROMOCIÓN",
//       );
//     }

//     if (type == 'view_my_travel') {
//       await AnimationRoutes.animationRoute(
//         context: context,
//         widget: TravelInformationPage(
//           serie: data['Serie'],
//           numero: data['Numero'],
//           transaction: 0,
//           type: 0,
//           // ruta: e['Ruta'],
//           goToMyTravels: true,
//         ),
//       );
//     }

//     if (type == 'web_view') {
//       await AnimationRoutes.animationRoute(
//         context: context,
//         widget: CustomWebview(
//           idforOTher: true,
//           url: url,
//           title: '',
//         ),
//       );
//     }

//     if (type == 'view_ubication_bus') {
//       await AnimationRoutes.animationRoute(
//         context: context,
//         widget: IndividualTrackBusPage(
//           origin: data['origen'],
//           destiny: data['destino'],
//           bus: data['bus'],
//         ),
//       );
//     }
//     if (type == 'resume_point_linea') {
//       url = _dataroutes.urlCompraDev +
//           "historial_puntos.aspx?" +
//           _dataroutes.webUrlApp +
//           "&tipo_doc=${user.tipoDoc}&num_doc=${user.numDoc}";
//       await AnimationRoutes.animationRoute(
//         context: context,
//         widget: CustomWebview(
//           idforOTher: true,
//           url: url,
//           title: 'Movimiento de Puntos',
//         ),
//       );
//     }
//   }

//   setToTab() {}
// }
