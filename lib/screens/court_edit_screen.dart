import 'package:flutter/material.dart';

class CourtDetails {
  final String? surface;
  final String? speed;
  final String? cover;
  final String? altitude;

  CourtDetails({
    this.surface,
    this.speed,
    this.cover,
    this.altitude,
  });
}

class CourtEditScreen extends StatefulWidget {
  final CourtDetails? initialDetails;

  const CourtEditScreen({super.key, this.initialDetails});

  @override
  State<CourtEditScreen> createState() => _CourtEditScreenState();
}

class _CourtEditScreenState extends State<CourtEditScreen> {
  String? _courtSurface;
  String? _courtSpeed;
  String? _courtCover;
  String? _altitude;

  final List<String> _courtSurfaces = [
    'Red clay',
    'Green clay',
    'Hard',
    'Grass',
    'Carpet',
  ];

  final List<String> _courtCovers = [
    'Outdoor',
    'Bubble',
    'Fabric',
    'Retractable',
    'Indoor',
  ];

  final List<String> _altitudesList = [
    'Low (0-1,000m/0-3,300ft)',
    'Mid (1,000-1,500m/3,300-5,000ft)',
    'High (1,500+m/5,000+ft)',
  ];

  // Get available speeds based on surface
  List<String> _getAvailableSpeeds() {
    if (_courtSurface == null) return [];

    if (_courtSurface == 'Red clay' || _courtSurface == 'Green clay') {
      return ['Slow', 'Slow-Medium'];
    } else if (_courtSurface == 'Hard') {
      return ['Medium', 'Medium-Fast'];
    } else if (_courtSurface == 'Grass' || _courtSurface == 'Carpet') {
      return ['Fast'];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    final details = widget.initialDetails;
    if (details != null) {
      _courtSurface = details.surface;
      // Handle legacy "Clay" value
      if (_courtSurface == 'Clay') {
        _courtSurface = 'Red clay';
      }
      _courtSpeed = details.speed;
      _courtCover = details.cover;
      _altitude = details.altitude;
    }
  }

  void _saveAndReturn() {
    Navigator.pop(
      context,
      CourtDetails(
        surface: _courtSurface,
        speed: _courtSpeed,
        cover: _courtCover,
        altitude: _altitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Court Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndReturn,
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Surface
          DropdownButtonFormField<String>(
            initialValue: _courtSurface,
            decoration: InputDecoration(
              labelText: 'Surface',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.landscape),
              suffixIcon: _courtSurface != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _courtSurface = null;
                          _courtSpeed = null;
                        });
                      },
                      tooltip: 'Clear',
                    )
                  : null,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Not set', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
              ..._courtSurfaces.map((surface) {
                return DropdownMenuItem(value: surface, child: Text(surface));
              }),
            ],
            onChanged: (value) {
              setState(() {
                _courtSurface = value;
                // Clear speed if it's not valid for the new surface
                if (_courtSpeed != null) {
                  final availableSpeeds = _getAvailableSpeeds();
                  if (!availableSpeeds.contains(_courtSpeed)) {
                    _courtSpeed = null;
                  }
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // Speed (only show if surface is selected)
          if (_courtSurface != null && _getAvailableSpeeds().isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _courtSpeed,
              decoration: InputDecoration(
                labelText: 'Speed',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.speed),
                suffixIcon: _courtSpeed != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _courtSpeed = null);
                        },
                        tooltip: 'Clear',
                      )
                    : null,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Not set', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
                ..._getAvailableSpeeds().map((speed) {
                  return DropdownMenuItem(value: speed, child: Text(speed));
                }),
              ],
              onChanged: (value) {
                setState(() => _courtSpeed = value);
              },
            ),

          if (_courtSurface != null && _getAvailableSpeeds().isNotEmpty)
            const SizedBox(height: 16),

          // Cover
          DropdownButtonFormField<String>(
            initialValue: _courtCover,
            decoration: InputDecoration(
              labelText: 'Cover',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.roofing),
              suffixIcon: _courtCover != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _courtCover = null);
                      },
                      tooltip: 'Clear',
                    )
                  : null,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Not set', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
              ..._courtCovers.map((cover) {
                return DropdownMenuItem(value: cover, child: Text(cover));
              }),
            ],
            onChanged: (value) {
              setState(() => _courtCover = value);
            },
          ),

          const SizedBox(height: 16),

          // Altitude
          DropdownButtonFormField<String>(
            initialValue: _altitude,
            decoration: InputDecoration(
              labelText: 'Altitude',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.terrain),
              suffixIcon: _altitude != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() => _altitude = null);
                      },
                      tooltip: 'Clear',
                    )
                  : null,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Not set', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
              ..._altitudesList.map((altitude) {
                return DropdownMenuItem(value: altitude, child: Text(altitude));
              }),
            ],
            onChanged: (value) {
              setState(() => _altitude = value);
            },
          ),

          const SizedBox(height: 24),

          // Save Button
          ElevatedButton(
            onPressed: _saveAndReturn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save'),
          ),

          const SizedBox(height: 8),

          // Cancel Button
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
