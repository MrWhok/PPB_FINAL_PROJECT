import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String photoURL;
  final String goal;
  final String bio;
  final String phone;
  final String address;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoURL = '',
    this.goal = '',
    this.bio = '',
    this.phone = '',
    this.address = '',
  });

  UserProfile copyWith({
    String? name,
    String? photoURL,
    String? goal,
    String? bio,
    String? phone,
    String? address,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoURL: photoURL ?? this.photoURL,
        goal: goal ?? this.goal,
        bio: bio ?? this.bio,
        phone: phone ?? this.phone,
        address: address ?? this.address,
      );

  /// Only the user-editable fields, for a Firestore update.
  /// Catatan: di Firestore field-nya bernama `phoneNumber` agar konsisten
  /// dengan dokumen yang dibuat AuthRepository saat registrasi.
  Map<String, dynamic> toUpdateMap() => {
    'name': name,
    'photoURL': photoURL,
    'goal': goal,
    'bio': bio,
    'phoneNumber': phone,
    'address': address,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] as String? ?? '',
    name: map['name'] as String? ?? '',
    email: map['email'] as String? ?? '',
    photoURL: map['photoURL'] as String? ?? '',
    goal: map['goal'] as String? ?? '',
    bio: map['bio'] as String? ?? '',
    // baca `phoneNumber` (utama) atau `phone` (kompatibilitas lama)
    phone:
    map['phoneNumber'] as String? ?? map['phone'] as String? ?? '',
    address: map['address'] as String? ?? '',
  );

  factory UserProfile.fromDoc(DocumentSnapshot doc) =>
      UserProfile.fromMap(doc.data() as Map<String, dynamic>);
}