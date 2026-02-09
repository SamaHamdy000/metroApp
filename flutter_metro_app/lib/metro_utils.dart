import 'package:flutter_metro_app/metro_data.dart';
import 'package:flutter_metro_app/metrostation_class.dart';
import 'package:flutter_metro_app/transfer_class.dart';

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────

List<MetroStation> getStationsByLine(int line) {
  return metroStations.where((s) => s.line == line).toList();
}

// ──────────────────────────────────────────────
// Route on single line (linear lines: 1 & 2)
// ──────────────────────────────────────────────

List<MetroStation> getRoute(MetroStation from, MetroStation to) {
  if (from.line != to.line) return [];

  final lineStations = getStationsByLine(from.line);

  final fromIndex = lineStations.indexWhere((s) => s.name == from.name);
  final toIndex = lineStations.indexWhere((s) => s.name == to.name);

  if (fromIndex == -1 || toIndex == -1) return [];

  if (fromIndex <= toIndex) {
    return lineStations.sublist(fromIndex, toIndex + 1);
  } else {
    return lineStations.sublist(toIndex, fromIndex + 1).reversed.toList();
  }
}

// ──────────────────────────────────────────────
// DFS for Line 3 (supports branches)
// ──────────────────────────────────────────────

List<MetroStation> getRouteDFS(
  MetroStation from,
  MetroStation to,
  Map<String, List<String>> connections,
) {
  List<MetroStation> path = [];
  Set<String> visited = {};

  bool dfs(String currentName) {
    visited.add(currentName);

    final station = metroStations.firstWhere(
      (s) => s.name == currentName,
      orElse: () => MetroStation(name: '', line: 0, lat: 0, lng: 0),
    );

    if (station.name.isEmpty) return false;
    path.add(station);

    if (currentName == to.name) return true;

    for (final neighbor in connections[currentName] ?? []) {
      if (!visited.contains(neighbor)) {
        if (dfs(neighbor)) return true;
      }
    }

    path.removeLast();
    return false;
  }

  dfs(from.name);
  return path;
}

// ──────────────────────────────────────────────
// Transfer logic
// ──────────────────────────────────────────────

List<TransferStations> findAllIntersections(
  MetroStation from,
  MetroStation to,
) {
  List<TransferStations> result = [];
  for (final entry in intersections.entries) {
    final stationName = entry.key;
    final lines = entry.value;

    if (lines.contains(from.line) && lines.contains(to.line)) {
      final fromStation = metroStations.firstWhere(
        (s) => s.name == stationName && s.line == from.line,
        orElse: () => MetroStation(name: '', line: 0, lat: 0, lng: 0),
      );
      final toStation = metroStations.firstWhere(
        (s) => s.name == stationName && s.line == to.line,
        orElse: () => MetroStation(name: '', line: 0, lat: 0, lng: 0),
      );

      if (fromStation.name.isNotEmpty && toStation.name.isNotEmpty) {
        result.add(TransferStations(fromLine: fromStation, toLine: toStation));
      }
    }
  }
  return result;
}

// ──────────────────────────────────────────────
// Main route function (combines everything)
// ──────────────────────────────────────────────

/// دالة مساعدة لاختيار خريطة الاتصالات (connections) حسب رقم الخط
Map<String, List<String>> getLineConnections(int line) {
  switch (line) {
    case 1:
      return line1Connections;
    case 2:
      return line2Connections;
    case 3:
      return line3Connections;
    default:
      return {};
  }
}

List<MetroStation> getCompleteRoute(MetroStation from, MetroStation to) {
  // لو نفس الخط
  if (from.line == to.line) {
    final connections = getLineConnections(from.line);
    if (connections.isEmpty) return [];
    return getRouteDFS(from, to, connections);
  }

  // خطوط مختلفة
  final transfers = findAllIntersections(from, to);
  if (transfers.isEmpty) return [];

  List<MetroStation> shortestRoute = [];
  int minLength = 1000;

  for (final transfer in transfers) {
    // مسار من from إلى محطة التحويل
    final fromConnections = getLineConnections(from.line);
    final firstPart = getRouteDFS(from, transfer.fromLine, fromConnections);
    if (firstPart.isEmpty) continue;

    // مسار من محطة التحويل إلى to
    final toConnections = getLineConnections(to.line);
    final secondPart = getRouteDFS(transfer.toLine, to, toConnections)
        .skip(1) // لتجنب تكرار محطة التحويل
        .toList();
    if (secondPart.isEmpty) continue;

    final complete = [...firstPart, ...secondPart];
    if (complete.length < minLength) {
      minLength = complete.length;
      shortestRoute = complete;
    }
  }

  return shortestRoute;
}

// ──────────────────────────────────────────────
// Calculations
// ──────────────────────────────────────────────

double calculateTicketPrice(MetroStation from, MetroStation to) {
  final route = getCompleteRoute(from, to);
  if (route.isEmpty) return 0;

  final stationsCount = route.length - 1;

  if (stationsCount <= 9) return 6;
  if (stationsCount <= 16) return 8;
  if (stationsCount <= 23) return 12;
  return 15;
}

int calculateTripTime(MetroStation from, MetroStation to) {
  final route = getCompleteRoute(from, to);
  if (route.isEmpty) return 0;

  final stationsCount = route.length - 1;
  int transfers = 0;

  for (int i = 1; i < route.length; i++) {
    if (route[i].line != route[i - 1].line) {
      transfers++;
    }
  }

  return (stationsCount * 2) + (transfers * 3);
}
