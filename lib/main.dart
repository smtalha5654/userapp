import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:global_configuration/global_configuration.dart';

import 'generated/l10n.dart';
import 'route_generator.dart';
import 'src/helpers/app_config.dart' as config;
import 'src/helpers/custom_trace.dart';
import 'src/models/setting.dart';
import 'src/repository/settings_repository.dart' as settingRepo;
import 'src/repository/user_repository.dart' as userRepo;

const appId = "ff29b528c8894a46a652ea175f430ba8";
// const token =
//     "007eJxTYDC/cNH24eya868n9U/jLbzC4Z24j/PoO2mdX8686q8/vtFXYDA0TjY2MDdOMTMyMzFJNjSxSE1OMUxKNUg2MDIxtkhO+tAVntoQyMjA8baBlZEBAkF8NoaS1OISI2MGBgDkQSDs";

// const token =
//     "007eJxTYFi4/pL0veRs6ZqwO58ivq4xabsmMD02+tq5pet8Ju2MsGtSYEhLM7JMMjWySLawsDRJNDFLNDM1Sk00NDdNMzE2SEq0kDELS20IZGToPJrNzMgAgSA+K0NJanGJEQMDANkEIHc=";
// const channel = "test2";

const String BASEIMAGEURL =
    "https://galaxysocial.com/everbuy/public/storage/app/public/";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset("configurations");
  await Firebase.initializeApp();
  print(CustomTrace(StackTrace.current,
      message: "base_url: ${GlobalConfiguration().getValue('base_url')}"));
  print(CustomTrace(StackTrace.current,
      message:
          "api_base_url: ${GlobalConfiguration().getValue('api_base_url')}"));
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    settingRepo.initSettings();
    settingRepo.getCurrentLocation();
    userRepo.getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: settingRepo.setting,
        builder: (context, Setting _setting, _) {
          return MaterialApp(
              navigatorKey: settingRepo.navigatorKey,
              title: _setting.appName,
              initialRoute: '/Splash',
              onGenerateRoute: RouteGenerator.generateRoute,
              debugShowCheckedModeBanner: false,
              locale: _setting.mobileLanguage.value,
              localizationsDelegates: [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              theme: _setting.brightness.value == Brightness.light
                  ? ThemeData(
                      fontFamily: 'ProductSans',
                      primaryColor: Colors.white,
                      floatingActionButtonTheme: FloatingActionButtonThemeData(
                          elevation: 0, foregroundColor: Colors.white),
                      brightness: Brightness.light,
                      dividerColor: config.Colors().accentColor(0.1),
                      focusColor: config.Colors().accentColor(1),
                      hintColor: config.Colors().secondColor(1),
                      textTheme: TextTheme(
                        headlineSmall: TextStyle(
                            fontSize: 22.0,
                            color: config.Colors().secondColor(1),
                            height: 1.3),
                        headlineMedium: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().secondColor(1),
                            height: 1.3),
                        displaySmall: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().secondColor(1),
                            height: 1.3),
                        displayMedium: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().mainColor(1),
                            height: 1.4),
                        displayLarge: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w300,
                            color: config.Colors().secondColor(1),
                            height: 1.4),
                        titleMedium: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w500,
                            color: config.Colors().secondColor(1),
                            height: 1.2),
                        titleLarge: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().mainColor(1),
                            height: 1.3),
                        bodyMedium: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                            color: config.Colors().secondColor(1),
                            height: 1.2),
                        bodyLarge: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w400,
                            color: config.Colors().secondColor(1),
                            height: 1.3),
                        bodySmall: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: config.Colors().accentColor(1),
                            height: 1.2),
                      ), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: config.Colors().mainColor(1)),
                    )
                  : ThemeData(
                      fontFamily: 'ProductSans',
                      primaryColor: Color(0xFF252525),
                      brightness: Brightness.dark,
                      scaffoldBackgroundColor: Color(0xFF2C2C2C),
                      dividerColor: config.Colors().accentColor(0.1),
                      hintColor: config.Colors().secondDarkColor(1),
                      focusColor: config.Colors().accentDarkColor(1),
                      textTheme: TextTheme(
                        headlineSmall: TextStyle(
                            fontSize: 22.0,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.3),
                        headlineMedium: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.3),
                        displaySmall: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.3),
                        displayMedium: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().mainDarkColor(1),
                            height: 1.4),
                        displayLarge: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w300,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.4),
                        titleMedium: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w500,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.2),
                        titleLarge: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.w700,
                            color: config.Colors().mainDarkColor(1),
                            height: 1.3),
                        bodyMedium: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w400,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.2),
                        bodyLarge: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w400,
                            color: config.Colors().secondDarkColor(1),
                            height: 1.3),
                        bodySmall: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w300,
                            color: config.Colors().secondDarkColor(0.6),
                            height: 1.2),
                      ), colorScheme: ColorScheme.fromSwatch().copyWith(secondary: config.Colors().mainDarkColor(1)),
                    ));
        });
  }
}
