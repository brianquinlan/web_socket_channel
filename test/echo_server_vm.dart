// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

Future<void> hybridMain(StreamChannel<Object?> channel) async {
  late HttpServer server;

  server = (await HttpServer.bind('localhost', 0))
    ..transform(WebSocketTransformer())
        .listen((WebSocket webSocket) => webSocket.listen((data) {
              if (data == 'close') {
                webSocket.close(3001, 'you asked me to');
              } else {
                webSocket.add(data);
              }
            }));

  channel.sink.add(server.port);
  await channel
      .stream.first; // Any writes indicates that the server should exit.
  unawaited(server.close());
}

/// Starts an WebSocket server that echos the payload of the request.
Future<StreamChannel<Object?>> startServer() async {
  final controller = StreamChannelController<Object?>(sync: true);
  unawaited(hybridMain(controller.foreign));
  return controller.local;
}
