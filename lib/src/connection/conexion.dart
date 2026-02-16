class Conexion {
  static bool mood = true; //true: produccion false: soluciones
  //https://aplicativos.linea.pe/apiOperativa_beta/api/embarqueTdp/
  //https://aplicativos.linea.pe/apiGETP_BETA/api/embarqueTdp/
  //https://aplicativos.linea.pe/apiOperativa_tdp/api/embarqueTdp/
  static String apiUrl = mood ? 'https://aplicativos.linea.pe/apiOperativa_tdp/api/embarqueTdp/' : 'https://soluciones.linea.pe/aplicativos/apiOperativa_tdp/api/embarqueTdp/'; //https://soluciones.linea.pe/aplicativos/apiOperativa_tdp/api/embarqueTdp/
  static String apiUrlDocsLabs = mood ? 'https://aplicativos.linea.pe/apiOperativa_tdp/api/DocLaborales': 'https://soluciones.linea.pe/aplicativos/apiOperativa_tdp/api/DocLaborales';

  static String urlRecursos = mood ? 'https://aplicativos.linea.pe/assetsAppBus/' : 'https://aplicativos.linea.pe/assetsAppBus/';
}
