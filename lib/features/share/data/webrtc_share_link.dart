import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import 'share_link.dart';
import 'signaling_client.dart';

/// A WebRTC data-channel transport. It is used only when the local-network
/// path is unavailable, and it is identical for the sender and the receiver.
class WebRtcShareLink implements ShareLink {
  WebRtcShareLink(this._peer, this._channel, {this.path = SharePath.direct}) {
    _channel.onMessage = _onMessage;
    _channel.onDataChannelState = (state) {
      if (state == webrtc.RTCDataChannelState.RTCDataChannelClosed) {
        _fail(
          const ShareLinkException(
            'The WebRTC data channel closed.',
            code: 'closed',
          ),
        );
      }
    };
    _peer.onConnectionState = (state) {
      if (state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _fail(
          const ShareLinkException(
            'The WebRTC connection failed. Check both devices’ internet access '
            'and try again.',
            code: 'webrtc_failed',
          ),
        );
      }
    };
  }

  final webrtc.RTCPeerConnection _peer;
  final webrtc.RTCDataChannel _channel;
  final StreamController<Uint8List> _incoming =
      StreamController<Uint8List>.broadcast();
  final List<Future<void>> _pendingSends = <Future<void>>[];
  bool _closed = false;

  @override
  SharePath path;

  @override
  bool get isOpen =>
      !_closed &&
      _channel.state == webrtc.RTCDataChannelState.RTCDataChannelOpen;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  int get bufferedAmount => _channel.bufferedAmount ?? 0;

  @override
  int get preferredChunkBytes => 16 * 1024;

  @override
  void add(Uint8List bytes) {
    if (_closed) {
      throw const ShareLinkException('The connection is closed.');
    }
    _pendingSends.add(
      _channel.send(webrtc.RTCDataChannelMessage.fromBinary(bytes)).catchError((
        Object error,
      ) {
        _fail(
          const ShareLinkException(
            'The WebRTC connection was interrupted.',
            code: 'webrtc_failed',
          ),
        );
      }),
    );
  }

  @override
  Future<void> drain() async {
    while (_pendingSends.isNotEmpty) {
      final pending = _pendingSends.removeAt(0);
      await pending;
    }
    // Keep the SCTP buffer small so a slow receiver cannot make Relay allocate
    // without bound. 512 KiB is well below the platform's default high-water
    // mark while still allowing throughput on a normal link.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (bufferedAmount > 512 * 1024) {
      if (_closed) return;
      if (DateTime.now().isAfter(deadline)) {
        throw const ShareLinkException(
          'The receiving device stopped accepting data.',
          code: 'timeout',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 15));
    }
  }

  void _onMessage(webrtc.RTCDataChannelMessage message) {
    if (!message.isBinary) {
      _fail(
        const ShareLinkException(
          'The peer sent an unexpected text message.',
          code: 'protocol',
        ),
      );
      return;
    }
    if (!_incoming.isClosed) {
      _incoming.add(Uint8List.fromList(message.binary));
    }
  }

  void _fail(ShareLinkException error) {
    if (_closed) return;
    _closed = true;
    if (!_incoming.isClosed) _incoming.addError(error);
    if (!_incoming.isClosed) _incoming.close();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _channel.close();
    } catch (_) {
      // Already closed by the peer.
    }
    try {
      await _peer.close();
      await _peer.dispose();
    } catch (_) {
      // Platform teardown is best effort.
    }
    if (!_incoming.isClosed) await _incoming.close();
  }

  /// Confirms whether the selected ICE candidate pair is relayed through TURN.
  /// Unknown or unreadable stats are reported as a direct connection rather
  /// than claiming a relay was used.
  Future<void> detectPath() async {
    try {
      final reports = await _peer.getStats();
      final candidates = <String, webrtc.StatsReport>{};
      for (final report in reports) {
        if (report.type == 'local-candidate' ||
            report.type == 'remote-candidate') {
          candidates[report.id] = report;
        }
      }
      for (final report in reports) {
        if (report.type != 'candidate-pair') continue;
        final state = report.values['state'];
        final nominated = report.values['nominated'];
        if (state != 'succeeded' || nominated == false) continue;
        final localId = report.values['localCandidateId'];
        final local = candidates[localId];
        if (local != null && local.values['candidateType'] == 'relay') {
          path = SharePath.relayed;
          return;
        }
      }
    } catch (_) {
      // Keep the conservative default.
    }
  }
}

/// Creates both ends of a WebRTC data-channel session through the signaling
/// room. The sender creates the channel and the offer; the receiver answers.
class WebRtcNegotiator {
  const WebRtcNegotiator._();

  static const String channelLabel = 'relay-share';

  static Future<WebRtcShareLink> connectSender({
    required SignalingClient signaling,
    required RelayIceConfig ice,
    required Duration timeout,
  }) async {
    final peer = await _createPeer(ice);
    try {
      peer.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        unawaited(
          signaling.sendIce(
            candidate: candidate.candidate!,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex ?? 0,
          ),
        );
      };

      final channel = await peer.createDataChannel(
        channelLabel,
        webrtc.RTCDataChannelInit()
          ..ordered = true
          ..binaryType = 'binary',
      );

      final offer = await peer.createOffer();
      await peer.setLocalDescription(offer);
      await signaling.sendOffer(offer.sdp!);

      final pendingIce = <SignalingIceEvent>[];
      final deadline = DateTime.now().add(timeout);
      while (true) {
        final event = await signaling.next(
          timeout: _remaining(deadline, timeout),
        );
        if (event is SignalingIceEvent) {
          pendingIce.add(event);
          continue;
        }
        if (event is SignalingPeerLeft) {
          throw const ShareLinkException(
            'The other device left before the connection was ready.',
            code: 'peer_left',
          );
        }
        if (event is SignalingAnswerEvent) {
          await peer.setRemoteDescription(
            webrtc.RTCSessionDescription(event.sdp, 'answer'),
          );
          break;
        }
      }
      for (final candidate in pendingIce) {
        await _addIce(peer, candidate);
      }

      final link = WebRtcShareLink(peer, channel);
      await _awaitChannelOpen(channel, timeout);
      await link.detectPath();
      return link;
    } catch (error) {
      await _dispose(peer);
      if (error is ShareLinkException) rethrow;
      throw ShareLinkException(
        'Relay could not establish a direct connection. Try again, or move '
        'both devices to a less restrictive network.',
      );
    }
  }

  static Future<WebRtcShareLink> connectReceiver({
    required SignalingClient signaling,
    required RelayIceConfig ice,
    required Duration timeout,
  }) async {
    final peer = await _createPeer(ice);
    final channelCompleter = Completer<webrtc.RTCDataChannel>();
    peer.onDataChannel = (channel) {
      if (channel.label == channelLabel || channel.label == null) {
        if (!channelCompleter.isCompleted) channelCompleter.complete(channel);
      }
    };

    try {
      final pendingIce = <SignalingIceEvent>[];
      peer.onIceCandidate = (candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        unawaited(
          signaling.sendIce(
            candidate: candidate.candidate!,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex ?? 0,
          ),
        );
      };

      final deadline = DateTime.now().add(timeout);
      while (true) {
        final event = await signaling.next(
          timeout: _remaining(deadline, timeout),
        );
        if (event is SignalingIceEvent) {
          pendingIce.add(event);
          continue;
        }
        if (event is SignalingPeerLeft) {
          throw const ShareLinkException(
            'The sending device left before the connection was ready.',
            code: 'peer_left',
          );
        }
        if (event is SignalingOfferEvent) {
          await peer.setRemoteDescription(
            webrtc.RTCSessionDescription(event.sdp, 'offer'),
          );
          break;
        }
      }

      final answer = await peer.createAnswer();
      await peer.setLocalDescription(answer);
      await signaling.sendAnswer(answer.sdp!);

      for (final candidate in pendingIce) {
        await _addIce(peer, candidate);
      }

      final channel = await channelCompleter.future.timeout(
        _remaining(deadline, timeout),
        onTimeout: () => throw const ShareLinkException(
          'The sending device did not open the transfer channel.',
          code: 'webrtc_timeout',
        ),
      );
      final link = WebRtcShareLink(peer, channel);
      await _awaitChannelOpen(channel, _remaining(deadline, timeout));
      await link.detectPath();
      return link;
    } catch (error) {
      await _dispose(peer);
      if (error is ShareLinkException) rethrow;
      throw ShareLinkException(
        'Relay could not establish a direct connection. Try again, or move '
        'both devices to a less restrictive network.',
      );
    }
  }

  static Future<webrtc.RTCPeerConnection> _createPeer(
    RelayIceConfig ice,
  ) async {
    return webrtc.createPeerConnection({
      'iceServers': ice.servers,
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceCandidatePoolSize': 0,
    });
  }

  static Future<void> _addIce(
    webrtc.RTCPeerConnection peer,
    SignalingIceEvent event,
  ) async {
    try {
      await peer.addCandidate(
        webrtc.RTCIceCandidate(
          event.candidate,
          event.sdpMid ?? '0',
          event.sdpMLineIndex,
        ),
      );
    } catch (_) {
      // A candidate that arrived too late is harmless; ICE will use the rest.
    }
  }

  static Future<void> _awaitChannelOpen(
    webrtc.RTCDataChannel channel,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (channel.state != webrtc.RTCDataChannelState.RTCDataChannelOpen) {
      if (channel.state == webrtc.RTCDataChannelState.RTCDataChannelClosed) {
        throw const ShareLinkException(
          'The WebRTC data channel closed before the transfer started.',
          code: 'closed',
        );
      }
      if (DateTime.now().isAfter(deadline)) {
        throw const ShareLinkException(
          'The WebRTC connection was not ready in time.',
          code: 'webrtc_timeout',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  static Duration _remaining(DateTime deadline, Duration fallback) {
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      throw const ShareLinkException(
        'The connection attempt timed out.',
        code: 'timeout',
      );
    }
    return remaining < fallback ? remaining : fallback;
  }

  static Future<void> _dispose(webrtc.RTCPeerConnection peer) async {
    try {
      await peer.close();
      await peer.dispose();
    } catch (_) {
      // Best effort.
    }
  }
}
