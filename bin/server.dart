import 'dart:io';
import 'package:appengine/appengine.dart';
import 'package:http/http.dart' as http;

const ipMetadataUrl = "http://metadata/computeMetadata/v1beta1/instance/network-interfaces/0/access-configs/0/external-ip";
const metadataHeaders = const {
  "Metadata-Flavor": "Google"
};
var wsHost = "localhost";

main(List<String> args) {
  http.get(ipMetadataUrl, headers: metadataHeaders).then((res) => wsHost = res.body);
  
  runAppEngine(handleRequest, onError: (e) => print("An error occurred $e"));
}

handleRequest(HttpRequest req) {
  if (req.uri.path == '/ws/url') {
    req.response
        ..write("ws://$wsHost:8080/ws")
        ..close();
  } else if (req.uri.path == '/ws') {
    WebSocketTransformer.upgrade(req).then(handleWebSocket);
  } else {
    context.assets.serve();
  }
}

void handleWebSocket(WebSocket ws) {
  ws.listen((data) => ws.add("PONG: $data"));
}