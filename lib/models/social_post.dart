class SocialComment {
  final String id;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime timestamp;

  SocialComment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.timestamp,
  });
}

class SocialPost {
  final String id;
  final String userName;
  final String userHandle;
  final String userAvatar; // Initial for avatar
  final String className; // Kelas User (e.g. "9A")
  final String content;
  final DateTime timestamp;
  final List<String> taggedClasses; // ["9A", "8B", "OSIS"]
  
  // Interaction Data
  bool isLiked;
  final List<String> likedBy; // List of names who liked
  final List<SocialComment> commentsList;

  SocialPost({
    required this.id,
    required this.userName,
    required this.userHandle,
    required this.userAvatar,
    required this.className,
    required this.content,
    required this.timestamp,
    this.taggedClasses = const [],
    this.isLiked = false,
    this.likedBy = const [],
    this.commentsList = const [],
  });
  
  int get likeCount => likedBy.length + (isLiked ? 1 : 0); // Self like adjustment
  int get commentCount => commentsList.length;

  // Dummy Data
  static List<SocialPost> get dummyPosts {
    return [
      SocialPost(
        id: '1',
        userName: 'Ahmad Rizki',
        userHandle: '@ahmad_r',
        userAvatar: 'AR',
        className: '9A',
        content: 'Besok jangan lupa bawa buku paket Matematika ya teman-teman! Ada tugas halaman 45. 📚 #matematika',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        taggedClasses: ['9A'],
        likedBy: ['Budi', 'Siti', 'Dewi', 'Rina', 'Joko'],
        commentsList: [
          SocialComment(
            id: 'c1', 
            userName: 'Budi Santoso', 
            userAvatar: 'BS', 
            content: 'Siap, makasih infonya Mad!', 
            timestamp: DateTime.now().subtract(const Duration(minutes: 2))
          ),
          SocialComment(
            id: 'c2', 
            userName: 'Siti Aminah', 
            userAvatar: 'SA', 
            content: 'Halaman 45 yang bagian B aja kan?', 
            timestamp: DateTime.now().subtract(const Duration(minutes: 1))
          ),
        ],
      ),
      SocialPost(
        id: '2',
        userName: 'Siti Aminah',
        userHandle: '@siti_aminah',
        userAvatar: 'SA',
        className: 'Guru',
        content: 'Pengumuman untuk kelas 9B, jam ke-3 kita pindah ke Lab Komputer ya. Harap tepat waktu.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        taggedClasses: ['9B'],
        likedBy: ['Andi', 'Rudi', 'Tri', 'Kusuma', 'Putri', 'Mega', 'Bayu', 'Lina'],
        commentsList: [
          SocialComment(
            id: 'c3', 
            userName: 'Bayu Pradana', 
            userAvatar: 'BP', 
            content: 'Baik bu, terima kasih.', 
            timestamp: DateTime.now().subtract(const Duration(minutes: 50))
          ),
        ],
      ),
      SocialPost(
        id: '3',
        userName: 'OSIS SMPN 1',
        userHandle: '@osis_spensa',
        userAvatar: 'OS',
        className: 'OSIS',
        content: 'Persiapan HUT Sekolah minggu depan! Rapat panitia nanti sore jam 15.00 di ruang OSIS. Wajib hadir perwakilan kelas! 🇮🇩🎉',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        taggedClasses: ['OM', 'PK', '9A', '9B', '8A', '8B', '7A', '7B'],
        isLiked: true,
        likedBy: List.generate(45, (index) => 'User $index'), // Dummy bulk likes
        commentsList: [
           SocialComment(
            id: 'c4', 
            userName: 'Ketua Kelas 9A', 
            userAvatar: 'KK', 
            content: 'Siap hadir min!', 
            timestamp: DateTime.now().subtract(const Duration(hours: 2))
          ),
        ],
      ),
      SocialPost(
        id: '4',
        userName: 'Budi Santoso',
        userHandle: '@budis',
        userAvatar: 'BS',
        className: '8C',
        content: 'Ada yang nemu tempat pensil warna biru di kantin gak? Isinya pulpen sama tipe-x. 😅',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likedBy: ['Dewi', 'Rina'],
        commentsList: [],
      ),
      SocialPost(
        id: '5',
        userName: 'Dewi Lestari',
        userHandle: '@dewi_l',
        userAvatar: 'DL',
        className: '7B',
        content: 'Seneng banget hari ini praktek IPA berhasil! 🌱',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isLiked: true,
        likedBy: ['Siti', 'Budi', 'Ahmad', 'Rina', 'Joko'],
        commentsList: [
           SocialComment(
            id: 'c5', 
            userName: 'Rina Wati', 
            userAvatar: 'RW', 
            content: 'Keren banget Wi! Ajarin dong.', 
            timestamp: DateTime.now().subtract(const Duration(hours: 20))
          ),
        ],
      ),
    ];
  }
}
