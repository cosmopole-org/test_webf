import 'package:flutter/material.dart';
import 'package:webf/webf.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WebFControllerManager.instance.initialize(
    WebFControllerManagerConfig(
      maxAliveInstances: 5,
      maxAttachedInstances: 3,
      onControllerDisposed: (String name, WebFController controller) {
        print('controller disposed: $name $controller');
      },
      onControllerDetached: (String name, WebFController controller) {
        print('controller detached: $name $controller');
      },
    ),
  );

  WebFControllerManager.instance.addWithPrerendering(
    name: 'home',
    createController: () => WebFController(),
    bundle: WebFBundle.fromContent(
      "<!DOCTYPE html><head></head><body><h1>test</h1></body></html>",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Webf Test",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: Text("Webf Test")),
        body: WebF.fromControllerName(
          controllerName: 'home',
          loadingWidget: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
