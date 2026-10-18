import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';



class AirGapReceivePage extends StatefulWidget {
  const AirGapReceivePage({super.key});

  @override
  State<AirGapReceivePage> createState() => _AirGapReceivePageState();
}

class _AirGapReceivePageState extends State<AirGapReceivePage> {
  String? _scannedData;
  final Map<int, List<int>> _receivedChunks = {};
  String? _transferId;
  int? _totalFrames;
  String? _filename;
  bool _isSaving = false;
  String? _expectedDigest;
  final Stopwatch _receiveTimer = Stopwatch();
  bool _transferComplete = false;
  int? _completedBytes;
  double? _completedSeconds;
  double? _completedThroughput;

  // adds bytes received from frames in order and returns as a list
  List<int> _reconstructFile() {
    final List<int> bytes = [];

    for (var i = 0; i < _totalFrames!; i++) {
      bytes.addAll(_receivedChunks[i]!);

    }

    return bytes;
  }

  // resets all variables for new transfer
  void _resetTransfer() {
    setState(() {
      _receivedChunks.clear();
      _transferId = null;
      _totalFrames = null;
      _filename = null;
      _expectedDigest = null;
      _scannedData = null;
      _isSaving = false;
      _transferComplete = false;
      _completedBytes = null;
      _completedSeconds = null;
      _completedThroughput = null;
      _receiveTimer
        ..stop()
        ..reset();
    });
  }
  // show file transfer stats
  Widget _buildCompletionPanel() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Transfer Complete',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(_filename ?? 'Unknown file'),
                Text(
                  '${((_completedBytes ?? 0) / 1024).toStringAsFixed(1)} KiB',
                ),
                const SizedBox(height: 12),
                const Text('SHA-256 Verified'),
                const SizedBox(height: 20),
                Text(
                  'Time: ${_completedSeconds!.toStringAsFixed(2)} seconds',
                ),
                Text(
                  'Speed: ${_completedThroughput!.toStringAsFixed(1)} B/s',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _resetTransfer,
                  child: const Text('New Transfer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive via AirGap')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _transferComplete
                  ? _buildCompletionPanel()
                  : MobileScanner(
                onDetect: (capture) async {
                  if (_isSaving || capture.barcodes.isEmpty) return;

                  final value = capture.barcodes.first.rawValue;

                  if (value == null) return;
                  try {
                  // Decode the QR frame.
                  final frame = jsonDecode(value) as Map<String, dynamic>;

                  final id = frame['id'] as String;
                  final index = frame['index'] as int;
                  final total = frame['total'] as int;
                  final bytes = base64Decode(frame['data'] as String);
                  // Reject invalid frame numbers.
                  if (total < 1 || index < 0 || index >= total) return;
                  // Don't mix frames from different transfers.
                  if (_transferId != null &&
                        (_transferId != id || _totalFrames != total)) {
                      return;
                    }
                  // Ignore frames we've already received.
                  if (_receivedChunks.containsKey(index)) return;

                  // reset timer
                  if (_receivedChunks.isEmpty) {
                    _receiveTimer.reset();
                    _receiveTimer.start();
                  }

                  setState(() {
                    // set variables on first received frame
                    _filename ??= frame['name'] as String;
                    _transferId ??= id;
                    _totalFrames ??= total;
                    _expectedDigest??= frame['sha256'] as String;
                    _receivedChunks[index] = bytes;



                    _scannedData =
                    'Received ${_receivedChunks.length} / $_totalFrames frames';
                  });

                  // check if all frames received
                  if (_receivedChunks.length == _totalFrames)
                  {
                    _isSaving = true;
                    final List<int> fileBytes = _reconstructFile();

                    // check file integrity
                    final actualDigest = sha256.convert(fileBytes).toString();
                    if (actualDigest != _expectedDigest) {
                      // file integrity corrupted reject file
                      setState(() {
                        _scannedData = 'File integrity check failed!';
                      });
                      return;
                    }

                    // stop timer when file received
                    _receiveTimer.stop();
                    final seconds = _receiveTimer.elapsedMilliseconds / 1000.0;
                    final throughput = fileBytes.length / seconds;

                    // file picker opens if hashes match
                    final saved = await FilePicker.saveFile(
                        fileName: _filename!,
                        bytes: Uint8List.fromList(fileBytes));

                    if (!mounted) return;

                    setState(() {
                      _transferComplete = saved != null;

                      if (saved != null) {
                        _completedBytes = fileBytes.length;
                        _completedSeconds = seconds;
                        _completedThroughput = throughput;
                      }

                      _scannedData = saved == null
                          ? 'Save cancelled'
                          : 'Transfer Complete!';
                    });
                  }

                  } catch (e) {
                    debugPrint('invalid qr frame: $e');
                  }
                },
              ),
            ),
            if (!_transferComplete)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _scannedData ?? 'Point camera at QR code',
                ),
              ),

              // progress bar
              if (_totalFrames != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LinearProgressIndicator(
                    value: _receivedChunks.length / _totalFrames!,
                  ),
                ),

            // retry btn
            if (_isSaving && !_transferComplete)
              ElevatedButton(
                onPressed: _resetTransfer,
                child: const Text('Retry / New Transfer'),
              ),
          ],
        ),
      ),
    );
  }
}