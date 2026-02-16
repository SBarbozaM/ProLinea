import 'package:embarques_tdp/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewBasicaPage extends StatefulWidget {
  final String url;
  final String titulo;
  final String back;

  const WebViewBasicaPage({Key? key, required this.url, required this.titulo, required this.back}) : super(key: key);

  @override
  State<WebViewBasicaPage> createState() => _PadronVehiculosPageState();
}

class _PadronVehiculosPageState extends State<WebViewBasicaPage> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        centerTitle: true,
        backgroundColor: AppColors.mainBlueColor,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(widget.back, (Route<dynamic> route) => false);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.only(right: 7),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.whiteColor,
              child: IconButton(
                color: AppColors.mainBlueColor,
                onPressed: () {
                  _webViewController.reload();
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          onWebViewCreated: (InAppWebViewController controller) {
            _webViewController = controller;
          },
          onLoadStart: (controller, url) {
            setState(() {
              //print('Page started loading: $url');
            });
          },
          onLoadStop: (controller, url) {
            setState(() {
              //print('Page finished loading: $url');
            });
          },
        ),
      ),
    );
  }
}
