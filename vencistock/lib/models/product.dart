class Product {
  int? id;
  String name;
  String barcode;
  double price;
  int stock;
  String batch;
  String entryDate;
  String expiryDate;
  int daysBeforeAlert;
  String alertHour;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    required this.batch,
    required this.entryDate,
    required this.expiryDate,
    required this.daysBeforeAlert,
    required this.alertHour,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
      'batch': batch,
      'entryDate': entryDate,
      'expiryDate': expiryDate,
      'daysBeforeAlert': daysBeforeAlert,
      'alertHour': alertHour,
    };
    if (id != null) {
      map['id'] = id as Object;
    }
    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    name: map['name'],
    barcode: map['barcode'],
    price:
        map['price'] is int ? (map['price'] as int).toDouble() : map['price'],
    stock: map['stock'],
    batch: map['batch'],
    entryDate: map['entryDate'],
    expiryDate: map['expiryDate'],
    daysBeforeAlert: map['daysBeforeAlert'] ?? 0,
    alertHour: map['alertHour'],
  );

  copyWith({required int stock}) {}
}
