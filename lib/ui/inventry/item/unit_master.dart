// import 'package:flutter/material.dart';
// import 'package:ims/component/side_menu.dart';

// class MeasuringUnitScreen extends StatefulWidget {
//   const MeasuringUnitScreen({super.key});

//   @override
//   State<MeasuringUnitScreen> createState() => _MeasuringUnitScreenState();
// }

// class _MeasuringUnitScreenState extends State<MeasuringUnitScreen> {
//   String? baseUnit;
//   String? secondaryUnit;
//   double conversionValue = 0;

//   final TextEditingController _controller = TextEditingController();

//   // 🔹 Grouped Units with conversions
//   final Map<String, Map<String, double>> conversionMap = {
//     // Length
//     'Millimeter (mm)': {
//       'Centimeter (cm)': 0.1,
//       'Meter (m)': 0.001,
//       'Kilometer (km)': 0.000001,
//       'Inch (in)': 0.03937,
//       'Foot (ft)': 0.003281,
//     },
//     'Centimeter (cm)': {
//       'Millimeter (mm)': 10,
//       'Meter (m)': 0.01,
//       'Kilometer (km)': 0.00001,
//       'Inch (in)': 0.3937,
//     },
//     'Meter (m)': {
//       'Millimeter (mm)': 1000,
//       'Centimeter (cm)': 100,
//       'Kilometer (km)': 0.001,
//       'Inch (in)': 39.37,
//       'Foot (ft)': 3.2808,
//     },
//     'Kilometer (km)': {
//       'Meter (m)': 1000,
//       'Centimeter (cm)': 100000,
//       'Mile (mi)': 0.62137,
//     },

//     // Weight
//     'Gram (g)': {
//       'Kilogram (kg)': 0.001,
//       'Milligram (mg)': 1000,
//       'Pound (lb)': 0.0022046,
//     },
//     'Kilogram (kg)': {
//       'Gram (g)': 1000,
//       'Pound (lb)': 2.2046,
//       'Ounce (oz)': 35.274,
//     },
//     'Pound (lb)': {
//       'Gram (g)': 453.592,
//       'Kilogram (kg)': 0.4536,
//       'Ounce (oz)': 16,
//     },

//     // Volume
//     'Liter (l)': {
//       'Milliliter (ml)': 1000,
//       'Gallon (gal)': 0.264172,
//       'Pint (pt)': 2.11338,
//     },
//     'Milliliter (ml)': {'Liter (l)': 0.001},
//     'Gallon (gal)': {'Liter (l)': 3.78541},

//     // Area
//     'Square m (m²)': {
//       'Square cm (cm²)': 10000,
//       'Hectare (ha)': 0.0001,
//       'Acre': 0.000247,
//     },
//     'Hectare (ha)': {'Square m (m²)': 10000, 'Acre': 2.47105},

//     // Quantity
//     'Piece (Pc)': {'Dozen (Dzn)': 1 / 12, 'Box (Box)': 1 / 24},
//     'Dozen (Dzn)': {'Piece (Pc)': 12, 'Box (Box)': 0.5},
//     'Box (Box)': {'Piece (Pc)': 24, 'Dozen (Dzn)': 2},
//     'Packet (Pkt)': {'Piece (Pc)': 10},
//     'Pair (Pr)': {'Piece (Pc)': 2},
//   };

//   List<String> get relatedUnits {
//     if (baseUnit == null) return [];
//     return conversionMap[baseUnit!]!.keys.toList();
//   }

//   void updateConversion() {
//     if (baseUnit != null && secondaryUnit != null) {
//       conversionValue = conversionMap[baseUnit!]?[secondaryUnit!] ?? 0;
//       _controller.text = conversionValue.toString();
//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(title: const Text('Measuring Unit'), centerTitle: true),
//       drawer: SideMenu(),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "Base Unit",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               decoration: const InputDecoration(border: OutlineInputBorder()),
//               value: baseUnit,
//               hint: const Text('Select Base Unit'),
//               items: conversionMap.keys
//                   .map(
//                     (unit) => DropdownMenuItem(value: unit, child: Text(unit)),
//                   )
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   baseUnit = value;
//                   secondaryUnit = null;
//                   conversionValue = 0;
//                   _controller.text = "";
//                 });
//               },
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Secondary Unit",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             DropdownButtonFormField<String>(
//               decoration: const InputDecoration(border: OutlineInputBorder()),
//               value: secondaryUnit,
//               hint: const Text('Select Secondary Unit'),
//               items: relatedUnits
//                   .map((u) => DropdownMenuItem(value: u, child: Text(u)))
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   secondaryUnit = value;
//                 });
//                 updateConversion();
//               },
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               "Conversion Rates",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     baseUnit != null ? "1 ${_short(baseUnit!)}" : "1 Unit",
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   flex: 1,
//                   child: TextFormField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       border: OutlineInputBorder(),
//                       isDense: true,
//                     ),
//                     keyboardType: const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     onChanged: (val) {
//                       conversionValue = double.tryParse(val) ?? 0;
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     secondaryUnit != null
//                         ? _short(secondaryUnit!)
//                         : "Secondary Unit",
//                     style: const TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             SizedBox(
//               width: double.infinity,
//               height: 48,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.deepPurple,
//                 ),
//                 onPressed: () {
//                   if (baseUnit == null || secondaryUnit == null) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Please select both units")),
//                     );
//                     return;
//                   }
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(
//                         "1 ${_short(baseUnit!)} = $conversionValue ${_short(secondaryUnit!)}",
//                       ),
//                     ),
//                   );
//                 },
//                 child: const Text(
//                   "Save",
//                   style: TextStyle(fontSize: 16, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _short(String unit) => unit.split(' ').first;
// }
