import 'package:equatable/equatable.dart';

class PaginationModel extends Equatable {
  const PaginationModel({
    required this.currentPage,
    required this.from,
    required this.to,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  final int currentPage;
  final int from;
  final int to;
  final int total;
  final int perPage;
  final int lastPage;

  bool get hasNextPage => currentPage < lastPage;

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      PaginationModel(
        currentPage: json['current_page'] as int,
        from: (json['from'] as int?) ?? 0,
        to: (json['to'] as int?) ?? 0,
        total: json['total'] as int,
        perPage: json['per_page'] as int,
        lastPage: json['last_page'] as int,
      );

  @override
  List<Object?> get props =>
      [currentPage, from, to, total, perPage, lastPage];
}
