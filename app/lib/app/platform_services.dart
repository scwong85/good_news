import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a story's original page in the browser.
abstract class LinkOpener {
  /// Returns false when nothing could handle the link.
  Future<bool> open(Uri url);
}

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Opens the system share sheet with a headline and the link to the original.
abstract class Sharer {
  Future<void> share({required String title, required Uri url});
}

class SharePlusSharer implements Sharer {
  const SharePlusSharer();

  @override
  Future<void> share({required String title, required Uri url}) async {
    await SharePlus.instance.share(ShareParams(text: '$title\n$url', subject: title));
  }
}
