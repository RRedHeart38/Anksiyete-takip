import 'package:flutter/material.dart';

class SkeletonLoaderCard extends StatelessWidget {
  const SkeletonLoaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.white,
          radius: 24,
        ),
        title: Container(
          height: 16,
          width: MediaQuery.of(context).size.width * 0.5,
          color: Colors.white,
        ),
        subtitle: Container(
          height: 12,
          width: MediaQuery.of(context).size.width * 0.3,
          color: Colors.white,
        ),
      ),
    );
  }
}