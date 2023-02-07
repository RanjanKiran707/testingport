import 'dart:typed_data';

import 'package:flutter/material.dart';
import "package:image/image.dart" as img;

List<int> toRasterFormat(img.Image imgSrc) {
  final img.Image image = img.Image.from(imgSrc); // make a copy
  final int widthPx = image.width;
  final int heightPx = image.height;

  img.grayscale(image);

  img.invert(image);

  // R/G/B channels are same -> keep only one channel
  final List<int> oneChannelBytes = [];
  final List<int> buffer = image.getBytes(format: img.Format.rgba);

  for (int i = 0; i < buffer.length; i += 4) {
    oneChannelBytes.add(buffer[i]);
  }

  // Add some empty pixels at the end of each line (to make the width divisible by 8)
  if (widthPx % 8 != 0) {
    final targetWidth = (widthPx + 8) - (widthPx % 8);
    final missingPx = targetWidth - widthPx;
    final extra = Uint8List(missingPx);
    for (int i = 0; i < heightPx; i++) {
      final pos = (i * widthPx + widthPx) + i * missingPx;
      oneChannelBytes.insertAll(pos, extra);
    }
  }

  // Pack bits into bytes
  return _packBitsIntoBytes(oneChannelBytes);
}

/// Merges each 8 values (bits) into one byte
List<int> _packBitsIntoBytes(List<int> bytes) {
  const pxPerLine = 8;
  final List<int> res = <int>[];
  const threshold = 127; // set the greyscale -> b/w threshold here
  for (int i = 0; i < bytes.length; i += pxPerLine) {
    int newVal = 0;
    for (int j = 0; j < pxPerLine; j++) {
      newVal = _transformUint32Bool(
        newVal,
        pxPerLine - j,
        bytes[i + j] > threshold,
      );
    }
    res.add(newVal ~/ 2);
  }
  return res;
}

/// Replaces a single bit in a 32-bit unsigned integer.
int _transformUint32Bool(int uint32, int shift, bool newValue) {
  return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) |
      ((newValue ? 1 : 0) << shift);
}
