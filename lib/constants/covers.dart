import "package:path/path.dart" as path;

class Covers {
  static String getLocalCover() {
    return Covers.local[0];
  }

  static List<String> local = [
    path.join("assets", "images", "cover-1.jpg"),
  ];
}
