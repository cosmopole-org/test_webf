/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:webf/rendering.dart';
import 'package:webf/webf.dart';
import 'package:webf/devtools.dart';
import 'package:flutter/cupertino.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the controller manager
  WebFControllerManager.instance.initialize(
    WebFControllerManagerConfig(
      maxAliveInstances: 4,
      maxAttachedInstances: 1,
      onControllerDisposed: (String name, WebFController controller) {
        print('controller disposed: $name $controller');
      },
      onControllerDetached: (String name, WebFController controller) {
        print('controller detached: $name $controller');
      },
    ),
  );

  WebFControllerManager.instance.addWithPreload(
    name: 'home',
    createController: () => WebFController(
      routeObserver: routeObserver,
      initialRoute: '/',
      onLCP: (time, isEvaluated) {
        print('LCP time: $time, evaluated: $isEvaluated');
      },
      onLCPContentVerification: (contentInfo, routePath) {
        print('contentInfo: $contentInfo');
      },
      httpLoggerOptions: HttpLoggerOptions(
        requestHeader: true,
        requestBody: true,
      ),
      onControllerInit: (controller) async {
        controller.loadingState.onFinalLargestContentfulPaint((event) {
          final dump = controller.dumpLoadingState(
            options:
                LoadingStateDumpOptions.html |
                LoadingStateDumpOptions.api |
                LoadingStateDumpOptions.scripts |
                LoadingStateDumpOptions.networkDetailed,
          );
          debugPrint(dump.toStringFiltered());
        });
      },
    ),
    bundle: WebFBundle.fromUrl('https://miracleplus.openwebf.com/'),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  WebFController? controller;

  @override
  void initState() {
    super.initState();
    WebFControllerManager.instance.getController("home").then((cont) {
      setState(() {
        controller = cont;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return WebFHTMLElement(
        tagName: "h1",
        controller: controller!,
        parentElement: null,
        children: [Text("hello world !")],
      );
    } else {
      return Container();
    }
  }
}
