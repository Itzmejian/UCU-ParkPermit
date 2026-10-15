import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'status_badge.dart';

enum TimelineState { done, current, pending, info }

class TimelineItem {
  const TimelineItem({
    required this.title,
    required this.subtitle,
    required this.state,
    this.tag,
    this.chips = const [],
  });

  final String title;
  final String subtitle;
  final TimelineState state;
  final String? tag;
  final List<String> chips;
}

class StepTimeline extends StatelessWidget {
  const StepTimeline({super.key, required this.items});

  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _row(items[i], i, i == items.length - 1),
      ],
    );
  }

  Widget _row(TimelineItem item, int index, bool last) {
    final pending = item.state == TimelineState.pending;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                _Dot(state: item.state, number: index + 1),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: item.state == TimelineState.done
                          ? AppColors.navy
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: pending ? AppColors.textHint : AppColors.navy,
                        ),
                      ),
                      if (item.tag != null) StatusBadge(text: item.tag!),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: pending ? AppColors.textHint : AppColors.textMuted,
                    ),
                  ),
                  if (item.chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in item.chips) _MiniChip(text: c),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.number});

  final TimelineState state;
  final int number;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Widget inner;
    switch (state) {
      case TimelineState.done:
        bg = AppColors.navy;
        border = AppColors.navy;
        inner = const Icon(Icons.check, size: 16, color: Colors.white);
        break;
      case TimelineState.current:
        bg = AppColors.goldLight;
        border = AppColors.gold;
        inner = Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.goldDark,
          ),
        );
        break;
      case TimelineState.pending:
        bg = AppColors.inputFill;
        border = AppColors.border;
        inner = Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textHint,
          ),
        );
        break;
      case TimelineState.info:
        bg = AppColors.navy;
        border = AppColors.navy;
        inner = Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );
        break;
    }
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: inner,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}