import 'package:flutter/foundation.dart'; // Required for debugPrint

class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  bool get hasMore => page < pages;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    debugPrint("DEBUG: PaginatedResponse parsing keys: ${json.keys.toList()}");

    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    // ADDED: json['applications'] to the lookup list
    final dynamic rawList = json['messages'] ??  // <--- Messages for chat
        json['applications'] ??
        json['products'] ??
        json['jobs'] ??
        json['items'] ??
        json['data'] ??
        [];

    final List<dynamic> itemsList = rawList is List ? rawList : [];

    return PaginatedResponse(
      items: itemsList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      page: _forceInt(pagination['page']) ?? 1,
      limit: _forceInt(pagination['limit']) ?? 20,
      total: _forceInt(pagination['total']) ?? 0,
      pages: _forceInt(pagination['pages']) ?? 0,
    );
  }

  static int? _forceInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory PaginatedResponse.empty() => PaginatedResponse(
    items: [],
    page: 1,
    limit: 20,
    total: 0,
    pages: 0,
  );

  // Helper getters (Inside the class now!)
  List<T> get products => items;
  List<T> get jobs => items;
  List<T> get applications => items;

  PaginationInfo get pagination => PaginationInfo(
    page: page,
    limit: limit,
    total: total,
    pages: pages,
  );
} // <--- Only one closing brace here!

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      pages: json['pages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'pages': pages,
    };
  }

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
  int get nextPage => page + 1;
  int get previousPage => page - 1;
}