import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

import 'package:mhd_virtual_table/locale/locales.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool darkTheme = false;
  bool blackTheme = false;

  _getprefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      darkTheme = prefs.getBool('darkTheme');
      blackTheme = prefs.getBool('blackTheme');
    });
  }

  @override
  void initState() {
    _getprefs();
    super.initState();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context).settingsTitle),
      ),
      body: Column(
        children: <Widget>[
          SwitchListTile(
            value: darkTheme,
            title: Text(AppLocalizations.of(context).darkTheme),
            onChanged: (value) async {
              print(value);
              print(darkTheme);
              print(blackTheme);
              setState(() {
                DynamicTheme.of(context)
                    .setBrightness(value ? Brightness.dark : Brightness.light);
                DynamicTheme.of(context).setThemeData(ThemeData(
                  backgroundColor: value ? null : Colors.white,
                  dialogBackgroundColor: value ? null : Colors.white,
                  scaffoldBackgroundColor: value ? null : Colors.white,
                  primaryColor: Colors.redAccent[700],
                  accentColor: Colors.red,
                  primaryColorDark: Colors.redAccent[700],
                  toggleableActiveColor: Colors.red,
                  primarySwatch: Colors.red,
                  brightness: value ? Brightness.dark : Brightness.light,
                ));
                darkTheme = value;
                blackTheme = false;
              });
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('darkTheme', value);
              await prefs.setBool('blackTheme', false);
            },
          ),
          Divider(),
          SwitchListTile(
            value: blackTheme,
            title: Text(AppLocalizations.of(context).blackTheme),
            onChanged: (value) async {
              setState(() {
                darkTheme = true;
                blackTheme = value;
              });
              DynamicTheme.of(context).setThemeData(ThemeData(
                backgroundColor: value ? Colors.black : null,
                dialogBackgroundColor: value ? Colors.black : null,
                scaffoldBackgroundColor: value ? Colors.black : null,
                primaryColor: Colors.redAccent[700],
                accentColor: Colors.red,
                primaryColorDark: Colors.redAccent[700],
                toggleableActiveColor: Colors.red,
                primarySwatch: Colors.red,
                brightness: Brightness.dark,
              ));
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('darkTheme', true);
              await prefs.setBool('blackTheme', value);
            },
          ),
        ],
      ),
    );
  }
}
