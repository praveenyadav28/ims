import 'package:flutter/material.dart';
import 'package:ims/utils/colors.dart';

class GlobalHeaderCard extends StatelessWidget {
  const GlobalHeaderCard({
    super.key,
    required this.billTo,
    required this.shipTo,
    required this.details,
  });

  final Widget billTo;
  final Widget shipTo;
  final Widget details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 30),
              Expanded(child: billTo),
              const SizedBox(width: 60),
              Expanded(child: shipTo),
              const SizedBox(width: 60),
              Expanded(child: details),
              const SizedBox(width: 30),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: AppColor.black.withValues(alpha: .45),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
