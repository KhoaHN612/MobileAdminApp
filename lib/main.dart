  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
  import 'package:provider/provider.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:yoga_customer/views/cart_page.dart';
  import 'package:yoga_customer/models/cart.dart';
  import 'package:yoga_customer/models/course.dart';
  import 'package:yoga_customer/models/class.dart'; 
  import 'firebase_options.dart';
  import 'views/register_page.dart';
  import 'views/login_page.dart';
  import 'views/home_page.dart';
  import 'views/profile_page.dart';
  import 'views/classes_page.dart';
  import 'views/update_user_name_page.dart';
  import 'views/update_password_page.dart';
  import 'views/order_page.dart'; 

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => Cart()..loadCartFromFirestore()),
          Provider<Map<String, Course>>(create: (context) => <String, Course>{}),
          Provider<List<Class>>(create: (context) => <Class>[]), 
        ],
        child: MaterialApp(
          title: 'Yoga Customer',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthCheck(),
            '/cart': (context) => CartPage(),
            '/profile': (context) => ProfilePage(),
            '/classes': (context) => ClassesPage(),
            '/update_user_name': (context) => UpdateUserNamePage(),
            '/update_password': (context) => UpdatePasswordPage(),
            '/order': (context) => OrderPage(), 
          },
          debugShowCheckedModeBanner: false,
        ),
      );
    }
  }

  class AuthCheck extends StatefulWidget {
    const AuthCheck({super.key});

    @override
    _AuthCheckState createState() => _AuthCheckState();
  }

  class _AuthCheckState extends State<AuthCheck> {
    bool _isLoggedIn = false;

    @override
    void initState() {
      super.initState();
      _checkLoginStatus();
    }

    Future<void> _checkLoginStatus() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      });
    }

    @override
    Widget build(BuildContext context) {
      if (_isLoggedIn) {
        return const HomePage();
      } else {
        return const LoginPage();
      }
    }
  }
