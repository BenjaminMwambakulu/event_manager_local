import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/services/organiser_service.dart';
import 'package:event_manager_local/widgets/event_list_tiles.dart';
import 'package:flutter/material.dart';

class OrganiserEventList extends StatefulWidget {
  const OrganiserEventList({super.key});

  @override
  State<OrganiserEventList> createState() => _OrganiserEventListState();
}

class _OrganiserEventListState extends State<OrganiserEventList> {
  List<Event> _events = [];

  void _fetchEvents() async {
    final eventsData = await OrganiserService().getOrganiserEvents();
    final events = eventsData.map((e) => Event.fromJson(e)).toList();
    setState(() {
      _events = events;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void _refresh() {
    _fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    "My Events",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  InkWell(
                    onTap: () {},
                    child: Text("view all", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
            EventListTiles(events: _events, onTap: (event) {}, haveMenu: true),
          ],
        ),
      ),
    );
  }
}
