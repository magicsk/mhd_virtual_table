class Stop {
  String _name;
  String _url;

  Stop(this._name, this._url);

  Stop.fromJson(Map<String, dynamic> json) {
    _name = json['name'];
    _url = json['url'];
  }

  String get name => _name;
  String get url => _url;

  Map<String, dynamic> toJson() => {
    'name': _name,
    'url': _url,
  };
}