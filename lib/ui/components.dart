import 'package:flutter/material.dart';
import 'design.dart';

class AppCard extends StatelessWidget {
  const AppCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(18),
      this.color = Colors.white});
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0c253044),
                  blurRadius: 12,
                  offset: Offset(0, 4))
            ]),
        child: child,
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.muted));
}

class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.trailing});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        if (onBack != null) ...[
          IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
              style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.ink)),
          const SizedBox(width: 9)
        ],
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(color: AppColors.muted, fontSize: 13))
        ])),
        if (trailing != null) trailing!,
      ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label,
      {super.key, required this.onPressed, this.color = AppColors.lime});
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.ink,
              disabledBackgroundColor: AppColors.line,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3),
          child: Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))));
}

class ChoiceGroup<T> extends StatelessWidget {
  const ChoiceGroup(
      {super.key,
      required this.options,
      required this.value,
      required this.onChanged,
      this.columns = 2});
  final List<T> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final int columns;
  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = option == value;
        return SizedBox(
            width: columns == 1
                ? double.infinity
                : columns == 2
                    ? 165
                    : 105,
            child: OutlinedButton(
                onPressed: () => onChanged(option),
                style: OutlinedButton.styleFrom(
                    backgroundColor: selected ? AppColors.lime : Colors.white,
                    foregroundColor: AppColors.ink,
                    side: BorderSide(
                        color: selected ? AppColors.lime : AppColors.line),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 9)),
                child: Text('$option',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700))));
      }).toList());
}

class MetricTile extends StatelessWidget {
  const MetricTile(this.label, this.value,
      {super.key, this.unit = '', this.icon = Icons.monitor_heart_outlined});
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AppCard(
      padding: const EdgeInsets.all(13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12))
        ]),
        const Divider(height: 13),
        RichText(
            text: TextSpan(children: [
          TextSpan(
              text: value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          TextSpan(
              text: unit,
              style: const TextStyle(fontSize: 13, color: AppColors.muted))
        ])),
        const Text('Latest available',
            style: TextStyle(fontSize: 11, color: AppColors.muted))
      ]));
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.status, {super.key});
  final String label;
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = status == 'READY'
        ? AppColors.teal
        : status == 'CAUTION'
            ? AppColors.amber
            : status == 'RESTRICTED'
                ? AppColors.red
                : AppColors.muted;
    return Row(children: [
      Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
      Text(status == 'INSUFFICIENT_DATA' ? 'No data' : status.toLowerCase(),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: color))
    ]);
  }
}

class NavBar extends StatelessWidget {
  const NavBar({super.key, required this.current, required this.go});
  final String current;
  final ValueChanged<String> go;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _item('today', 'Today', Icons.home_outlined),
          _item('training', 'Training', Icons.sports_mma_outlined),
          _item('nutrition', 'Food', Icons.restaurant_outlined),
          _item('camp', 'Camp', Icons.flag_outlined),
          _item('settings', 'Settings', Icons.settings_outlined),
        ]),
      );
  Widget _item(String key, String label, IconData icon) => InkWell(
      onTap: () => go(key),
      child: SizedBox(
          width: 65,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 23,
                color: current == key ? AppColors.ink : AppColors.muted),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: current == key ? AppColors.ink : AppColors.muted))
          ])));
}

class FieldTitle extends StatelessWidget {
  const FieldTitle(this.title, {super.key, this.helper});
  final String title;
  final String? helper;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel(title),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted))
        ],
        const SizedBox(height: 10)
      ]);
}
