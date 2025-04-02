class Post {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String imageUrl; // 添加图片 URL 字段

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.imageUrl, // 添加图片 URL 参数
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
      // 根据帖子 ID 生成随机图片，保证每篇帖子有不同但一致的图片
      imageUrl: 'https://picsum.photos/seed/${json['id']}/400/300',
    );
  }
}