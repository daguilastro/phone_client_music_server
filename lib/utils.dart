import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';

final TextEditingController ipController = TextEditingController();
final TextEditingController urlController = TextEditingController();
Socket? _socket;

Future<void> conectar() async {
  final input = ipController.text.trim();

  // Separar IP y puerto
  final parts = input.split(':');
  if (parts.length != 2) {
    print('Formato inválido. Usa: ip:puerto');
    return;
  }

  final ip = parts[0];
  final port = int.tryParse(parts[1]);
  if (port == null) {
    print('Puerto inválido.');
    return;
  }

  try {
    _socket = await Socket.connect(ip, port);
    print('Conectado a $ip:$port');
    
    // Escuchar datos del servidor
    _socket!.listen((data) {
      print('Recibido: ${String.fromCharCodes(data)}');
    });

  } catch (e) {
    print('Error al conectar: $e');
  }
}

Future<void> addSong(String url) async {
  final socket = _socket;
  if (socket == null) {
    print('No hay conexión activa con el servidor.');
    return;
  }

  final raw = url.trim();
  if (raw.isEmpty) {
    print('La URL está vacía.');
    return;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    print('URL inválida.');
    return;
  }

  final host = uri.host.toLowerCase();
  final isYoutubeHost =
      host == 'youtube.com' ||
      host == 'www.youtube.com' ||
      host == 'm.youtube.com' ||
      host == 'music.youtube.com' ||
      host == 'youtu.be' ||
      host == 'www.youtu.be';

  if (!isYoutubeHost) {
    print('Solo se permiten URLs de YouTube o YouTube Music.');
    return;
  }

  final hasPlaylistId = uri.queryParameters.containsKey('list');
  final isPlaylistPath = uri.path.toLowerCase().contains('/playlist');
  if (hasPlaylistId || isPlaylistPath) {
    print('No se permiten playlists por el momento.');
    return;
  }

  final hasVideoId =
      (host.contains('youtu.be') && uri.pathSegments.isNotEmpty) ||
      uri.queryParameters.containsKey('v');

  if (!hasVideoId) {
    print('La URL no parece ser de una canción/video individual.');
    return;
  }

  final urlBytes = utf8.encode(raw);
  final argSize = urlBytes.length;
  final payloadLength = 2 + argSize; // 2 bytes para arg_size + URL

  final messageLength = 5 + payloadLength;
  final message = Uint8List(messageLength);

  // Byte 0: tipo de comando
  message[0] = 1;

  // Bytes 1-4: payload_length en big-endian
  final payloadLenData = ByteData(4)..setUint32(0, payloadLength, Endian.big);
  for (int i = 0; i < 4; i++) {
    message[1 + i] = payloadLenData.getUint8(i);
  }

  // Bytes 5-6: arg_size en big-endian (2 bytes)
  final argSizeData = ByteData(2)..setUint16(0, argSize, Endian.big);
  message[5] = argSizeData.getUint8(0);
  message[6] = argSizeData.getUint8(1);

  // Bytes 7-...: URL
  message.setRange(7, messageLength, urlBytes);

  final asBinary = message.map((b) => b.toRadixString(2).padLeft(8, '0')).join(' ');
  print('Mensaje completo (binario):');
  print(asBinary);

  final commandTypeBinary = message[0].toRadixString(2).padLeft(8, '0');
  final payloadLenBinary = message
      .sublist(1, 5)
      .map((b) => b.toRadixString(2).padLeft(8, '0'))
      .join(' ');
  final argSizeBinary = message
      .sublist(5, 7)
      .map((b) => b.toRadixString(2).padLeft(8, '0'))
      .join(' ');
  final urlBinary = message
      .sublist(7)
      .map((b) => b.toRadixString(2).padLeft(8, '0'))
      .join(' ');

  print('Mensaje por partes:');
  print('Byte 0 (tipo comando): $commandTypeBinary');
  print('Bytes 1-4 (payload_length, big endian): $payloadLenBinary');
  print('Bytes 5-6 (arg_size, big endian): $argSizeBinary');
  print('Bytes 7-... (URL): $urlBinary');

  socket.add(message);
  await socket.flush();
  print('Comando addSong enviado.');
}
