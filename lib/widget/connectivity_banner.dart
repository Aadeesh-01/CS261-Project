import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A lightweight banner that appears at the top of the app when there is
/// no network connectivity. It wraps the entire app via MaterialApp.builder
/// so it works across all routes.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  StreamSubscription?
      _sub; // List<ConnectivityResult> for newer connectivity_plus
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    // Seed initial value then listen for changes
    Connectivity().checkConnectivity().then((res) {
      if (!mounted) return;
      setState(() => _offline = res == ConnectivityResult.none);
    });
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      // onConnectivityChanged now emits List<ConnectivityResult>
      final first =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() => _offline = first == ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You\'re offline. Some actions are unavailable.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
