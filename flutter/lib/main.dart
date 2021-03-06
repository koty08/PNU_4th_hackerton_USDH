import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login/firebase_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'function/signedin_page.dart';
import 'login/signin_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<FirebaseProvider>(create: (_) => FirebaseProvider())],
      child: MaterialApp(
        title: "USDH",
        home: AuthPage(),
        theme: ThemeData(errorColor: Colors.indigo.shade200),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('ko', 'KR'),
        ],
      ),
    );
  }
}

late AuthPageState pageState;

class AuthPage extends StatefulWidget {
  @override
  AuthPageState createState() {
    pageState = AuthPageState();
    return pageState;
  }
}

class AuthPageState extends State<AuthPage> {
  late FirebaseProvider fp;

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);
    logger.d("user: ${fp.getUser()}");

    if (fp.getUser() != null && fp.getUser()?.emailVerified == true) {
      return SignedInPage();
    } else {
      return SignInPage();
    }
  }
}
