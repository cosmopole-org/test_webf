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
    name: 'miracle_plus',
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

  // // Add vue controller with preloading
  // WebFControllerManager.instance.addWithPrerendering(
  //     name: 'miracle_plus',
  //     createController: () => WebFController(
  //           initialRoute: '/home',
  //           routeObserver: routeObserver,
  //         ),
  //     bundle: WebFBundle.fromUrl('https://miracleplus.openwebf.com/'),
  //     setup: (controller) {
  //       controller.hybridHistory.delegate = CustomHybridHistoryDelegate();
  //       controller.darkModeOverride = savedThemeMode?.isDark;
  //     });
  //
  // // Add vue controller with preloading
  // WebFControllerManager.instance.addWithPrerendering(
  //     name: 'cupertino_gallery',
  //     createController: () => WebFController(
  //       initialRoute: '/',
  //       routeObserver: routeObserver,
  //     ),
  //     bundle: WebFBundle.fromUrl('https://vue-cupertino-gallery.openwebf.com/'),
  //     setup: (controller) {
  //       controller.hybridHistory.delegate = CustomHybridHistoryDelegate();
  //       controller.darkModeOverride = savedThemeMode?.isDark;
  //     });
  //
  // // Add react use cases controller with preloading for image preload test
  // WebFControllerManager.instance.addWithPreload(
  //     name: 'react_use_cases',
  //     createController: () => WebFController(
  //           routeObserver: routeObserver,
  //           // devToolsService: kDebugMode ? ChromeDevToolsService() : null,
  //         ),
  //     bundle: WebFBundle.fromUrl('http://localhost:3000/'),
  //     setup: (controller) {
  //       controller.hybridHistory.delegate = CustomHybridHistoryDelegate();
  //       controller.darkModeOverride = savedThemeMode?.isDark;
  //
  //       // Set up method call handler for FlutterInteractionPage using dedicated handler
  //       controller.javascriptChannel.onMethodCall = FlutterInteractionHandler().handleMethodCall;
  //     });

  runApp(MyApp());
}

class WebFSubView extends StatefulWidget {
  const WebFSubView({super.key, required this.path, required this.controller});

  final WebFController controller;
  final String path;

  @override
  State<StatefulWidget> createState() {
    return WebFSubViewState();
  }
}

class WebFSubViewState extends State<WebFSubView> {
  @override
  Widget build(BuildContext context) {
    WebFController controller = widget.controller;
    RouterLinkElement? routerLinkElement = controller.view.getHybridRouterView(
      widget.path,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(routerLinkElement?.getAttribute('title') ?? ''),
        actions: [],
      ),
      body: Stack(
        children: [
          WebFRouterView(controller: controller, path: widget.path),
          WebFInspectorFloatingPanel(),
        ],
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to first screen when tapped.
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  final ValueNotifier<String> webfPageName = ValueNotifier('');

  @override
  void initState() {
    super.initState();
  }

  Route<dynamic>? handleOnGenerateRoute(RouteSettings settings) {
    return CupertinoPageRoute(
      settings: settings,
      builder: (context) {
        return WebFRouterView.fromControllerName(
          controllerName: webfPageName.value,
          path: settings.name!,
          builder: (context, controller) {
            return WebFSubView(controller: controller, path: settings.name!);
          },
          loadingWidget: _WebFDemoState.buildSplashScreen(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebF Example App',
      initialRoute: '/',
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      themeMode: ThemeMode.system,
      onGenerateInitialRoutes: (initialRoute) {
        return [
          CupertinoPageRoute(
            builder: (context) {
              return ValueListenableBuilder(
                valueListenable: webfPageName,
                builder: (context, value, child) {
                  return FirstPage(
                    title: 'Landing Bay',
                    webfPageName: webfPageName,
                  );
                },
              );
            },
          ),
        ];
      },
      onGenerateRoute: handleOnGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class FirstPage extends StatefulWidget {
  const FirstPage({super.key, required this.title, required this.webfPageName});
  final String title;
  final ValueNotifier<String> webfPageName;

  @override
  State<StatefulWidget> createState() {
    return FirstPageState();
  }
}

class FirstPageState extends State<FirstPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          ListView(
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'html/css';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'html/css',
                          initialRoute: '/',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open HTML/CSS/JavaScript demo'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'esm_demo';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'esm_demo',
                          initialRoute: '/',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open ES Module Demo'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'import_meta_demo';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'import_meta_demo',
                          initialRoute: '/',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open ES Module Import Meta Demo'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'vuejs';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(webfPageName: 'vuejs');
                      },
                    ),
                  );
                },
                child: Text('Open Vue.js demo'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'vuejs';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'vuejs',
                          initialRoute: '/positioned_layout',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open Vue.js demo Positioned Layout'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'reactjs';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(webfPageName: 'reactjs');
                      },
                    ),
                  );
                },
                child: Text('Open React.js demo'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'reactjs';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'reactjs',
                          initialRoute: '/array-buffer-demo',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open ArrayBuffer Demo'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'tailwind_react';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'tailwind_react',
                          initialRoute: '/',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open React.js with TailwindCSS 3'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'miracle_plus';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'miracle_plus',
                          initialRoute: '/',
                          initialState: {'name': 1},
                        );
                      },
                    ),
                  );
                },
                child: Text('Open MiraclePlus App'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'miracle_plus';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'miracle_plus',
                          initialRoute: '/login',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open MiraclePlus App Login'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'hybrid_router';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(webfPageName: 'hybrid_router');
                      },
                    ),
                  );
                },
                child: Text('Open Hybrid Router Example'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'cupertino_gallery';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(webfPageName: 'cupertino_gallery');
                      },
                    ),
                  );
                },
                child: Text('Open Cupertino Gallery'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'cupertino_gallery';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(
                          webfPageName: 'cupertino_gallery',
                          initialRoute: '/button',
                        );
                      },
                    ),
                  );
                },
                child: Text('Open Cupertino Gallery / Button'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'use_cases';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(webfPageName: 'use_cases');
                      },
                    ),
                  );
                },
                child: Text('Open Use Cases (Vue.js)'),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  widget.webfPageName.value = 'react_use_cases';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return WebFDemo(webfPageName: 'react_use_cases');
                      },
                    ),
                  );
                },
                child: Text('Open Use Cases (React.js)'),
              ),
            ],
          ),
          WebFInspectorFloatingPanel(),
        ],
      ),
    );
  }
}

// Helper method to determine the appropriate bundle based on controller name
WebFBundle? _getBundleForControllerName(String controllerName) {
  switch (controllerName) {
    case 'html/css':
      return WebFBundle.fromUrl('assets:///assets/bundle.html');
    // return WebFBundle.fromUrl('http://127.0.0.1:3300/kraken_debug_server.js');
    case 'esm_demo':
      return WebFBundle.fromUrl('assets:///assets/esm_demo.html');
    case 'import_meta_demo':
      return WebFBundle.fromUrl('assets:///assets/import_meta_demo.html');
    case 'vuejs':
      return WebFBundle.fromUrl('assets:///vue_project/dist/index.html');
    case 'reactjs':
      return WebFBundle.fromUrl('http://localhost:3000/react_project/build');
    case 'miracle_plus':
      return WebFBundle.fromUrl('https://miracleplus.openwebf.com/');
    case 'hybrid_router':
      return WebFBundle.fromUrl('assets:///hybrid_router/build/index.html');
    case 'tailwind_react':
      return WebFBundle.fromUrl('assets:///tailwind_react/build/index.html');
    case 'cupertino_gallery':
      return WebFBundle.fromUrl('https://vue-cupertino-gallery.openwebf.com/');
    case 'use_cases':
      return WebFBundle.fromUrl('assets:///use_cases/dist/index.html');
    case 'react_use_cases':
      return WebFBundle.fromUrl('https://usecase.openwebf.com/');
    default:
      // Return null if the controller name is not recognized
      return null;
  }
}

class WebFDemo extends StatefulWidget {
  final String webfPageName;
  final String initialRoute;
  final Map<String, dynamic>? initialState;

  const WebFDemo({
    super.key,
    required this.webfPageName,
    this.initialRoute = '/',
    this.initialState,
  });

  @override
  State<WebFDemo> createState() => _WebFDemoState();
}

class _WebFDemoState extends State<WebFDemo> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('WebF Demo'),
        actions: [
        ],
      ),
      body: Stack(
        children: [
          WebF.fromControllerName(
            controllerName: widget.webfPageName,
            loadingWidget: buildSplashScreen(),
            initialRoute: widget.initialRoute,
            initialState: widget.initialState,
            bundle: _getBundleForControllerName(widget.webfPageName),
            createController: () => WebFController(
              routeObserver: routeObserver,
              initialRoute: widget.initialRoute,
              onControllerInit: (controller) async {},
              httpLoggerOptions: HttpLoggerOptions(
                requestHeader: true,
                requestBody: true,
              ),
              onLCPContentVerification:
                  (ContentInfo contentInfo, String routePath) {
                    print('contentInfo: $contentInfo $routePath');
                  },
              onLCP: (time, isEvaluated) {
                print('LCP time: $time ms, evaluated: $isEvaluated');
              },
            ),
            setup: (controller) {

              // Register event listeners for all main phases
              controller.loadingState.onConstructor((event) {
                print('🏗️ Constructor at ${event.elapsed.inMilliseconds}ms');
              });

              controller.loadingState.onInit((event) {
                print('🚀 Initialize at ${event.elapsed.inMilliseconds}ms');
              });

              controller.loadingState.onPreload((event) {
                print('📦 Preload at ${event.elapsed.inMilliseconds}ms');
              });

              controller.loadingState.onResolveEntrypointStart((event) {
                print(
                  '🔍 Resolve Entrypoint Start at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onResolveEntrypointEnd((event) {
                print(
                  '✅ Resolve Entrypoint End at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onParseHTMLStart((event) {
                print(
                  '📄 Parse HTML Start at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onParseHTMLEnd((event) {
                print('✅ Parse HTML End at ${event.elapsed.inMilliseconds}ms');
              });

              controller.loadingState.onScriptQueue((event) {
                print('📋 Script Queue at ${event.elapsed.inMilliseconds}ms');
              });

              controller.loadingState.onScriptLoadStart((event) {
                print(
                  '📥 Script Load Start at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onScriptLoadComplete((event) {
                print(
                  '✅ Script Load Complete at ${event.elapsed.inMilliseconds}ms ${event.parameters}',
                );
              });

              controller.loadingState.onAttachToFlutter((event) {
                print(
                  '🔗 Attach to Flutter at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onScriptExecuteStart((event) {
                print(
                  '▶️ Script Execute Start at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onScriptExecuteComplete((event) {
                print(
                  '✅ Script Execute Complete at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onDOMContentLoaded((event) {
                print(
                  '📄 DOM Content Loaded at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onWindowLoad((event) {
                print('🪟 Window Load at ${event.elapsed.inMilliseconds}ms');
              });

              controller.loadingState.onBuildRootView((event) {
                print(
                  '🏗️ Build Root View at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onFirstPaint((event) {
                print(
                  '🎨 First Paint (FP) at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onFirstContentfulPaint((event) {
                print(
                  '🖼️ First Contentful Paint (FCP) at ${event.elapsed.inMilliseconds}ms',
                );
              });

              controller.loadingState.onLargestContentfulPaint((event) {
                final isCandidate = event.parameters['isCandidate'] ?? false;
                final isFinal = event.parameters['isFinal'] ?? false;
                final status = isFinal
                    ? 'FINAL'
                    : (isCandidate ? 'CANDIDATE' : 'UNKNOWN');
                print(
                  '📊 Largest Contentful Paint (LCP) ($status) at ${event.parameters['timeSinceNavigationStart']}ms',
                );
              });
            },
          ),
          WebFInspectorFloatingPanel(),
        ],
      ),
    );
  }

  static Widget buildSplashScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/logo.png', width: 150, height: 150),
          SizedBox(height: 24),
          CupertinoActivityIndicator(radius: 14),
          SizedBox(height: 16),
          Text(
            '正在加载...',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
