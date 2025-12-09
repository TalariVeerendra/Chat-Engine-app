enum FriendRequestStatus { pending, accepted, declined }

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondAt;
  final String? message;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondAt,
    this.message,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondAt': respondAt?.millisecondsSinceEpoch,
      'message': message,
    };
  }

  static FriendRequestModel fromMap(Map<String, dynamic> map) {
    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      respondAt: map['respondAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['respondAt'])
          : null,
      message: map['message'],
    );
  }

  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondAt,
    String? message,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondAt: respondAt ?? this.respondAt,
      message: message ?? this.message,
    );
  }
}
