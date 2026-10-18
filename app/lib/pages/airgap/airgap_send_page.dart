import 'dart:async';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/util/airgap/airgap_gen.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class AirGapSendPage extends StatefulWidget {
  final CrossFile file;

  const AirGapSendPage({
    super.key,
    required this.file,
  });

  @override
  State<AirGapSendPage> createState() => _AirGapSendPageState();
}

class _AirGapSendPageState extends State<AirGapSendPage> {
  late final Future<List<String>> _framesFuture;
  int _currentFrame = 0;
  Timer? _timer; // for frame timer

  void _startAnimation(int totalFrames) {
    _timer?.cancel(); // stops timer if running already

    _timer = Timer.periodic(
        const Duration(milliseconds: 300),
          (_) {

          setState(() {
          _currentFrame = (_currentFrame + 1) % totalFrames;
          });

        },
    );

  }

  @override
  void initState() {
    super.initState();
    _framesFuture = AirGapGenerator.encodeFile(widget.file);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send via AirGap'),
      ),
      body: FutureBuilder<List<String>>(
        future: _framesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final frames = snapshot.data!;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('File: ${widget.file.name}'),
                const SizedBox(height: 20),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: PrettyQrView.data(
                      data: frames[_currentFrame],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Frame ${_currentFrame + 1} / ${frames.length}',
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    _startAnimation(frames.length);
                  },
                  child: const Text('Start QR animation'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}