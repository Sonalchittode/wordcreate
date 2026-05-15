import 'package:flutter/material.dart';

import '../screens/story_generator_page.dart';

class StoryApp extends StatelessWidget {
  const StoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF152434)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const StoryGeneratorPage(),
    );
  }
}
