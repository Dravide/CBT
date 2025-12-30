import 'dart:convert';
import 'dart:io'; // Added for File
import 'package:http/http.dart' as http;
import 'package:cbt_app/models/social_post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // Add this import

class SocialService {
  static const String baseUrl = 'https://digiclass.smpn1cipanas.sch.id/api/social';
  
  // ... existing methods ...
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Helper method for headers if needed
  
  // existing _getUserNis ...


  
  // Use NIS (String) instead of ID (int) for identification
  Future<String?> _getUserNis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_nis');
  }

  Future<String> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role') ?? 'siswa';
  }

  // 1. Get Timeline
  Future<SocialTimelineResponse> getTimeline({
    int page = 1, 
    String? classFilter, 
    String? userFilter,
    String? userFilterType, // 'guru' or 'siswa' - helps backend know which table to filter
    String? search,
  }) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in (NIS missing)');

    final uri = Uri.parse('$baseUrl/posts').replace(queryParameters: {
      'current_user_id': userNis,
      'user_type': userRole, // Send role
      'page': page.toString(),
      if (classFilter != null) 'class_filter': classFilter,
      if (userFilter != null) 'user_filter': userFilter,
      if (userFilterType != null) 'user_filter_type': userFilterType, // NEW: Tell backend if filtering guru or siswa
      if (search != null && search.isNotEmpty) 'search': search,
    });

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      return SocialTimelineResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load timeline: ${response.statusCode}');
    }
  }

  // 2. Create Post
  Future<SocialPost> createPost(String content, List<String> tags, {File? image}) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in (NIS missing)');
    final token = await _getToken();
    
    var uri = Uri.parse('$baseUrl/posts');
    var request = http.MultipartRequest('POST', uri);

    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['current_user_id'] = userNis;
    request.fields['user_type'] = userRole; // Send role
    request.fields['content'] = content;
    
    for (var tag in tags) {
       request.fields['tags[]'] = tag;
    }

    if (image != null) {
      final String extension = image.path.split('.').last.toLowerCase();
      MediaType contentType;
      
      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        contentType = MediaType('image', 'jpeg');
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          image.path,
          contentType: contentType,
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SocialPost.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to create post: ${response.body}');
    }
  }

  // 2b. Update Post
  Future<SocialPost> updatePost(String postId, String content, List<String> tags, {File? image}) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in');

    var uri = Uri.parse('$baseUrl/posts/$postId'); 
    var request = http.MultipartRequest('POST', uri);
    
    final token = await _getToken();
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['_method'] = 'PUT';
    request.fields['current_user_id'] = userNis;
    request.fields['user_type'] = userRole; // Send role
    request.fields['content'] = content;
    
    for (var tag in tags) {
       request.fields['tags[]'] = tag;
    }

    if (image != null) {
      final String extension = image.path.split('.').last.toLowerCase();
      MediaType contentType;
      
      if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'webp') {
        contentType = MediaType('image', 'webp');
      } else {
        contentType = MediaType('image', 'jpeg');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          image.path,
          contentType: contentType,
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return SocialPost.fromJson(json.decode(response.body)['data']);
    } else {
      throw Exception('Failed to update post: ${response.body}');
    }
  }

  // 3. Toggle Like
  Future<bool> toggleLike(String postId) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in (NIS missing)');

    final uri = Uri.parse('$baseUrl/posts/$postId/like').replace(queryParameters: {
      'current_user_id': userNis,
      'user_type': userRole, // Send role
    });

    final response = await http.post(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == 'liked';
    } else {
      throw Exception('Failed to toggle like: ${response.body}');
    }
  }

  // 4. Get Comments
  Future<List<SocialComment>> getComments(String postId) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    
    final uri = Uri.parse('$baseUrl/posts/$postId/comments').replace(queryParameters: {
      if (userNis != null) 'current_user_id': userNis,
      if (userNis != null) 'user_type': userRole, // Send role
    });

    final response = await http.get(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];
      return data.map((e) => SocialComment.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  // 5. Post Comment
  Future<SocialComment> postComment(String postId, String content) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in (NIS missing)');

    final uri = Uri.parse('$baseUrl/posts/$postId/comments'); // Post Body preferred for create

    final response = await http.post(
      uri,
      headers: {'Accept': 'application/json'},
      body: {
        'current_user_id': userNis,
        'user_type': userRole, // Send role
        'content': content,
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
       final jsonResponse = json.decode(response.body);
       return SocialComment.fromJson(jsonResponse['data']);
    } else {
       throw Exception('Failed to post comment: ${response.body}');
    }
  }

  // 6. Delete Post
  Future<bool> deletePost(String postId) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in');

    final uri = Uri.parse('$baseUrl/posts/$postId').replace(queryParameters: {
       'current_user_id': userNis,
       'user_type': userRole, // Send role
    });

    final response = await http.delete(uri, headers: {'Accept': 'application/json'});
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  // 7. Delete Comment
  Future<bool> deleteComment(String postId, String commentId) async {
    final userNis = await _getUserNis();
    final userRole = await _getUserRole();
    if (userNis == null) throw Exception('User not logged in');

    final uri = Uri.parse('$baseUrl/posts/$postId/comments/$commentId').replace(queryParameters: {
      'current_user_id': userNis,
      'user_type': userRole, // Send role
    });

    final response = await http.delete(uri, headers: {'Accept': 'application/json'});

    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    }
    
    throw Exception('Failed to delete comment: ${response.body}');
  }
}

class SocialTimelineResponse {
  final List<SocialPost> posts;
  final int currentPage;
  final int lastPage;

  SocialTimelineResponse({required this.posts, required this.currentPage, required this.lastPage});

  factory SocialTimelineResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<SocialPost> postsList = list.map((i) => SocialPost.fromJson(i)).toList();
    
    return SocialTimelineResponse(
      posts: postsList,
      currentPage: json['meta']['current_page'],
      lastPage: json['meta']['last_page'],
    );
  }
}
