/// A Postgrest response
class PostgrestResponse<T> {
  const PostgrestResponse({
    required this.data,
    required this.status,
    this.count,
  });

  final T? data;

  final int status;

  final int? count;

  factory PostgrestResponse.fromJson(Map<String, dynamic> json) =>
      PostgrestResponse<T>(
        data: json['data'] as T,
        status: json['status'] as int,
        count: json['count'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'data': data,
        'status': status,
        'count': count,
      };
}
