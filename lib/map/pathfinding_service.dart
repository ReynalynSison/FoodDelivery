import 'dart:math';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// A* Pathfinding Service
// ---------------------------------------------------------------------------
// Converts real-world LatLng coordinates into a discrete grid, runs the A*
// search algorithm on that grid, then converts the resulting grid path back
// into LatLng waypoints for rendering as a polyline on the map.
//
// Grid resolution is controlled by [gridSize]: a higher value produces a
// finer grid (more waypoints, smoother curve) at the cost of compute time.
// ---------------------------------------------------------------------------

class PathfindingService {
  /// Number of grid cells along each axis.
  /// 20×20 is fast and produces a clearly visible stepped/curved route.
  static const int gridSize = 20;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns an ordered list of [LatLng] waypoints from [start] to [end]
  /// calculated with the A* algorithm on a [gridSize]×[gridSize] grid.
  ///
  /// Returns an empty list only if no path exists (should not happen on an
  /// obstacle-free grid).
  List<LatLng> findRoute(LatLng start, LatLng end) {
    // --- 1. Map LatLng coordinates → grid cells ---
    final _GridBounds bounds = _GridBounds.from(start, end);
    final _Cell startCell = bounds.toCell(start);
    final _Cell endCell = bounds.toCell(end);

    // --- 2. Run A* on the grid ---
    final List<_Cell>? gridPath = _astar(startCell, endCell);
    if (gridPath == null || gridPath.isEmpty) return [start, end];

    // --- 3. Convert grid path back to LatLng ---
    return gridPath.map((cell) => bounds.toLatLng(cell)).toList();
  }

  // -------------------------------------------------------------------------
  // A* Algorithm
  // -------------------------------------------------------------------------

  /// Core A* search.
  ///
  /// - **Open set**: min-priority queue ordered by f = g + h.
  /// - **g(n)**: exact cost from start to n (step count).
  /// - **h(n)**: Euclidean distance heuristic to end cell.
  /// - **Neighbors**: 8-directional (cardinal + diagonal).
  ///
  /// Returns the reconstructed path from start to end, or null if unreachable.
  List<_Cell>? _astar(_Cell start, _Cell end) {
    // --- Open set: nodes to be evaluated ---
    final List<_AStarNode> openSet = [];

    // --- Closed set: already-evaluated cells ---
    final Set<_Cell> closedSet = {};

    // --- Cost map: best known g-cost to reach each cell ---
    final Map<_Cell, double> gCost = {};

    // --- Parent map: used to reconstruct the path ---
    final Map<_Cell, _Cell?> parent = {};

    // Initialise with the start node
    gCost[start] = 0;
    parent[start] = null;
    openSet.add(_AStarNode(cell: start, f: _heuristic(start, end)));

    while (openSet.isNotEmpty) {
      // Pop the node with the lowest f-score
      openSet.sort((a, b) => a.f.compareTo(b.f));
      final _AStarNode current = openSet.removeAt(0);

      // Goal reached — reconstruct and return path
      if (current.cell == end) {
        return _reconstructPath(parent, end);
      }

      closedSet.add(current.cell);

      // Evaluate all 8 neighbours
      for (final _Cell neighbor in _neighbors(current.cell)) {
        if (closedSet.contains(neighbor)) continue;

        // Diagonal movement costs √2, cardinal costs 1
        final bool isDiagonal =
            (neighbor.col - current.cell.col).abs() == 1 &&
            (neighbor.row - current.cell.row).abs() == 1;
        final double moveCost = isDiagonal ? sqrt(2) : 1.0;

        final double tentativeG = (gCost[current.cell] ?? double.infinity) + moveCost;

        if (tentativeG < (gCost[neighbor] ?? double.infinity)) {
          // Found a better path to this neighbor
          gCost[neighbor] = tentativeG;
          parent[neighbor] = current.cell;

          final double f = tentativeG + _heuristic(neighbor, end);

          // Remove stale entry if present, then add updated one
          openSet.removeWhere((n) => n.cell == neighbor);
          openSet.add(_AStarNode(cell: neighbor, f: f));
        }
      }
    }

    // No path found
    return null;
  }

  // -------------------------------------------------------------------------
  // Heuristic — Euclidean distance
  // -------------------------------------------------------------------------

  /// Euclidean distance between two grid cells.
  /// Admissible for 8-directional movement (never overestimates).
  double _heuristic(_Cell a, _Cell b) {
    final double dr = (a.row - b.row).toDouble();
    final double dc = (a.col - b.col).toDouble();
    return sqrt(dr * dr + dc * dc);
  }

  // -------------------------------------------------------------------------
  // Neighbours — 8-directional
  // -------------------------------------------------------------------------

  /// Returns all valid grid neighbours of [cell] (up to 8 directions).
  List<_Cell> _neighbors(_Cell cell) {
    const List<List<int>> directions = [
      [-1,  0], // North
      [ 1,  0], // South
      [ 0, -1], // West
      [ 0,  1], // East
      [-1, -1], // North-West
      [-1,  1], // North-East
      [ 1, -1], // South-West
      [ 1,  1], // South-East
    ];

    final List<_Cell> result = [];
    for (final dir in directions) {
      final int r = cell.row + dir[0];
      final int c = cell.col + dir[1];
      if (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
        result.add(_Cell(row: r, col: c));
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Path reconstruction
  // -------------------------------------------------------------------------

  /// Walks the [parent] map backwards from [end] to produce the forward path.
  List<_Cell> _reconstructPath(Map<_Cell, _Cell?> parent, _Cell end) {
    final List<_Cell> path = [];
    _Cell? current = end;

    while (current != null) {
      path.add(current);
      current = parent[current];
    }

    return path.reversed.toList();
  }
}

// ---------------------------------------------------------------------------
// Supporting data classes
// ---------------------------------------------------------------------------

/// A discrete cell on the A* grid.
class _Cell {
  final int row;
  final int col;

  const _Cell({required this.row, required this.col});

  @override
  bool operator ==(Object other) =>
      other is _Cell && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($_row, $_col)';

  // ignore: unused_field
  int get _row => row;
  // ignore: unused_field
  int get _col => col;
}

/// A node in the A* open set carrying its cell and total f-score.
class _AStarNode {
  final _Cell cell;
  final double f; // f = g + h

  const _AStarNode({required this.cell, required this.f});
}

/// Holds the geographic bounding box used to convert between
/// LatLng coordinates and integer grid cells.
class _GridBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  // Small padding so start/end cells are never on the grid edge
  static const double _padding = 0.002;

  const _GridBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  factory _GridBounds.from(LatLng a, LatLng b) {
    return _GridBounds(
      minLat: min(a.latitude,  b.latitude)  - _padding,
      maxLat: max(a.latitude,  b.latitude)  + _padding,
      minLng: min(a.longitude, b.longitude) - _padding,
      maxLng: max(a.longitude, b.longitude) + _padding,
    );
  }

  /// Map a LatLng to the nearest grid cell.
  _Cell toCell(LatLng point) {
    final double latRange = maxLat - minLat;
    final double lngRange = maxLng - minLng;
    final int n = PathfindingService.gridSize - 1;

    final int row = ((point.latitude  - minLat) / latRange * n).round().clamp(0, n);
    final int col = ((point.longitude - minLng) / lngRange * n).round().clamp(0, n);
    return _Cell(row: row, col: col);
  }

  /// Map a grid cell back to a LatLng (cell centre).
  LatLng toLatLng(_Cell cell) {
    final double latRange = maxLat - minLat;
    final double lngRange = maxLng - minLng;
    final int n = PathfindingService.gridSize - 1;

    final double lat = minLat + (cell.row / n) * latRange;
    final double lng = minLng + (cell.col / n) * lngRange;
    return LatLng(lat, lng);
  }
}

