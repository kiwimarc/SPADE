import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'view/import_view.dart';
import 'model/backend_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((value) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final backendModel = BackendModel();

    return MaterialApp(
      title: 'S.P.A.D.E',
      theme: ThemeData(useMaterial3: true),
      home: ImportView(
        title:
            'Synaptic Pipeline for Automated Decomposition of Electrophysiological data',
        description: 'Automated E/I balance analysis pipline',
        backendStatusStream: backendModel.backendStatusStream,
      ),
    );
  }
}
