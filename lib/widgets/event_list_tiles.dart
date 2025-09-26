import 'package:event_manager_local/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_manager_local/utils/image_utils.dart';

class EventListTiles extends StatefulWidget {
  const EventListTiles({
    super.key,
    required this.events,
    this.title,
    this.limit,
    this.onTap,
    this.haveMenu = false,
    this.onEdit,
    this.onDelete,
  });
  final List<Event> events;
  final String? title;
  final int? limit;
  final void Function(Event)? onTap;
  final bool? haveMenu;
  final void Function(Event)? onEdit;
  final void Function(Event)? onDelete;

  @override
  State<EventListTiles> createState() => _EventListTilesState();
}

class _EventListTilesState extends State<EventListTiles> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.events.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No events available',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      bottom: 12.0,
                      top: 8.0,
                    ),
                    child: Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.limit != null
                      ? (widget.events.length > widget.limit!
                            ? widget.limit!
                            : widget.events.length)
                      : widget.events.length,
                  itemBuilder: (context, index) {
                    final event = widget.events[index];
                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                        left: 12,
                        right: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: widget.onTap != null
                              ? () => widget.onTap!(event)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event Image
                                CachedNetworkImage(
                                  imageUrl: ImageUtils.fixImageUrl(event.bannerUrl),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        child: Icon(
                                          Icons.event,
                                          color: Colors.grey.shade400,
                                          size: 32,
                                        ),
                                      ),
                                ),
                                const SizedBox(width: 16),
                                // Event Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Event Title
                                      Text(
                                        event.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),

                                      // Location
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              event.location,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 13,
                                                    color: Colors.grey[700],
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Date & Time
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDateTime(
                                              event.startDateTime,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.haveMenu == true)
                                  PopupMenuButton<String>(
                                    onSelected: (String result) {
                                      if (result == 'edit' &&
                                          widget.onEdit != null) {
                                        widget.onEdit!(event);
                                      } else if (result == 'delete' &&
                                          widget.onDelete != null) {
                                        widget.onDelete!(event);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) =>
                                        <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  color: Colors.black54,
                                                ),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                    icon: const Icon(Icons.more_vert),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} • ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }
}
