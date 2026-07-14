import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

void main() {
  FTextField(
    prefixBuilder: (context, style, widget) => const SizedBox(),
    suffixBuilder: (context, style, widget) => const SizedBox(),
    hint: 'test',
  );
}
