import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:thumbnail_maker/src/providers/canvas_provider.dart'; // Import CanvasProvider
import 'package:thumbnail_maker/src/screens/home_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // Wrap with ChangeNotifierProvider
      create: (context) => CanvasProvider(),
      child: MaterialApp(
        title: 'Thumbnail Maker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
