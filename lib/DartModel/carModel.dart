/// plate : "string"
/// brand : "string"
/// model : "string"

class CarModel {
  CarModel({String plate, String brand, String model}) {
    _plate = plate;
    _brand = brand;
    _model = model;
  }

  CarModel.fromJson(dynamic json) {
    _plate = json['plate'];
    _brand = json['brand'];
    _model = json['model'];
  }
  String _plate;
  String _brand;
  String _model;
  CarModel copyWith({String plate, String brand, String model}) => CarModel(
    plate: plate ?? _plate,
    brand: brand ?? _brand,
    model: model ?? _model,
  );
  String get plate => _plate;
  String get brand => _brand;
  String get model => _model;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['plate'] = _plate;
    map['brand'] = _brand;
    map['model'] = _model;
    return map;
  }
}
