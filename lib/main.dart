import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/notes/notes_screen.dart';
import 'screens/finance/finance_screen.dart';
import 'screens/stocks/stocks_screen.dart';
import 'screens/health/health_screen.dart';
import 'screens/learning_hub/learning_hub_screen.dart';
import 'screens/tablo/tablo_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  await NotificationService().init();
  runApp(const FinviaApp());
}

class FinviaApp extends StatefulWidget {
  const FinviaApp({super.key});
  static FinviaAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<FinviaAppState>();
  @override
  State<FinviaApp> createState() => FinviaAppState();
}

class FinviaAppState extends State<FinviaApp> {
  ThemeMode _themeMode = ThemeMode.light;
  int _dataVersion = 0;

  void updateTheme(bool isDark) {
    if (!mounted) return;
    final nextMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == nextMode) return;
    setState(() => _themeMode = nextMode);
  }

  void refreshUserData({bool? isDarkMode}) {
    if (!mounted) return;
    setState(() {
      if (isDarkMode != null) {
        _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
      _dataVersion++;
    });
  }

  void resetUserData() {
    refreshUserData(isDarkMode: false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finvia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: _StartupSplashGate(dataVersion: _dataVersion),
    );
  }
}

class _StartupSplashGate extends StatefulWidget {
  const _StartupSplashGate({required this.dataVersion});

  final int dataVersion;

  @override
  State<_StartupSplashGate> createState() => _StartupSplashGateState();
}

class _StartupSplashGateState extends State<_StartupSplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Future.delayed(const Duration(milliseconds: 900), _hideSplash);
  }

  @override
  void dispose() {
    _restoreSystemUi();
    super.dispose();
  }

  void _hideSplash() {
    if (!mounted) return;
    _restoreSystemUi();
    setState(() => _showSplash = false);
  }

  void _restoreSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const _FullScreenSplash();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _FullScreenSplash();
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (_canEnterApp(user)) {
            return _DataSyncGate(
              userId: user.uid,
              child: MainNavigation(key: ValueKey(widget.dataVersion)),
            );
          }

          return const LoginScreen();
        }

        return const LoginScreen();
      },
    );
  }

  bool _canEnterApp(User user) {
    final providerIds = user.providerData.map((p) => p.providerId).toSet();
    return !providerIds.contains('password') || user.emailVerified;
  }
}

class _FullScreenSplash extends StatelessWidget {
  const _FullScreenSplash();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: Image(
        image: AssetImage('assets/splash/splash_logo.png'),
        fit: BoxFit.cover,
        alignment: Alignment.center,
      ),
    );
  }
}

class _DataSyncGate extends StatefulWidget {
  const _DataSyncGate({required this.userId, required this.child});

  final String userId;
  final Widget child;

  @override
  State<_DataSyncGate> createState() => _DataSyncGateState();
}

class _DataSyncGateState extends State<_DataSyncGate> {
  late Future<_CloudStartupResult> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _loadCloudData();
  }

  @override
  void didUpdateWidget(covariant _DataSyncGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _startupFuture = _loadCloudData();
    }
  }

  Future<_CloudStartupResult> _loadCloudData() async {
    final database = DatabaseService();
    final hasCloudAccess = await database.verifyCloudAccess();
    if (!hasCloudAccess) {
      return const _CloudStartupResult(hasCloudAccess: false);
    }
    final settings = await database.getAppSettings();
    return _CloudStartupResult(
      hasCloudAccess: true,
      isDarkMode: settings['darkMode'] as bool? ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CloudStartupResult>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bulut verileri yükleniyor...'),
                ],
              ),
            ),
          );
        }
        final result = snapshot.data;
        if (result != null && result.hasCloudAccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FinviaApp.of(context)?.updateTheme(result.isDarkMode);
          });
        }
        return widget.child;
      },
    );
  }
}

class _CloudStartupResult {
  const _CloudStartupResult({
    required this.hasCloudAccess,
    this.isDarkMode = false,
  });

  final bool hasCloudAccess;
  final bool isDarkMode;
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    NotesScreen(),
    FinanceScreen(),
    StocksScreen(),
    HealthScreen(),
    LearningHubScreen(),
    TabloScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finans',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Borsa',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Sağlık',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'LearningHub',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Tablo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
