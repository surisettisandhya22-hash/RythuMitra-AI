import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/backend_config_service.dart';

class CommunityCommentModel {
  final String id;
  final String author;
  final String time;
  final String text;
  final int likes;

  CommunityCommentModel({
    required this.id,
    required this.author,
    required this.time,
    required this.text,
    this.likes = 0,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: json['id'] ?? '',
      author: json['author'] ?? 'Farmer',
      time: json['time'] ?? 'Just now',
      text: json['text'] ?? '',
      likes: json['likes'] ?? 0,
    );
  }
}

class CommunityPostModel {
  final String id;
  final String title;
  final String crop;
  final String category;
  final String author;
  final String location;
  final String time;
  final String content;
  int likes;
  bool isLiked;
  int commentsCount;
  final List<CommunityCommentModel> comments;
  final String? aiVerifiedTip;

  CommunityPostModel({
    required this.id,
    required this.title,
    required this.crop,
    required this.category,
    required this.author,
    required this.location,
    required this.time,
    required this.content,
    this.likes = 0,
    this.isLiked = false,
    this.commentsCount = 0,
    required this.comments,
    this.aiVerifiedTip,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      crop: json['crop'] ?? 'General',
      category: json['category'] ?? 'Discussion',
      author: json['author'] ?? 'Farmer',
      location: json['location'] ?? '',
      time: json['time'] ?? 'Just now',
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      commentsCount: json['commentsCount'] ?? 0,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((c) => CommunityCommentModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      aiVerifiedTip: json['aiVerifiedTip'],
    );
  }
}

class AgronomistExpertModel {
  final String id;
  final String name;
  final String title;
  final String specialization;
  final String experience;
  final List<String> languages;
  final String? phone;
  final String availableHours;
  final double rating;

  AgronomistExpertModel({
    required this.id,
    required this.name,
    required this.title,
    required this.specialization,
    required this.experience,
    required this.languages,
    this.phone,
    required this.availableHours,
    required this.rating,
  });

  factory AgronomistExpertModel.fromJson(Map<String, dynamic> json) {
    return AgronomistExpertModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      specialization: json['specialization'] ?? '',
      experience: json['experience'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      phone: json['phone'],
      availableHours: json['availableHours'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }
}

class CommunityService {
  String get _baseUrl => '${BackendConfigService.getBackendUrl()}/api/community';

  Future<List<CommunityPostModel>> getPosts({String? crop, String? category}) async {
    try {
      final queryParams = <String, String>{};
      if (crop != null && crop.isNotEmpty) queryParams['crop'] = crop;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;

      final uri = Uri.parse('$_baseUrl/posts').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((p) => CommunityPostModel.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading community posts: $e');
    }
    return _getLocalFallbackPosts();
  }

  Future<CommunityPostModel?> createPost({
    required String title,
    required String crop,
    required String content,
    String category = 'Discussion',
    String author = 'Farmer',
    String location = 'Farm Field',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/posts');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'crop': crop,
          'category': category,
          'author': author,
          'location': location,
          'content': content,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        return CommunityPostModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
    }
    return null;
  }

  Future<void> toggleLike(String postId) async {
    try {
      final uri = Uri.parse('$_baseUrl/posts/$postId/like');
      await http.post(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<CommunityCommentModel?> addComment(String postId, String author, String text) async {
    try {
      final uri = Uri.parse('$_baseUrl/posts/$postId/comments');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author': author,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return CommunityCommentModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
    return null;
  }

  Future<List<AgronomistExpertModel>> getExperts() async {
    try {
      final uri = Uri.parse('$_baseUrl/experts');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => AgronomistExpertModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading experts: $e');
    }
    return [
      AgronomistExpertModel(
        id: 'exp_1',
        name: 'Dr. K. Ramakrishna Rao',
        title: 'Senior Agronomist & Soil Scientist',
        specialization: 'Crop Nutrition, Soil Reclamation & Organic Farming',
        experience: '18+ Years',
        languages: ['Telugu', 'English', 'Hindi'],
        phone: '+91 94401 23456',
        availableHours: 'Mon-Sat (10:00 AM - 5:00 PM)',
        rating: 4.9,
      ),
      AgronomistExpertModel(
        id: 'exp_2',
        name: 'Dr. M. Lakshmi Prasanna',
        title: 'Plant Pathologist & IPM Specialist',
        specialization: 'Pest & Disease Management in Chilli, Cotton & Paddy',
        experience: '12+ Years',
        languages: ['Telugu', 'English'],
        phone: '+91 98480 98765',
        availableHours: 'Mon-Fri (9:30 AM - 4:30 PM)',
        rating: 4.8,
      ),
    ];
  }

  List<CommunityPostModel> _getLocalFallbackPosts() {
    return [
      CommunityPostModel(
        id: 'p_1',
        title: 'వరిలో అగ్గితెగులు (Paddy Blast) నివారణకు సమగ్ర యాజమాన్యం',
        crop: 'Paddy',
        category: 'Question',
        author: 'Ramu (రైతు)',
        location: 'Miryalaguda, Nalgonda',
        time: '2 hrs ago',
        content: 'వరి చేలో ఆకులపై కంటి ఆకారంలో మచ్చలు కనిపిస్తున్నాయి. సరైన మందుల వివరాలు తెలపగలరు.',
        likes: 18,
        isLiked: false,
        commentsCount: 2,
        aiVerifiedTip: 'AI సలహా: ట్రైసైక్లాజోల్ (Tricyclazole 75% WP) ఎకరాకు 120 గ్రాములు పిచికారీ చేయండి. యూరియా ఎక్కువ వేయవద్దు.',
        comments: [
          CommunityCommentModel(id: 'c1', author: 'వెంకట్', time: '1 hr ago', text: 'పుల్లటి మజ్జిగ మరియు వేపనూనె కొడితే మంచి ఫలితం ఉంది.'),
        ],
      ),
    ];
  }
}
