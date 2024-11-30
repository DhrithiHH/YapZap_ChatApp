import 'package:flutter/material.dart';

class MediaViewPage extends StatelessWidget {
  final List<String> mediaUrls;

  const MediaViewPage({Key? key, required this.mediaUrls}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Media"),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return Scaffold(
                    appBar: AppBar(),
                    body: Center(
                      child: Image.network(mediaUrls[index]),
                    ),
                  );
                },
              ));
            },
            child: Image.network(mediaUrls[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
