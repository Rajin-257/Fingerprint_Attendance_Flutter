import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  
  const LogoWidget({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for a custom logo
    // Replace with your actual logo widget
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.school,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}