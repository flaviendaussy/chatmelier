import 'package:uuid/uuid.dart';

enum OfflineActionType {
  addBottle,
  consumeBottle,
  updateBottle,
  updateWine,
  deleteBottle,
  createCellar,
  updateCellar,
  moveBottle,
}

enum OfflineActionStatus {
  pending,
  syncing,
  failed,
  completed,
}

class OfflineAction {
  final String id;
  final OfflineActionType type;
  final String? cellarId;
  final Map<String, dynamic> data;
  final String? localPhotoPath;
  final DateTime createdAt;
  final OfflineActionStatus status;
  final String? errorMessage;
  final int retryCount;

  OfflineAction({
    String? id,
    required this.type,
    this.cellarId,
    required this.data,
    this.localPhotoPath,
    DateTime? createdAt,
    this.status = OfflineActionStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'cellar_id': cellarId,
        'data': data,
        'local_photo_path': localPhotoPath,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'error_message': errorMessage,
        'retry_count': retryCount,
      };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id'] as String? ?? const Uuid().v4(),
        type: OfflineActionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => OfflineActionType.addBottle,
        ),
        cellarId: json['cellar_id'] as String?,
        data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
        localPhotoPath: json['local_photo_path'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        status: OfflineActionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => OfflineActionStatus.pending,
        ),
        errorMessage: json['error_message'] as String?,
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
      );

  OfflineAction copyWith({
    String? id,
    OfflineActionType? type,
    String? cellarId,
    Map<String, dynamic>? data,
    String? localPhotoPath,
    DateTime? createdAt,
    OfflineActionStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? retryCount,
  }) {
    return OfflineAction(
      id: id ?? this.id,
      type: type ?? this.type,
      cellarId: cellarId ?? this.cellarId,
      data: data ?? this.data,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
