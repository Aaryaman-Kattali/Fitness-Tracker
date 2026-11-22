import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Hands files to the OS share sheet.
///
/// An interface over one plugin call, for the same reason `RunRecorder` is one
/// over tracelet: `share_plus` is a method channel and is not reachable in a
/// widget test, so without this the export screen could not be driven at all.
/// Nothing above this line imports `share_plus`.
// A class rather than the typedef one_member_abstracts wants. It sits in
// `data/repositories/` alongside RunRecorder and HealthConnectRepository and
// is overridden in tests the same way; a bare function type here would make
// this one platform boundary look unlike the other two for no gain.
// ignore: one_member_abstracts
abstract interface class FileSharer {
  /// Offer [paths] to the share sheet. Returns false if the user dismissed it
  /// without choosing anything.
  ///
  /// Dismissal is not an error and must not be reported as one — backing out
  /// of a share sheet is the ordinary way to change your mind.
  Future<bool> share(List<String> paths, {required String subject});
}

class SharePlusFileSharer implements FileSharer {
  const SharePlusFileSharer();

  @override
  Future<bool> share(List<String> paths, {required String subject}) async {
    // Existence is checked here rather than trusted. The list comes from a
    // directory read that happened when the screen was drawn, and a delete on
    // another row between then and now would otherwise reach the plugin as a
    // missing-file crash on a debug screen.
    final files = [
      for (final path in paths)
        if (File(path).existsSync()) XFile(path),
    ];
    if (files.isEmpty) return false;

    final result = await SharePlus.instance.share(
      ShareParams(files: files, subject: subject),
    );
    return result.status == ShareResultStatus.success;
  }
}
