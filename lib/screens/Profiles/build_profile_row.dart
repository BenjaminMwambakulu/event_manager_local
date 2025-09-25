import 'package:event_manager_local/models/profile.dart';
import 'package:event_manager_local/utils/image_utils.dart';
import 'package:flutter/material.dart';

Widget buildProfileRow(Profile profile) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: profile.profileUrl.isNotEmpty
                ? ImageUtils.cachedNetworkImage(
                    imageUrl: profile.profileUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/profile.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(width: 20),
          // Profile Information
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.username,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                profile.email ?? 'No Email',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
