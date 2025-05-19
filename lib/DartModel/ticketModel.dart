/// plate : "string"
/// start_date : "2019-08-24T14:15:22Z"
/// id : 0
/// end_date : "2019-08-24T14:15:22Z"
/// price : 0.1
/// paid : true
/// creation_time : "2019-08-24T14:15:22Z"

class TicketModel {
  TicketModel({
    String plate,
    String startDate,
    num id,
    String endDate,
    num price,
    bool paid,
    String creationTime,
  }) {
    _plate = plate;
    _startDate = startDate;
    _id = id;
    _endDate = endDate;
    _price = price;
    _paid = paid;
    _creationTime = creationTime;
  }

  TicketModel.fromJson(dynamic json) {
    _plate = json['plate'];
    _startDate = json['start_date'];
    _id = json['id'];
    _endDate = json['end_date'];
    _price = json['price'];
    _paid = json['paid'];
    _creationTime = json['creation_time'];
  }
  String _plate;
  String _startDate;
  num _id;
  String _endDate;
  num _price;
  bool _paid;
  String _creationTime;
  TicketModel copyWith({
    String plate,
    String startDate,
    num id,
    String endDate,
    num price,
    bool paid,
    String creationTime,
  }) => TicketModel(
    plate: plate ?? _plate,
    startDate: startDate ?? _startDate,
    id: id ?? _id,
    endDate: endDate ?? _endDate,
    price: price ?? _price,
    paid: paid ?? _paid,
    creationTime: creationTime ?? _creationTime,
  );
  String get plate => _plate;
  String get startDate => _startDate;
  num get id => _id;
  String get endDate => _endDate;
  num get price => _price;
  bool get paid => _paid;
  String get creationTime => _creationTime;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['plate'] = _plate;
    map['start_date'] = _startDate;
    map['id'] = _id;
    map['end_date'] = _endDate;
    map['price'] = _price;
    map['paid'] = _paid;
    map['creation_time'] = _creationTime;
    return map;
  }
}
