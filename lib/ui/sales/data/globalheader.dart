import 'package:flutter/material.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';

class GlobalHeaderCard extends StatelessWidget {
  const GlobalHeaderCard({
    super.key,
    required this.billTo,
    required this.shipTo,
    required this.details,
    this.flex1,
    this.flex2,
    this.flex3,
  });

  final Widget billTo;
  final Widget shipTo;
  final Widget details;
  final int? flex1;
  final int? flex2;
  final int? flex3;
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
              Expanded(flex: flex1 ?? 1, child: billTo),
              const SizedBox(width: 50),
              Expanded(flex: flex2 ?? 1, child: shipTo),
              const SizedBox(width: 50),
              Expanded(flex: flex3 ?? 1, child: details),
            ],
          ),

          // SizedBox(height: Sizes.height * .035),
          // Row(
          //   children: List.generate(3, (index) {
          //     return Expanded(
          //       flex: index == 0
          //           ? flex1 ?? 1
          //           : index == 1
          //           ? flex2 ?? 1
          //           : flex3 ?? 1,
          //       child: Container(
          //         margin: EdgeInsets.symmetric(horizontal: 10),
          //         height: 3,
          //         decoration: BoxDecoration(
          //           borderRadius: BorderRadius.circular(5),
          //           color: AppColor.black.withValues(alpha: .45),
          //         ),
          //       ),
          //     );
          //   }),
          // ),
        ],
      ),
    );
  }
}
