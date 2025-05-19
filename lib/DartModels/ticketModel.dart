/// plate : "string"
/// start_date : "2019-08-24T14:15:22Z"
/// id : 0
/// end_date : "2019-08-24T14:15:22Z"
/// price : 0.1
/// paid : true
/// creation_time : "2019-08-24T14:15:22Z"

class TicketModel {
  String? plate;
  String? startDate;
  int? id;
  String? endDate;
  double? price;
  bool? paid;
  String? creationTime;

  TicketModel({
    this.plate,
    this.startDate,
    this.id,
    this.endDate,
    this.price,
    this.paid,
    this.creationTime,
  });

  TicketModel.fromJson(Map<String, dynamic> json) {
    plate = json['plate'];
    startDate = json['start_date'];
    id = json['id'];
    endDate = json['end_date'];
    price = json['price'];
    paid = json['paid'];
    creationTime = json['creation_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plate'] = plate;
    data['start_date'] = startDate;
    data['id'] = id;
    data['end_date'] = endDate;
    data['price'] = price;
    data['paid'] = paid;
    data['creation_time'] = creationTime;
    return data;
  }
}
