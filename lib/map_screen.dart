
import 'package:flutter/material.dart';
import 'package:gps_task_app/google_map_view_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MyAppState extends ChangeNotifier {
  String currentCity = "Unknown City";

  setCurrentCity(LatLng coordinates) async {
    try {
      final addresses = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (addresses.isNotEmpty) {
        final firstAddress = addresses.first;
        currentCity = firstAddress.locality ?? "Unknown City";
      } else {
        currentCity = "Unknown City";
      }
      notifyListeners();
    } catch (e) {
      currentCity = "Unknown City";
      notifyListeners();
    }
  }
}

class NewMapScreen extends StatelessWidget {
  const NewMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(children: [MapWidget(), CityWidget()]),
    );
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final Future<LatLng> _mapLoadedFuture;
  final viewModel = GoogleMapViewModel();

  @override
  void initState() {
    super.initState();
    _mapLoadedFuture = viewModel.loadCurrentUserCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Expanded(
        flex: 1,
        child: FutureBuilder(
            future: _mapLoadedFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              } else {
                return GoogleMapWidget(
                    onMapCreated: (controller) {
                      appState.setCurrentCity(snapshot.data as LatLng);
                      viewModel.controller.complete(controller);
                    },
                    currentUserLocation: snapshot.data as LatLng);
              }
            }));
  }
}

class CityWidget extends StatelessWidget {
  const CityWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You are located in ${appState.currentCity}',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class GoogleMapWidget extends StatelessWidget {
  const GoogleMapWidget({
    required this.onMapCreated,
    required this.currentUserLocation,
    super.key,
  });

  final void Function(GoogleMapController) onMapCreated;
  final LatLng currentUserLocation;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: currentUserLocation,
        zoom: 18,
      ),
      onMapCreated: onMapCreated,
      markers: {
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentUserLocation,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => MarkerCoordinatesDialog(
                latitude: currentUserLocation.latitude,
                longitude: currentUserLocation.longitude,
              ),
            );
          },
        ),
      },
    );
  }
}

class MarkerCoordinatesDialog extends StatelessWidget {
  const MarkerCoordinatesDialog({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude, longitude;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("User's Current Location"),
      content: Text(
        'Latitude: $latitude, Longitude: $longitude',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
