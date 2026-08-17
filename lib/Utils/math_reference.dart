import 'package:flutter/material.dart';

const kMathReferenceAsset = 'assets/math/sat_math_reference.png';

class MathReferenceItem {
  final String text;
  final IconData icon;

  const MathReferenceItem({required this.text, required this.icon});
}

/// Official Digital SAT / Bluebook math reference sheet (geometry only).
const kMathReferenceItems = <MathReferenceItem>[
  MathReferenceItem(
    text: 'Area of a circle: A = πr²',
    icon: Icons.circle_outlined,
  ),
  MathReferenceItem(
    text: 'Circumference of a circle: C = 2πr',
    icon: Icons.circle_outlined,
  ),
  MathReferenceItem(
    text: 'Area of a rectangle: A = lw',
    icon: Icons.rectangle_outlined,
  ),
  MathReferenceItem(
    text: 'Area of a triangle: A = ½bh',
    icon: Icons.change_history_rounded,
  ),
  MathReferenceItem(
    text: 'Pythagorean theorem: a² + b² = c²',
    icon: Icons.change_history_rounded,
  ),
  MathReferenceItem(
    text: 'Special right triangle (30-60-90): sides in ratio x : x√3 : 2x',
    icon: Icons.change_history_rounded,
  ),
  MathReferenceItem(
    text: 'Special right triangle (45-45-90): sides in ratio s : s : s√2',
    icon: Icons.change_history_rounded,
  ),
  MathReferenceItem(
    text: 'Volume of a rectangular solid: V = lwh',
    icon: Icons.view_in_ar_outlined,
  ),
  MathReferenceItem(
    text: 'Volume of a cylinder: V = πr²h',
    icon: Icons.view_in_ar_outlined,
  ),
  MathReferenceItem(
    text: 'Volume of a sphere: V = (4/3)πr³',
    icon: Icons.view_in_ar_outlined,
  ),
  MathReferenceItem(
    text: 'Volume of a cone: V = (1/3)πr²h',
    icon: Icons.view_in_ar_outlined,
  ),
  MathReferenceItem(
    text: 'Volume of a pyramid: V = (1/3)lwh',
    icon: Icons.view_in_ar_outlined,
  ),
  MathReferenceItem(
    text: 'A circle has 360 degrees of arc.',
    icon: Icons.circle_outlined,
  ),
  MathReferenceItem(
    text: 'A circle has 2π radians of arc.',
    icon: Icons.circle_outlined,
  ),
  MathReferenceItem(
    text: 'The angle measures of a triangle sum to 180 degrees.',
    icon: Icons.change_history_rounded,
  ),
];
