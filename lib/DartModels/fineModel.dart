class FineModel {
  String? plate;
  double? amount;
  int? id;
  String? date;

  FineModel({this.plate, this.amount, this.id, this.date});

  FineModel.fromJson(Map<String, dynamic> json) {
    plate = json['plate'];
    amount = json['amount'];
    id = json['id'];
    date = json['date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plate'] = plate;
    data['amount'] = amount;
    data['id'] = id;
    data['date'] = date;
    return data;
  }
}
