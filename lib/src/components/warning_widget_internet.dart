import 'package:embarques_tdp/main.dart';
import 'package:embarques_tdp/src/components/conexionInternet.dart';
import 'package:embarques_tdp/src/providers/connection_status_provider.dart';
import 'package:embarques_tdp/src/utils/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WarningWidgetInternet extends StatelessWidget {
  const WarningWidgetInternet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: ((context) => ConnectionStatusProvider()),
      child: Consumer<ConnectionStatusProvider>(
        builder: (context, value, child) {
          return Visibility(
            //visible: value.status != ConnectionStatus.online,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16),
              height: 40,
              color: null /*value.status != ConnectionStatus.online
                  ? AppColors.whiteColor
                  : AppColors.whiteColor*/
              ,
              child: Row(
                children: [
                  value.status != ConnectionStatus.online
                      ? const Icon(
                          Icons.wifi_off,
                          size: 20,
                          color: AppColors.redColor,
                        )
                      : const Icon(
                          Icons.wifi,
                          size: 20,
                          color: AppColors.mainBlueColor,
                        ),
                  const SizedBox(width: 8),
                  value.status != ConnectionStatus.online ? const Text("") : const Text(""),
                  const SizedBox(width: 2),
                  datosPorSincronizar
                      ? const Text(
                          "Hay datos por enviar",
                          style: TextStyle(color: AppColors.redColor),
                        )
                      : const Text("Sin datos por enviar", style: TextStyle(color: AppColors.mainBlueColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
