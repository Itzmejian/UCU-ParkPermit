import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Opens a tall bottom sheet with a search box and a long list of options.
/// [subtitles] can add a smaller line under an option (it is searchable too).
/// Returns the chosen option, or null when it is closed.
Future<String?> showSearchSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  String searchHint = 'Search',
  Map<String, String>? subtitles,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SearchSheet(
      title: title,
      options: options,
      selected: selected,
      searchHint: searchHint,
      subtitles: subtitles ?? const <String, String>{},
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchHint,
    required this.subtitles,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final String searchHint;
  final Map<String, String> subtitles;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _query = '';

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  bool _matches(String option, String q) {
    if (option.toLowerCase().contains(q)) return true;
    final sub = widget.subtitles[option];
    return sub != null && sub.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.options
        : widget.options.where((o) => _matches(o, q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: _border(AppColors.border, 1),
                  enabledBorder: _border(AppColors.border, 1),
                  focusedBorder: _border(AppColors.navy, 1.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No match found.',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final o = items[index];
                        final sel = o == widget.selected;
                        final sub = widget.subtitles[o];
                        return ListTile(
                          title: Text(
                            o,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: sub == null
                              ? null
                              : Text(
                                  sub,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                          trailing: sel
                              ? const Icon(Icons.check_circle, color: AppColors.navy)
                              : null,
                          onTap: () => Navigator.pop(context, o),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}