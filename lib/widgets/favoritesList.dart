import 'package:flutter/material.dart';

class Trip {
  String _from;
  String _to;
  int _time;

  Trip(
    this._from,
    this._to, 
    this._time
  );

  Trip.fromJson(Map json) {
    _from = json['from'];
    _to = json['to'];
    _time = json['time'];
  }

  String get from => _from;
  String get to => _to;
  int get time => _time;

  Map toJson() => {
        'from': _from,
        'to': _to,
        'time': _time,
      };
}
