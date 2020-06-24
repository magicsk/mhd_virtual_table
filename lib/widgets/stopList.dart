class Stop {
  int _id;
  String _name;
  String _url;

  Stop(this._id, this._name, this._url);

  Stop.fromJson(Map json) {
    _id = json['id'];
    _name = json['name'];
    _url = json['url'];
  }

  int get id => _id;
  String get name => _name;
  String get url => _url;

  Map toJson() => {
    'id' : _id,
    'name': _name,
    'url': _url,
  };
}