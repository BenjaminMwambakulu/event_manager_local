// import 'package:event_management/Models/event_model.dart';
// import 'package:event_management/providers/registered_events.dart';
// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:provider/provider.dart';

// class MyTicket extends StatefulWidget {
//   const MyTicket({super.key});

//   @override
//   State<MyTicket> createState() => _MyTicketState();
// }

// class _MyTicketState extends State<MyTicket> {
//   final supabase = Supabase.instance.client;

//   @override
//   Widget build(BuildContext context) {
//     double height = 300;

//     return Consumer<RegisteredEvents>(
//       builder: (context, registeredEventsProvider, child) {
//         // We don't need to fetch events here as they are already in the provider
//         final events = registeredEventsProvider.registeredEvents;

//         if (registeredEventsProvider.isLoading) {
//           return SizedBox(
//             height: height,
//             child: const Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (events.isEmpty) {
//           return SizedBox(
//             height: height,
//             child: const Center(child: Text('No registered events')),
//           );
//         }

//         return SizedBox(
//           height: height,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: events.length,
//             padding: const EdgeInsets.all(16),
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: const EdgeInsets.only(right: 16),
//                 child: TicketCard(
//                   eventData: events[index],
//                   userId: supabase.auth.currentUser!.id,
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }

// class TicketCard extends StatelessWidget {
//   final Event eventData;
//   final String userId;

//   const TicketCard({super.key, required this.eventData, required this.userId});

//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width * 0.8;
//     double dotWidth = 6;
//     double spacing = 6;
//     int numberOfDots = (width / (dotWidth + spacing)).floor();
//     numberOfDots = numberOfDots.clamp(0, 100); // safety

//     final formattedDate =
//         "${eventData.startTime.day}/${eventData.startTime.month}/${eventData.startTime.year}";
//     final formattedTime =
//         "${eventData.startTime.hour}:${eventData.startTime.minute.toString().padLeft(2, '0')}";

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         height: 300,
//         width: width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 4,
//               offset: Offset(2, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // Top section with event info
//             Expanded(
//               flex: 1,
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 width: double.infinity,
//                 color: Theme.of(context).colorScheme.secondaryContainer,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         eventData.title,
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSecondaryContainer,
//                         ),
//                         overflow: TextOverflow.fade,
//                         softWrap: true,
//                       ),
//                       const SizedBox(height: 8),
//                       Text('Date: $formattedDate'),
//                       Text('Time: $formattedTime'),
//                       const SizedBox(height: 8),
//                       Text('Location: ${eventData.location}'),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // Dotted line separator
//             Container(
//               height: 1,
//               margin: const EdgeInsets.symmetric(vertical: 0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: List.generate(
//                   numberOfDots,
//                   (_) =>
//                       Container(width: dotWidth, height: 1, color: Colors.grey),
//                 ),
//               ),
//             ),

//             // Bottom section with QR code
//             Expanded(
//               flex: 1,
//               child: Container(
//                 width: double.infinity,
//                 color: Colors.grey[200],
//                 child: Center(
//                   child: QrImageView(
//                     data: 'event_${eventData.id}_user_$userId',
//                     size: 120,
//                     errorCorrectionLevel: QrErrorCorrectLevel.Q,
//                     backgroundColor: Theme.of(
//                       context,
//                     ).colorScheme.secondaryContainer,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
