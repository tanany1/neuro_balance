import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoInfo {
  final String title;
  final String youtubeId;
  final String url;

  VideoInfo({
    required this.title,
    required this.youtubeId,
    required this.url,
  });
}

class AwarenessScreen extends StatelessWidget {
  AwarenessScreen({super.key});

  final List<VideoInfo> videos = [
    VideoInfo(
      title: "فارماستان - التصلب المتعدد | Multiple Sclerosis",
      youtubeId: "ELBMn7gNaTk",
      url: "https://www.youtube.com/watch?v=ELBMn7gNaTk",
    ),
    VideoInfo(
      title: "أقوي فيديو عن MS (الأسباب والأعراض وأحدث الأدوية) -أ.د.عمرو حسن الحسني - حكيم أعصاب - موسم 1- حلقة18",
      youtubeId: "-YSWDzYPcms",
      url: "https://www.youtube.com/watch?v=-YSWDzYPcms",
    ),
    VideoInfo(
      title: "إيه أنواع التصلب المتعدد وما هي أشد انتكاساته وكيفية علاجه؟",
      youtubeId: "yZmXoM2AwNA",
      url: "https://www.youtube.com/watch?v=yZmXoM2AwNA",
    ),
    VideoInfo(
      title: "أعراض لازم تخلي بالك منها لمرض التصلب المتعدد حذر منها دكتور عمرو حـسن الحسنى | هي وبس",
      youtubeId: "P9oUs4JE9lo",
      url: "https://www.youtube.com/watch?v=P9oUs4JE9lo",
    ),
  ];

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('MS Awareness')),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () => _launchURL(video.url),
                child: Card(
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // YouTube thumbnail
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          'https://img.youtube.com/vi/${video.youtubeId}/maxresdefault.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              'https://img.youtube.com/vi/${video.youtubeId}/hqdefault.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      // Video title
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_circle_filled,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                video.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}