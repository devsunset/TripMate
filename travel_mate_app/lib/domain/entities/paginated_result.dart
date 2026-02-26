/// 페이징 결과. 목록과 전체 개수.
library;
import 'package:equatable/equatable.dart';

class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final int total;

  const PaginatedResult({required this.items, required this.total});

  bool get hasMore => items.length < total;

  @override
  List<Object?> get props => [items, total];
}
