import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Post> _postFuture;
  late Future<User> _userFuture;
  late Future<List<dynamic>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _postFuture = _apiService.getPost(widget.postId);
    _postFuture.then((post) {
      setState(() {
        _userFuture = _apiService.getUser(post.userId);
      });
    });
    _commentsFuture = _apiService.getComments(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帖子详情'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostSection(),
            const Divider(height: 30),
            _buildUserSection(),
            const Divider(height: 30),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostSection() {
    return FutureBuilder<Post>(
      future: _postFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('加载帖子时出错: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('没有帖子数据'));
        }

        final post = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 添加帖子大图
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: double.infinity,
                height: 200,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              post.body,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserSection() {
    return FutureBuilder<Post>(
      future: _postFuture,
      builder: (context, postSnapshot) {
        if (postSnapshot.connectionState == ConnectionState.waiting ||
            !postSnapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        return FutureBuilder<User>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('加载用户时出错: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('没有用户数据'));
            }

            final user = snapshot.data!;
            return Card(
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '作者信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      // 使用随机用户头像，基于用户ID生成不同的图片
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: CachedNetworkImageProvider(
                          'https://i.pravatar.cc/100?u=${user.id}',
                        ),
                        onBackgroundImageError: (exception, stackTrace) {
                          // 如果加载失败，回退到文字头像
                          return;
                        },
                        child: null, // 设为null，因为使用了backgroundImage
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('公司: ${user.company.name}'),
                    Text('网站: ${user.website}'),
                    Text('电话: ${user.phone}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentsSection() {
    return FutureBuilder<List<dynamic>>(
      future: _commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('加载评论时出错: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('没有评论'));
        }

        final comments = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '评论 (${comments.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...comments.map((comment) => _buildCommentItem(comment)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    // 从邮箱生成一个唯一值作为头像ID，确保相同邮箱显示相同头像
    final String avatarId = comment['email'].toString().replaceAll(RegExp(r'[^\w\s]+'), '');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 添加评论者头像
            CircleAvatar(
              radius: 20,
              backgroundImage: CachedNetworkImageProvider(
                'https://i.pravatar.cc/80?u=$avatarId',
              ),
              onBackgroundImageError: (exception, stackTrace) {
                // 如果加载失败，使用默认头像
              },
              child: null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    comment['email'],
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(comment['body']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}