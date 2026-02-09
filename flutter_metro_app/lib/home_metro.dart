import 'package:flutter/material.dart';
import 'package:flutter_metro_app/metro_data.dart';
import 'package:flutter_metro_app/metro_utils.dart';
import 'package:flutter_metro_app/metrostation_class.dart';
import 'package:flutter_metro_app/tamplets/buildResultRow.dart';
import 'package:flutter_metro_app/tamplets/selectbox.dart';
import 'package:geolocator/geolocator.dart';

// ===================== Main HomeMetro Widget =====================
class HomeMetro extends StatefulWidget {
  const HomeMetro({super.key});

  @override
  State<HomeMetro> createState() => _HomeMetroState();
}

class _HomeMetroState extends State<HomeMetro> {
  MetroStation? fromStation; // selected "from" station
  MetroStation? toStation; // selected "to" station

  double? ticketPrice; // calculated ticket price
  int? tripTimeMinutes; // calculated trip time in minutes
  List<MetroStation>? route; // full route including transfers
  String? routeText; // human-readable route

  MetroStation? nearestStation; // nearest station based on GPS
  bool isLoadingNearest = false; // loading state for nearest station

  // ===================== Dropdown Lists =====================
  List<MetroStation> getToStations() {
    if (fromStation == null) return metroStations;
    return metroStations.where((station) => station != fromStation).toList();
  }

  List<MetroStation> getFromStations() {
    if (toStation == null) return metroStations;
    return metroStations.where((station) => station != toStation).toList();
  }

  // ===================== Find Nearest Station =====================
  Future<void> _findNearestStation() async {
    setState(() {
      isLoadingNearest = true;
      nearestStation = null;
    });

    try {
      // 1. Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

      // 2. Check for location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permissions permanently denied. Enable from settings.',
            ),
          ),
        );
        return;
      }

      // 3. Get the current location safely
      Position? position;

      try {
        // First, try getting last known position (fast for emulator)
        position = await Geolocator.getLastKnownPosition();

        position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 10),
          forceAndroidLocationManager: true,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
        return;
      }

      if (position == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No location available')));
        return;
      }

      // 4. Calculate the nearest station
      MetroStation? closest;
      double minDistance = double.infinity;

      for (final station in metroStations) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          station.lat,
          station.lng,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closest = station;
        }
      }

      if (closest != null) {
        setState(() {
          nearestStation = closest;
          fromStation = closest; // fill the "from" station
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nearest station: ${closest.name} (${(minDistance / 1000).toStringAsFixed(1)} km)',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    } finally {
      setState(() {
        isLoadingNearest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metro Route'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============= From Station Dropdown =============
            stationDropdown(
              hint: 'From station',
              selectedValue: fromStation,
              items: getFromStations(),
              onChanged: (value) {
                setState(() {
                  fromStation = value;
                  _clearResults(); // clear previous calculation results
                });
              },
            ),

            const SizedBox(height: 20),

            // ============= To Station Dropdown =============
            stationDropdown(
              hint: 'To station',
              selectedValue: toStation,
              items: getToStations(),
              onChanged: (value) {
                setState(() {
                  toStation = value;
                  _clearResults(); // clear previous calculation results
                });
              },
            ),

            const SizedBox(height: 30),

            // ============= Show Nearest Station Button =============
            OutlinedButton.icon(
              icon: isLoadingNearest
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.my_location, size: 20),
              label: Text(
                nearestStation == null
                    ? 'Show nearest station'
                    : 'Nearest station: ${nearestStation!.name}',
              ),
              onPressed: isLoadingNearest ? null : _findNearestStation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 30),

            // ============= Calculate Route & Ticket Price Button =============
            ElevatedButton(
              onPressed: (fromStation != null && toStation != null)
                  ? () {
                      setState(() {
                        ticketPrice = calculateTicketPrice(
                          fromStation!,
                          toStation!,
                        );
                        route = getCompleteRoute(fromStation!, toStation!);
                        tripTimeMinutes = calculateTripTime(
                          fromStation!,
                          toStation!,
                        );

                        // convert route list to readable string
                        routeText = route!.map((s) => s.name).join(" → ");
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Calculate Route & Price',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 32),

            // ============= Result Card =============
            if (ticketPrice != null &&
                route != null &&
                tripTimeMinutes != null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildResultRow(
                        icon: Icons.train,
                        title: "Route",
                        value: routeText ?? "—",
                        isBold: true,
                      ),
                      const Divider(height: 24),
                      buildResultRow(
                        icon: Icons.timer_outlined,
                        title: "Estimated Time",
                        value: "$tripTimeMinutes Minutes",
                      ),
                      const Divider(height: 24),
                      buildResultRow(
                        icon: Icons.attach_money,
                        title: "Ticket Price",
                        value: "$ticketPrice EGP",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================== Clear Previous Results =====================
  void _clearResults() {
    ticketPrice = null;
    tripTimeMinutes = null;
    route = null;
    routeText = null;
  }
}
