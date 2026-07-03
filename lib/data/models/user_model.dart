class UserModel {
  final int id;
  final String nup;
  final String nama;
  final String? email;
  final String? noTelp;
  final String role;
  final String? jabatan;
  final String? departemen;
  final String? subDepartemen;
  final int? idDept;
  final int? idSubdept;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.nup,
    required this.nama,
    this.email,
    this.noTelp,
    required this.role,
    this.jabatan,
    this.departemen,
    this.subDepartemen,
    this.idDept,
    this.idSubdept,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nup: json['nup'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String?,
      noTelp: json['no_telp'] as String?,
      role: json['role'] as String,
      jabatan: json['jabatan'] as String?,
      departemen: json['departemen'] as String?,
      subDepartemen: json['sub_departemen'] as String?,
      idDept: json['id_dept'] as int?,
      idSubdept: json['id_subdept'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nup': nup,
      'nama': nama,
      'email': email,
      'no_telp': noTelp,
      'role': role,
      'jabatan': jabatan,
      'departemen': departemen,
      'sub_departemen': subDepartemen,
      'id_dept': idDept,
      'id_subdept': idSubdept,
      'created_at': createdAt,
    };
  }
}
