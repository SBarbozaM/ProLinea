class Conexion {
  static bool mood = true; //true: produccion false: soluciones
  //https://aplicativos.linea.pe/apiOperativa_beta/api/embarqueTdp/
  //https://aplicativos.linea.pe/apiGETP_BETA/api/embarqueTdp/
  //https://aplicativos.linea.pe/apiOperativa_tdp/api/embarqueTdp/
  static String url = mood ? 'https://aplicativos.linea.pe/apiOperativa_tdp/api/' : 'https://soluciones.linea.pe/aplicativos/apiOperativa_tdp/api/';
  static String apiUrl = url + 'embarqueTdp/'; //https://soluciones.linea.pe/aplicativos/apiOperativa_tdp/api/embarqueTdp/
  static String apiUrlDocsLabs = url + 'DocLaborales';
  static String apiUrlDocBacko = url + 'documentosbacko';
  static String apiUrlLogin = url + 'LoginGeus';

  static String urlRecursos = mood ? 'https://aplicativos.linea.pe/assetsAppBus/' : 'https://aplicativos.linea.pe/assetsAppBus/';
}
