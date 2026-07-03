import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notifikasi_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/loading_indicator.dart';

class ListNotifikasiScreen extends StatefulWidget {
  const ListNotifikasiScreen({super.key});

  @override
  State<ListNotifikasiScreen> createState() => _ListNotifikasiScreenState();
}

class _ListNotifikasiScreenState extends State<ListNotifikasiScreen> {
  String filter = "semua";
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated && auth.user != null) {
        Provider.of<NotifikasiProvider>(context, listen: false)
            .fetchNotifikasi(auth.user!.id);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> getNotifIconAndColor(String judul) {
    final title = judul.toLowerCase();
    if (title.contains("masuk")) {
      return {
        'icon': Icons.inventory_2_outlined,
        'bgColor': TirtaTheme.greenSoft,
        'textColor': TirtaTheme.green,
      };
    }
    if (title.contains("keluar")) {
      return {
        'icon': Icons.keyboard_arrow_down_outlined,
        'bgColor': TirtaTheme.redSoft,
        'textColor': TirtaTheme.rose,
      };
    }
    if (title.contains("pengajuan")) {
      return {
        'icon': Icons.description_outlined,
        'bgColor': TirtaTheme.blueSoft,
        'textColor': TirtaTheme.primaryBlue,
      };
    }
    if (title.contains("minimum")) {
      return {
        'icon': Icons.warning_amber_outlined,
        'bgColor': TirtaTheme.orangeSoft,
        'textColor': TirtaTheme.orange,
      };
    }
    return {
      'icon': Icons.notifications_outlined,
      'bgColor': TirtaTheme.blueSoft,
      'textColor': TirtaTheme.primaryBlue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final notifProv = Provider.of<NotifikasiProvider>(context);

    final filteredNotif = notifProv.notifikasiList.where((n) {
      final matchFilter = filter == "semua"
          ? true
          : filter == "unread"
              ? n.isRead == 0
              : n.isRead == 1;

      final matchSearch = searchQuery.isEmpty ||
          n.judul.toLowerCase().contains(searchQuery.toLowerCase()) ||
          n.pesan.toLowerCase().contains(searchQuery.toLowerCase());

      return matchFilter && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: themeProv.isDarkMode
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: theme.colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Notifikasi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Semua riwayat pembaruan sistem dan status persetujuan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notifProv.unreadCount > 0)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            TirtaTheme.primaryBlue,
                            TirtaTheme.skyBlue,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                TirtaTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.done_all_outlined,
                            color: Colors.white, size: 24),
                        onPressed: () =>
                            notifProv.markAllAsRead(authProv.user!.id),
                      ),
                    ),
                ],
              ),
            ),
            // Toolbar
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  if (auth.isAuthenticated && auth.user != null) {
                    await Provider.of<NotifikasiProvider>(context, listen: false)
                        .fetchNotifikasi(auth.user!.id);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search and Filter
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: themeProv.isDarkMode
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          // Search
                          TextField(
                            controller: searchController,
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari notifikasi...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              prefixIcon: Icon(Icons.search_outlined,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6)),
                              filled: true,
                              fillColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Filter Tabs
                          Row(
                            children: [
                              for (final tab in [
                                {'id': 'semua', 'label': 'Semua'},
                                {'id': 'unread', 'label': 'Belum Dibaca'},
                                {'id': 'read', 'label': 'Sudah Dibaca'}
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        filter = tab['id'] as String;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: filter == tab['id']
                                              ? (themeProv.isDarkMode
                                                  ? TirtaTheme.primaryBlue
                                                      .withValues(alpha: 0.2)
                                                  : TirtaTheme.blueSoft)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          tab['label'] as String,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: filter == tab['id']
                                                ? (themeProv.isDarkMode
                                                    ? TirtaTheme.skyBlue
                                                    : TirtaTheme.primaryBlue)
                                                : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Notif List
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: [
                          BoxShadow(
                            color: themeProv.isDarkMode
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: notifProv.isLoading
                          ? const SizedBox(
                              height: 300,
                              child: Center(
                                child: LoadingIndicator(
                                    message: 'Memuat notifikasi...'),
                              ),
                            )
                          : filteredNotif.isEmpty
                              ? SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.notifications_off_outlined,
                                            size: 70,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.2)),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tidak ada notifikasi',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          searchQuery.isNotEmpty
                                              ? 'Tidak ada notifikasi yang cocok dengan pencarian Anda'
                                              : 'Anda belum memiliki riwayat notifikasi di kategori ini',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredNotif.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final notif = filteredNotif[index];
                                    final isUnread = notif.isRead == 0;
                                    final ui =
                                        getNotifIconAndColor(notif.judul);

                                    return GestureDetector(
                                      onTap: () {
                                        if (isUnread) {
                                          notifProv.markAsRead(notif.id);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 22),
                                        decoration: BoxDecoration(
                                          gradient: isUnread
                                              ? LinearGradient(
                                                  colors: [
                                                    (themeProv.isDarkMode
                                                            ? TirtaTheme
                                                                .primaryBlue
                                                            : TirtaTheme
                                                                .primaryBlue)
                                                        .withValues(
                                                            alpha: 0.18),
                                                    (themeProv.isDarkMode
                                                            ? TirtaTheme.skyBlue
                                                            : TirtaTheme
                                                                .skyBlue)
                                                        .withValues(
                                                            alpha: 0.12),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isUnread
                                              ? null
                                              : (themeProv.isDarkMode
                                                  ? Colors.transparent
                                                  : Colors.grey.shade50),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: isUnread
                                              ? [
                                                  BoxShadow(
                                                    color: (themeProv.isDarkMode
                                                            ? TirtaTheme
                                                                .primaryBlue
                                                            : TirtaTheme
                                                                .primaryBlue)
                                                        .withValues(
                                                            alpha: themeProv
                                                                    .isDarkMode
                                                                ? 0.08
                                                                : 0.15),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Icon
                                            Container(
                                              width: 58,
                                              height: 58,
                                              decoration: BoxDecoration(
                                                color: ui['bgColor'] as Color,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Icon(
                                                ui['icon'] as IconData,
                                                size: 28,
                                                color: ui['textColor'] as Color,
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            // Content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          notif.judul,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: isUnread
                                                                ? FontWeight
                                                                    .w800
                                                                : FontWeight
                                                                    .w700,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (isUnread)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: themeProv
                                                                    .isDarkMode
                                                                ? TirtaTheme
                                                                    .primaryBlue
                                                                    .withValues(
                                                                        alpha:
                                                                            0.2)
                                                                : TirtaTheme
                                                                    .blueSoft,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        24),
                                                          ),
                                                          child: Text(
                                                            'Baru',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              color: themeProv
                                                                      .isDarkMode
                                                                  ? TirtaTheme
                                                                      .skyBlue
                                                                  : TirtaTheme
                                                                      .primaryBlue,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    notif.pesan,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: isUnread
                                                          ? FontWeight.w500
                                                          : FontWeight.w400,
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    DateFormat(
                                                      "dd MMMM yyyy 'PUKUL' HH.mm",
                                                      'id_ID',
                                                    )
                                                        .format(
                                                          DateTime.parse(notif
                                                                  .createdAt)
                                                              .toLocal(),
                                                        )
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.45),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Actions
                                            Row(
                                              children: [
                                                if (isUnread)
                                                  IconButton(
                                                    onPressed: () => notifProv
                                                        .markAsRead(notif.id),
                                                    icon: Icon(
                                                      Icons
                                                          .check_circle_outlined,
                                                      color: TirtaTheme
                                                          .primaryBlue,
                                                      size: 22,
                                                    ),
                                                  ),
                                                IconButton(
                                                  onPressed: () => notifProv
                                                      .deleteNotifikasi(
                                                          notif.id),
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_outlined,
                                                    color: TirtaTheme.rose,
                                                    size: 22,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
