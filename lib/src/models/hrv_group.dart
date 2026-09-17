import 'package:flutter/foundation.dart';

/// A group that aggregates HRV data from multiple users.
@immutable
class HrvGroup {
  final String id;
  final String name;
  final String? description;
  final String? organizationId;
  final String inviteCode;
  final bool isActive;
  final DateTime createdAt;
  final int memberCount;
  final String? myRole;
  final String? myStatus;
  final String? myMemberId;

  const HrvGroup({
    required this.id,
    required this.name,
    this.description,
    this.organizationId,
    required this.inviteCode,
    required this.isActive,
    required this.createdAt,
    required this.memberCount,
    this.myRole,
    this.myStatus,
    this.myMemberId,
  });

  bool get isPending => myStatus == 'PENDING';
  bool get isInvited => myStatus == 'INVITED';
  bool get isActiveMember => myStatus == null || myStatus == 'ACTIVE';

  factory HrvGroup.fromJson(Map<String, dynamic> json) {
    return HrvGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      organizationId: json['organizationId'] as String?,
      inviteCode: json['inviteCode'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      memberCount: (json['_count'] as Map<String, dynamic>?)?['members'] as int? ?? 0,
      myRole: json['myRole'] as String?,
      myStatus: json['myStatus'] as String?,
      myMemberId: json['myMemberId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'organizationId': organizationId,
    'inviteCode': inviteCode,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    '_count': {'members': memberCount},
    'myRole': myRole,
    'myStatus': myStatus,
    'myMemberId': myMemberId,
  };
}

/// A member of a group.
@immutable
class HrvGroupMember {
  final String id;
  final String? name;
  final String? email;
  final String? customerKey;
  final String role;
  final String? status;
  final DateTime joinedAt;

  const HrvGroupMember({
    required this.id,
    this.name,
    this.email,
    this.customerKey,
    required this.role,
    this.status,
    required this.joinedAt,
  });

  bool get isPending => status == 'PENDING';
  bool get isInvited => status == 'INVITED';

  factory HrvGroupMember.fromJson(Map<String, dynamic> json) {
    final endUser = json['endUser'] as Map<String, dynamic>?;
    final appUser = json['appUser'] as Map<String, dynamic>?;

    return HrvGroupMember(
      id: json['id'] as String? ?? '',
      name: appUser?['name'] as String?,
      email: appUser?['email'] as String? ?? endUser?['email'] as String?,
      customerKey: endUser?['customerKey'] as String?,
      role: json['role'] as String? ?? 'MEMBER',
      status: json['status'] as String?,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'customerKey': customerKey,
    'role': role,
    'status': status,
    'joinedAt': joinedAt.toIso8601String(),
  };
}
