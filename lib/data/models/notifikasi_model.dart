class Notifikasi {
  final int id;
  final int userId;
  final String judul;
  final String pesan;
  final String? tipe;
  final int? relatedId;
  final int isRead;
  final String createdAt;
  final String? updatedAt;

  Notifikasi({
    required this.id,
    required this.userId,
    required this.judul,
    required this.pesan,
    this.tipe,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id'].toString()) ?? 0,
      judul: json['judul'] ?? '',
      pesan: json['pesan'] ?? '',
      tipe: json['tipe'],
      relatedId: json['related_id'] != null
          ? (json['related_id'] is int
              ? json['related_id']
              : int.tryParse(json['related_id'].toString()))
          : null,
      isRead: json['is_read'] is int
          ? json['is_read']
          : int.tryParse(json['is_read'].toString()) ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
