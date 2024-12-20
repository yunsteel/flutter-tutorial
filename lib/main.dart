import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

// StatelessWidget, 빌드하는 역할
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

// 값이 변경됐을 때 다른 위젯이 알아야 함. through ChangeNotifier
// React의 Context와 비슷한 것 같음.
class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void removeFavoriteItem(value) {
    favorites.remove(value);
  }
}

// StatelessWidget -> 자체적으로 가진 로컬 state가 없음. 모두 context로부터 가져오는 중임
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  // 모든 위젯은 build() 내 상황이 바뀔 때 마다 최신 상태 유지함
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>(); // watch로 변경사항 추적함
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritePage();
      default:
        throw UnimplementedError("No widget for $selectedIndex");
    }

    // 위젯은 중첩된 트리를 반환해야됨. 이때 최상위가 Scaffold
    return LayoutBuilder(builder: (context, constraints) {
      // Layout builder의 builder callback은 constraints가 변할 때마다 호출된다.
      // 예를 들면 유저가 창크기 바꾸거나, 폰 회전하거나
      // 이 컴포넌트 옆에 있는 어떤 위젯이 커져서 얘가 작아지거나 등..
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
                // 노치나 status bar에 방해받지 않도록 보호됨
                child: NavigationRail(
              extended: constraints.maxWidth >= 600,
              destinations: [
                NavigationRailDestination(
                    icon: Icon(Icons.home), label: Text("홈")),
                NavigationRailDestination(
                    icon: Icon(Icons.favorite), label: Text("좋아요"))
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) => {
                setState(() {
                  selectedIndex = value;
                })
              },
            )),
            Expanded(
                child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: page,
            ))
          ],
        ),
      );
    });
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    // 현재 앱의 테마
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium?.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            pair.asLowerCase,
            style: style,
            semanticsLabel: "${pair.first} ${pair.second}", // 스크린 리더기
          )),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: appState.toggleFavorite,
                label: Text("좋아요"),
                icon: Icon(icon),
              ),
              SizedBox(width: 10),
              ElevatedButton(onPressed: appState.getNext, child: Text("다음으로"))
            ],
          )
        ],
      ),
    );
  }
}

class FavoritePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text("좋아요가 없어양 ㅠㅠ"),
      );
    }

    return ListView(children: [
      Padding(
          padding: const EdgeInsets.all(20),
          child: Text("You have ${appState.favorites.length} favorites.")),
      for (var favorite in appState.favorites)
        ListTile(
            leading: Icon(Icons.favorite),
            title: Text(appState.current.asLowerCase))
    ]);

    return Column(
      children: [
        for (var favorite in appState.favorites)
          Row(children: [
            Text(favorite.join(" ")),
            SizedBox(width: 10),
            ElevatedButton.icon(
                onPressed: () => appState.removeFavoriteItem(favorite),
                icon: Icon(Icons.delete),
                label: Text("삭제"))
          ])
      ],
    );
  }
}
