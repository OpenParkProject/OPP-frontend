/// plate : "string"
/// brand : "string"
/// model : "string"

class CarModel {
  String? plate;
  String? brand;
  String? model;

  CarModel({this.plate, this.brand, this.model});

  CarModel.fromJson(Map<String, dynamic> json) {
    plate = json['plate'];
    brand = json['brand'];
    model = json['model'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plate'] = plate;
    data['brand'] = brand;
    data['model'] = model;
    return data;
  }
}
