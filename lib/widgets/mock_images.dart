import 'package:flutter/material.dart';
import 'package:todo_app/utils/colors.dart';

class MockImages {
  static Widget checkedBox() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: CustomColors.GreenIcon,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  static Widget uncheckedBox() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(
          color: CustomColors.GreyBorder,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  static Widget categoryIcon(IconData icon, Color backgroundColor) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        icon,
        size: 30,
        color: CustomColors.TextHeader,
      ),
    );
  }

  // Category Icons
  static Widget userIcon() => categoryIcon(Icons.person, CustomColors.YellowBackground);
  static Widget workIcon() => categoryIcon(Icons.work, CustomColors.GreenBackground);
  static Widget meetingIcon() => categoryIcon(Icons.groups, CustomColors.PurpleBackground);
  static Widget shoppingIcon() => categoryIcon(Icons.shopping_basket, CustomColors.OrangeBackground);
  static Widget partyIcon() => categoryIcon(Icons.celebration, CustomColors.BlueBackground);
  static Widget studyIcon() => categoryIcon(Icons.school, CustomColors.PurpleBackground);

  // Bell Icons
  static Widget bellIcon({bool isActive = false}) {
    return Icon(
      Icons.notifications,
      color: isActive ? CustomColors.YellowBell : CustomColors.BellGrey,
      size: 20,
    );
  }

  static Widget bellIconSmall({bool isActive = false}) {
    return Icon(
      Icons.notifications,
      color: isActive ? CustomColors.YellowBell : CustomColors.BellGrey,
      size: 16,
    );
  }

  // Add Task Button
  static Widget addTaskIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CustomColors.PurpleLight, CustomColors.PurpleDark],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CustomColors.PurpleShadow,
            blurRadius: 10.0,
            spreadRadius: 5.0,
            offset: Offset(0.0, 0.0),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  // Delete Task Button
  static Widget deleteTaskIcon() {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: CustomColors.TrashRedBackground,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        Icons.delete_outline,
        color: CustomColors.TrashRed,
        size: 20,
      ),
    );
  }
} 