class SocialComment {
  final String id; // Keep as String for safety, convert from API int/long
  final String userName;
  final String? authorNis; // To identify ownership
  final String? userAvatar;
  final String content;
  final DateTime timestamp;

  SocialComment({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.timestamp,
    this.authorNis,
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id'].toString(),
      userName: json['user_name'] ?? 'Anonim',
      userAvatar: json['user_avatar'], // Can be null
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      // Try to get NIS from available fields. 
      // If backend sends 'user_handle' in comments too:
      authorNis: (json['user_handle'] as String?)?.replaceAll('@', '') 
                 ?? json['user_id']?.toString() 
                 ?? json['nis']?.toString(),
    );
  }
}

class SocialPost {
  final String id;
  final String userName;
  final String userHandle;
  final String? userAvatar; // Can be null
  final String className;
  final String content;
  final DateTime timestamp;
  final List<String> taggedClasses;
  
  // Interaction Data
  bool isLiked;
  int likeCount; // Changed from likedBy list to count
  int commentCount; // Changed from commentsList to count
  
  // Note: Comments are now fetched separately, so we don't store them in the post model for the feed
  // But for the detail view/modal, we might fetch them. 
  // For the model used in the list, we keep it simple.

  final String? imageUrl; // New field for post image
  final String? authorNis; // To identify ownership

  SocialPost({
    required this.id,
    required this.userName,
    required this.userHandle,
    this.userAvatar,
    this.imageUrl, // Add to constructor
    this.authorNis,
    required this.className,
    required this.content,
    required this.timestamp,
    this.taggedClasses = const [],
    this.isLiked = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isEdited = false,
    this.updatedAt,
    this.authorType = 'siswa', // Added to constructor
  });

  bool isEdited;
  final DateTime? updatedAt;
  
  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: json['id'].toString(),
      userName: json['user_name'] ?? 'User',
      userHandle: json['user_handle'] ?? '',
      authorNis: (json['user_handle'] as String?)?.replaceAll('@', ''), // Extract NIS from handle
      userAvatar: json['user_avatar'],
      imageUrl: json['image_url'], // Parse image url
      className: json['class_name'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      taggedClasses: json['tagged_classes'] != null 
          ? List<String>.from(json['tagged_classes']) 
          : [],
      isLiked: json['is_liked'] ?? false,
      likeCount: json['likes_count'] ?? 0,
      commentCount: json['comments_count'] ?? 0,
      isEdited: json['is_edited'] ?? (
        // Fallback: Check if updated_at is significantly different from created_at/timestamp
        json['updated_at'] != null && json['timestamp'] != null && 
        json['updated_at'] != json['timestamp']
      ),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      authorType: _parseAuthorType(json),
    );
  }

  static String _parseAuthorType(Map<String, dynamic> json) {
    // 1. Explicit Check from backend
    if (json['author_type'] != null) {
      final type = json['author_type'].toString().toLowerCase();
      if (type == 'guru') return 'guru';
      if (type == 'siswa') return 'siswa';
    }
    
    // 2. Check if guru_id exists (backend may send this)
    if (json['guru_id'] != null && json['guru_id'] != 0) {
      return 'guru';
    }
    
    // 3. Heuristic Check if backend doesn't send author_type
    final className = json['class_name']?.toString().toLowerCase() ?? '';
    final handle = (json['user_handle'] as String?)?.replaceAll('@', '') ?? '';
    
    // If class_name contains 'guru' keyword
    if (className.contains('guru')) {
      return 'guru';
    }
    
    // If handle is NIP format (18 digits typically) - Guru indicator
    // NIP format: YYYYMMDD YYYYMM X XXX (18 digits)
    if (handle.length >= 18) {
      return 'guru';
    }
    
    // If class_name is empty or dash AND handle is longer than typical NIS (5-10 chars)
    if ((className.isEmpty || className == '-' || className == 'null') && handle.length > 12) {
      return 'guru';
    }
    
    return 'siswa';
  }

  // Add field
  final String authorType;
  
  // Fallback dummy for testing if needed
  static List<SocialPost> get dummyPosts => []; 

  SocialPost copyWith({
    String? id,
    String? userName,
    String? userHandle,
    String? content,
    bool? isLiked,
    int? likeCount,
    int? commentCount,
    String? authorType,
    // Add other fields as needed for copy
  }) {
    return SocialPost(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      userAvatar: userAvatar,
      imageUrl: imageUrl,
      authorNis: authorNis,
      className: className,
      content: content ?? this.content,
      timestamp: timestamp,
      taggedClasses: taggedClasses,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isEdited: isEdited,
      updatedAt: updatedAt,
      authorType: authorType ?? this.authorType,
    );
  }
}
