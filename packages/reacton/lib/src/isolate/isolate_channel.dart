import 'dart:async';
import 'dart:isolate';

import 'isolate_protocol.dart';

/// Two-way communication channel between isolates.
///
/// Provides a typed message-passing interface over Dart's
/// [SendPort]/[ReceivePort] mechanism.
class IsolateChannel {
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  late final Stream<IsolateMessage> _incoming;

  IsolateChannel(this._sendPort, this._receivePort) {
    _incoming = _receivePort.cast<IsolateMessage>().asBroadcastStream();
  }

  /// Send a message to the other isolate.
  void send(IsolateMessage message) => _sendPort.send(message);

  /// Stream of incoming messages from the other isolate.
  Stream<IsolateMessage> get messages => _incoming;

  /// Close the receive port.
  void close() => _receivePort.close();

  /// Create a pair of channels for two isolates to communicate.
  ///
  /// Returns (mainChannel, workerInitPort). The worker init port
  /// should be passed to the spawned isolate.
  static (ReceivePort mainReceive, SendPort workerInitPort) createPair() {
    final mainReceive = ReceivePort();
    return (mainReceive, mainReceive.sendPort);
  }
}
