class EXModel {
  String? id;
  String? brand;
  String? model;

  EXModel({this.id, this.brand, this.model});

  EXModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    brand = json['brand'];
    model = json['model'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['brand'] = brand;
    data['model'] = model;
    return data;
  }
}
