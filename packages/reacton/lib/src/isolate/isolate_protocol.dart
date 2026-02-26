import 'dart:isolate';

/// Base class for all messages between isolates.
sealed class IsolateMessage {
  const IsolateMessage();
}

/// Sent when a reacton's value changes.
class ReactonValueChanged extends IsolateMessage {
  /// The reacton ref id.
  final int reactonRefId;

  /// The serialized value.
  final Object? serializedValue;

  const ReactonValueChanged(this.reactonRefId, this.serializedValue);
}

/// Request to subscribe to a reacton's changes.
class ReactonSubscribe extends IsolateMessage {
  final int reactonRefId;
  const ReactonSubscribe(this.reactonRefId);
}

/// Request to unsubscribe from a reacton's changes.
class ReactonUnsubscribe extends IsolateMessage {
  final int reactonRefId;
  const ReactonUnsubscribe(this.reactonRefId);
}

/// Initial handshake message sent when spawning a worker.
class HandshakeInit extends IsolateMessage {
  /// The reply port for the worker to send messages back.
  final SendPort replyPort;

  /// Initial values of all shared reactons.
  final Map<int, Object?> initialValues;

  const HandshakeInit(this.replyPort, this.initialValues);
}

/// Handshake response from the worker.
class HandshakeAck extends IsolateMessage {
  /// The worker's send port for receiving messages.
  final SendPort workerPort;

  const HandshakeAck(this.workerPort);
}
