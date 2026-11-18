import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_client.dart';
import 'cloud_library.dart';

/// Features appear only after the existing server advertises the versioned contract.
class ServerFeatureTile extends StatelessWidget {
  const ServerFeatureTile({
    super.key,
    required this.api,
    required this.feature,
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final MitvApi api;
  final String feature, title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FutureBuilder<Set<String>>(
    future: api.clientFeatures(),
    builder: (context, snapshot) => snapshot.data?.contains(feature) == true
        ? ListTile(leading: Icon(icon), title: Text(title), onTap: onTap)
        : const SizedBox.shrink(),
  );
}

Future<void> showQuickWatchLink(
  BuildContext context,
  MitvApi api,
  String ref, {
  int? season,
  int? episode,
}) async {
  String message;
  try {
    final client = await CloudLibrarySync.authenticationClient();
    if (!hasRegisteredNajdAccount(client)) throw StateError('ACCOUNT_REQUIRED');
    final owner = client.auth.currentUser!.id;
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw StateError('ACCOUNT_REQUIRED');
    final link = await api.createQuickWatchLink(
      ref,
      bearer: token,
      season: season,
      episode: episode,
    );
    if (client.auth.currentUser?.id != owner ||
        !hasRegisteredNajdAccount(client)) {
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رابط المشاهدة السريعة'),
        content: SelectableText(link.toString()),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link.toString()));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('نسخ الرابط'),
          ),
        ],
      ),
    );
    return;
  } catch (_) {
    message = 'تعذر إنشاء الرابط. تأكد من تسجيل الدخول وحاول مجددًا.';
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
