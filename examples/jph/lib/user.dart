import 'dart:convert' as convert;

import 'package:equatable/equatable.dart';

final class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.address,
    required this.phone,
    required this.website,
    required this.company,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final Address address;
  final String phone;
  final String website;
  final Company company;

  factory User.fromRawJson(String str) =>
      User.fromJson(convert.jsonDecode(str));

  String toRawJson() => convert.jsonEncode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    name: json["name"],
    username: json["username"],
    email: json["email"],
    address: Address.fromJson(json["address"]),
    phone: json["phone"],
    website: json["website"],
    company: Company.fromJson(json["company"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "username": username,
    "email": email,
    "address": address.toJson(),
    "phone": phone,
    "website": website,
    "company": company.toJson(),
  };

  @override
  List<Object> get props => [
    id,
    name,
    username,
    email,
    address,
    phone,
    website,
    company,
  ];
}

final class Address extends Equatable {
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final Geo geo;

  const Address({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geo,
  });

  factory Address.fromRawJson(String str) =>
      Address.fromJson(convert.jsonDecode(str));

  String toRawJson() => convert.jsonEncode(toJson());

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    street: json["street"],
    suite: json["suite"],
    city: json["city"],
    zipcode: json["zipcode"],
    geo: Geo.fromJson(json["geo"]),
  );

  Map<String, dynamic> toJson() => {
    "street": street,
    "suite": suite,
    "city": city,
    "zipcode": zipcode,
    "geo": geo.toJson(),
  };

  @override
  List<Object> get props => [street, suite, city, zipcode, geo];
}

final class Geo extends Equatable {
  const Geo({required this.lat, required this.lng});

  final String lat;
  final String lng;

  factory Geo.fromRawJson(String str) => Geo.fromJson(convert.jsonDecode(str));

  String toRawJson() => convert.jsonEncode(toJson());

  factory Geo.fromJson(Map<String, dynamic> json) =>
      Geo(lat: json["lat"], lng: json["lng"]);

  Map<String, dynamic> toJson() => {"lat": lat, "lng": lng};

  @override
  List<Object> get props => [lat, lng];
}

final class Company extends Equatable {
  const Company({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  final String name;
  final String catchPhrase;
  final String bs;

  factory Company.fromRawJson(String str) =>
      Company.fromJson(convert.jsonDecode(str));

  String toRawJson() => convert.jsonEncode(toJson());

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    name: json["name"],
    catchPhrase: json["catchPhrase"],
    bs: json["bs"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "catchPhrase": catchPhrase,
    "bs": bs,
  };

  @override
  List<Object> get props => [name, catchPhrase, bs];
}
