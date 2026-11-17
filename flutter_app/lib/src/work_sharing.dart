import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_library.dart';
import 'cloud_runtime_stub.dart' if (dart.library.io) 'cloud_runtime_io.dart';
import 'library_store.dart';
import 'library_sync_record.dart';

typedef ShareRpc = Future<dynamic> Function(
  String name,
  Map<String, dynamic> params,
);

class SharedWork {
  SharedWork(this.id, this.sender, this.recipient, this.entry);
  final String id, sender, recipient;
  final WatchEntry entry;
  factory SharedWork.fromJson(Map row) {
    final payload = Map<String, dynamic>.from(row['payload'] as Map);
    final entry = WatchEntry.fromJson(payload);
    final record = LibrarySyncRecord(
      kind: 'history',
      itemKey: entry.contentRef,
      metadata: payload,
      updatedAt: DateTime.now(),
    );
    if (!record.fitsCloudBudget ||
        entry.contentRef.isEmpty ||
        entry.title.isEmpty ||
        (!WorkSharing.validId('${row['id']}') ||
            !WorkSharing.validId('${row['sender_id']}') ||
            !WorkSharing.validId('${row['recipient_id']}'))) {
      throw const FormatException('INVALID_SHARED_WORK');
    }
    return SharedWork(
      '${row['id']}',
      '${row['sender_id']}',
      '${row['recipient_id']}',
      entry,
    );
  }
}

class WorkSharing {
  WorkSharing({ShareRpc? rpc}) : _rpc = rpc ?? _authenticatedRpc;
  final ShareRpc _rpc;
  static bool validId(String value) =>
      RegExp(r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$')
          .hasMatch(value);
  static Future<dynamic> _authenticatedRpc(
    String name,
    Map<String, dynamic> params,
  ) async {
    final client = await CloudLibrarySync.authenticationClient();
    if (!hasRegisteredNajdAccount(client)) {
      throw StateError('REGISTERED_ACCOUNT_REQUIRED');
    }
    final owner = client.auth.currentUser!.id;
    final result = await client
        .rpc(name, params: params)
        .timeout(const Duration(seconds: 12));
    if (client.auth.currentUser?.id != owner ||
        !hasRegisteredNajdAccount(client)) {
      throw StateError('SHARE_ACCOUNT_CHANGED');
    }
    return result;
  }

  Future<void> send(String recipient, WatchEntry entry) async {
    final payload = entry.toJson();
    final record = LibrarySyncRecord(
      kind: 'history',
      itemKey: entry.contentRef,
      metadata: payload,
      updatedAt: DateTime.now(),
    );
    if (!validId(recipient) ||
        entry.contentRef.isEmpty ||
        !record.fitsCloudBudget) {
      throw const FormatException('INVALID_SHARE_REQUEST');
    }
    final result = await _rpc('najd_share_work', {
      'p_recipient': recipient,
      'p_payload': payload,
    });
    if (!validId('$result')) {
      throw const FormatException('INVALID_SHARE_RECEIPT');
    }
  }

  Future<List<SharedWork>> _list(String method) async {
    final result = await _rpc(method, {});
    if (result is! List) throw const FormatException('INVALID_SHARE_RESPONSE');
    return result.whereType<Map>().map(SharedWork.fromJson).toList();
  }

  Future<List<SharedWork>> inbox() => _list('najd_share_inbox');
  Future<List<SharedWork>> accepted() => _list('najd_shared_works');
  Future<void> respond(String id, bool accept) async {
    if (!validId(id)) throw const FormatException('INVALID_SHARE_ID');
    final result = await _rpc('najd_share_respond', {
      'p_id': id,
      'p_accept': accept,
    });
    if (result != true) throw StateError('SHARE_NOT_ACKNOWLEDGED');
  }
}

Future<void> showShareWork(
  BuildContext context,
  WatchEntry entry, {
  WorkSharing? transport,
}) async {
  final recipient = await showDialog<String>(
    context: context,
    builder: (_) => const _ShareRecipientDialog(),
  );
  if (recipient == null || !context.mounted) return;
  try {
    await (transport ?? WorkSharing()).send(recipient, entry);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أُرسلت المشاركة؛ يختار المستلم قبولها أو رفضها.'),
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إرسال المشاركة. تحقق من معرّف الحساب وتسجيل الدخول.',
          ),
        ),
      );
    }
  }
}

class _ShareRecipientDialog extends StatefulWidget {
  const _ShareRecipientDialog();
  @override
  State<_ShareRecipientDialog> createState() => _ShareRecipientDialogState();
}

class _ShareRecipientDialogState extends State<_ShareRecipientDialog> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('مشاركة مع حساب نجد'),
    content: TextField(
      controller: input,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: 'معرّف حساب المستلم',
        helperText: 'ينسخه المستلم من صفحة حسابه.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, input.text.trim()),
        child: const Text('إرسال'),
      ),
    ],
  );
}

class SharedLibraryPage extends StatefulWidget {
  const SharedLibraryPage({super.key, required this.onOpen, this.transport});
  final void Function(WatchEntry) onOpen;
  final WorkSharing? transport;
  @override
  State<SharedLibraryPage> createState() => _SharedLibraryPageState();
}

class _SharedLibraryPageState extends State<SharedLibraryPage> {
  late Future<List<SharedWork>> rows;
  @override
  void initState() {
    super.initState();
    rows = (widget.transport ?? WorkSharing()).accepted();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('القائمة المشتركة')),
    body: FutureBuilder<List<SharedWork>>(
      future: rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => rows = (widget.transport ?? WorkSharing()).accepted(),
              ),
              child: const Text(
                'تعذر جلب القائمة. سجّل الدخول أو أعد المحاولة.',
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text('المشاركات المقبولة تظهر هنا. قائمتك الشخصية مستقلة.'),
          );
        }
        return ListView(
          children: [
            for (final row in snapshot.data!)
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(row.entry.title),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => widget.onOpen(row.entry),
              ),
          ],
        );
      },
    ),
  );
}

/// A durable inbox; background/inactive tabs never show or acknowledge a request.
class WorkShareInbox extends StatefulWidget {
  const WorkShareInbox({
    super.key,
    required this.child,
    required this.onOpen,
    this.transport,
  });
  final Widget child;
  final void Function(WatchEntry) onOpen;
  final WorkSharing? transport;
  @override
  State<WorkShareInbox> createState() => _WorkShareInboxState();
}

class _WorkShareInboxState extends State<WorkShareInbox>
    with WidgetsBindingObserver {
  RealtimeChannel? channel;
  String? boundOwner;
  BuildContext? inboxDialog;
  SupabaseClient? realtimeClient;
  StreamSubscription<AuthState>? authChanges;
  Future<void> connect() async {
    try {
      final client = await CloudLibrarySync.authenticationClient();
      if (!mounted) return;
      realtimeClient = client;
      void bind() {
        final uid = hasRegisteredNajdAccount(client)
            ? client.auth.currentUser!.id
            : null;
        if (uid == boundOwner && channel != null) return;
        final oldDialog = inboxDialog;
        if (boundOwner != uid && oldDialog != null && oldDialog.mounted) {
          final route = ModalRoute.of(oldDialog);
          if (route != null) Navigator.of(oldDialog).removeRoute(route);
        }
        boundOwner = uid;
        final old = channel;
        channel = null;
        if (old != null) unawaited(client.removeChannel(old));
        seen.clear();
        if (!mounted || uid == null) return;
        channel = client
            .channel('najd-work-shares-$uid')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'najd_work_shares',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'recipient_id',
                value: uid,
              ),
              callback: (_) => unawaited(tick()),
            )
            .subscribe();
        unawaited(tick());
      }

      bind();
      authChanges = client.auth.onAuthStateChange.listen((_) => bind());
    } catch (_) {
      // The durable polling inbox remains available when Realtime cannot connect.
    }
  }

  late final bridge = widget.transport ?? WorkSharing();
  Timer? timer;
  bool busy = false, active = true;
  final seen = <String>{};
  @override
  void initState() {
    super.initState();
    if (widget.transport == null &&
        (cloudRuntimeIsTest || const bool.fromEnvironment('FLUTTER_TEST'))) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    if (widget.transport == null) unawaited(connect());
    unawaited(tick());
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(tick()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    if (active) unawaited(tick());
  }

  Future<void> tick() async {
    if (busy || !active || !mounted) return;
    busy = true;
    try {
      final rows = await bridge.inbox();
      if (!active || !mounted) return;
      final unseen = rows.where((row) => !seen.contains(row.id));
      if (unseen.isEmpty) return;
      final row = unseen.first;
      seen.add(row.id);
      if (seen.length > 128) seen.remove(seen.first);
      final accept = await showDialog<bool>(
        context: context,
        builder: (context) {
          inboxDialog = context;
          return AlertDialog(
            title: const Text('وصلتك مشاركة'),
            content: Text(row.entry.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('رفض'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('قبول وفتح'),
              ),
            ],
          );
        },
      );
      inboxDialog = null;
      if (accept == null || !mounted || !active) {
        seen.remove(row.id);
        return;
      }
      await bridge.respond(row.id, accept);
      if (accept && mounted && active) widget.onOpen(row.entry);
    } catch (_) {
      // Durable pending rows remain available after networking/auth recovery.
      seen.clear();
    } finally {
      busy = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    unawaited(authChanges?.cancel());
    final current = channel;
    if (current != null && realtimeClient != null) {
      unawaited(realtimeClient!.removeChannel(current));
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
