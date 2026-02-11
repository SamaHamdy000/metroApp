import 'package:flutter/material.dart';
import 'package:flutter_metro_app/metro_data.dart';
import 'package:flutter_metro_app/metro_utils.dart';
import 'package:flutter_metro_app/metrostation_class.dart';
import 'package:flutter_metro_app/station_map_screen.dart';
import 'package:flutter_metro_app/tamplets/buildResultRow.dart';
import 'package:flutter_metro_app/tamplets/selectbox.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class HomeMetro extends StatefulWidget {
  const HomeMetro({super.key});

  @override
  State<HomeMetro> createState() => _HomeMetroState();
}

class _HomeMetroState extends State<HomeMetro> {
  MetroStation? fromStation;
  MetroStation? toStation;

  double? ticketPrice;
  int? tripTimeMinutes;
  List<MetroStation>? route;
  String? routeText;
  List<String>? transferStations; // أسماء محطات التحويل

  MetroStation? nearestStation;
  bool isLoadingNearest = false;

  TextEditingController streetController = TextEditingController();
  bool isLoadingStreet = false;

  // ================= Dropdown Lists =================
  List<MetroStation> getToStations() {
    final stations = metroStations.where((station) {
      // استبعد المحطة اللي مختارة كـ FromStation
      if (fromStation != null && station.name == fromStation!.name)
        return false;
      return true;
    }).toList();

    // فلترة duplicates بناءً على الاسم
    final seenNames = <String>{};
    return stations.where((s) {
      if (seenNames.contains(s.name)) return false;
      seenNames.add(s.name);
      return true;
    }).toList();
  }

  List<MetroStation> getFromStations() {
    final stations = metroStations.where((station) {
      // استبعد المحطة اللي مختارة كـ ToStation
      if (toStation != null && station.name == toStation!.name) return false;
      return true;
    }).toList();

    // فلترة duplicates بناءً على الاسم
    final seenNames = <String>{};
    return stations.where((s) {
      if (seenNames.contains(s.name)) return false;
      seenNames.add(s.name);
      return true;
    }).toList();
  }

  // ================= Find Nearest Station (GPS) =================
  Future<void> _findNearestStation() async {
    setState(() {
      isLoadingNearest = true;
      nearestStation = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        return;
      }

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

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
        forceAndroidLocationManager: true,
      );

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
          fromStation = closest;
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

  // ================= Find Nearest Station (Street for To Station) =================
  Future<void> _findNearestStationFromStreetUI(String street) async {
    if (street.trim().isEmpty) return;

    setState(() {
      isLoadingStreet = true;
      nearestStation = null;
    });

    try {
      List<Location> locations = await locationFromAddress(
        "$street, Cairo, Egypt",
      );
      if (locations.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Street not found.")));
        return;
      }

      final loc = locations.first;

      MetroStation? closest;
      double minDistance = double.infinity;

      for (final station in metroStations) {
        double distance = Geolocator.distanceBetween(
          loc.latitude,
          loc.longitude,
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
          toStation = closest; // To Station
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nearest station to "$street": ${closest.name} (${(minDistance / 1000).toStringAsFixed(2)} km)',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        isLoadingStreet = false;
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
            Row(
              children: [
                Expanded(
                  child: stationDropdown(
                    hint: 'From station',
                    selectedValue: fromStation,
                    items: getFromStations(),
                    onChanged: (value) {
                      setState(() {
                        fromStation = value;
                        _clearResults();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: fromStation == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StationMapScreen(station: fromStation!),
                            ),
                          );
                        },
                ),
              ],
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
                  _clearResults();
                });
              },
            ),

            const SizedBox(height: 30),

            // ============= Show Nearest Station Button (GPS) =============
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

                        // Route text
                        routeText = route!.map((s) => s.name).join(" → ");

                        //transfer station
                        transferStations = [];
                        for (int i = 0; i < route!.length; i++) {
                          if (intersections.containsKey(route![i].name)) {
                            transferStations!.add(route![i].name);
                          }
                        }
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

            // ============= Street Input for To Station =============
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: streetController,
                    decoration: const InputDecoration(
                      hintText: "Enter street name",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: isLoadingStreet
                      ? null
                      : () async {
                          await _findNearestStationFromStreetUI(
                            streetController.text,
                          );
                        },
                  child: isLoadingStreet
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text("Find Nearest for To Station"),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                      if (transferStations != null &&
                          transferStations!.isNotEmpty)
                        buildResultRow(
                          icon: Icons.swap_horiz,
                          title: "Transfers at",
                          value: transferStations!.join(", "),
                        ),
                      if (transferStations != null &&
                          transferStations!.isNotEmpty)
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

  void _clearResults() {
    ticketPrice = null;
    tripTimeMinutes = null;
    route = null;
    routeText = null;
    transferStations = null;
  }
}
