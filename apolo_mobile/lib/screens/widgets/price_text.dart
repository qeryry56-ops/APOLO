import 'package:flutter/material.dart';

/// Isolates a complete price from the surrounding paragraph's bidi ordering.
/// Arabic layouts keep start alignment; amounts and currency read left-to-right.
/// Scales down only when necessary, never truncating the amount.
class PriceText extends StatelessWidget {
  final String price;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const PriceText(this.price,
      {super.key,
      this.style,
      this.maxLines = 1,
      this.overflow = TextOverflow.clip});

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final alignment = AlignmentDirectional.centerStart.resolve(direction);
    final priceDirection =
        RegExp(r'[0-9٠-٩۰-۹]').hasMatch(price) ? TextDirection.ltr : direction;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final resolvedStyle =
        (baseStyle.fontFeatures == null || baseStyle.fontFeatures!.isEmpty)
            ? baseStyle.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              )
            : baseStyle;
    return Align(
      alignment: alignment,
      widthFactor: 1,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          price,
          textDirection: priceDirection,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: false,
          style: resolvedStyle,
        ),
      ),
    );
  }
}
