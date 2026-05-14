import 'package:flutter/material.dart';
import 'home/home_view.dart';
import 'store/store_view.dart';
import 'app_drawer.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // --- NEW: Persistent data storage ---
  String? _globalLastStory;
  List<String>? _globalLastWords;

  // Callback to update the story from HomeView
  void _updateLastStory(String story, List<String> words) {
    setState(() {
      _globalLastStory = story;
      _globalLastWords = words;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We define the screens inside build so they can receive updated data
    final List<Widget> _screens = [
      HomeView(
        lastStory: _globalLastStory,
        lastWords: _globalLastWords,
        onStoryGenerated: _updateLastStory, // Pass the callback
      ),
      const StoreView(),
    ];

    final List<String> _titles = ['Story Generator', 'Recent Stories'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      drawer: const AppDrawer(),
      body: IndexedStack( // Use IndexedStack to keep the scroll position and state alive
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.grey.shade200,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Generate'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Store'),
        ],
      ),
    );
  }
}