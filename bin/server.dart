import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

var content = '''<html>
  <head>
    <script type="application/javascript">
      var output = function(data) { document.write(data + "<br>"); };

      var http = new XMLHttpRequest();
      http.open('GET', "http://" + location.host + "/ws/url");
      http.onreadystatechange = function(e) {
        if (this.readyState == this.DONE) {
          var socket = new WebSocket(http.responseText);
          socket.onopen = function(event) {
            output('Socket opened');
            socket.send("Hello");
            socket.send("World!");
          };
          socket.onerror = function(event) {
            console.log(event);
          };
          socket.onmessage = function(event) {
            output('Message ' + event.data);
          }

        }
      };
      http.send();
    </script>    
  </head>
  <body>...</body>
</html>''';

const ipMetadataUrl = "http://metadata/computeMetadata/v1beta1/instance/network-interfaces/0/access-configs/0/external-ip";
const metadataHeaders = const {
  "Metadata-Flavor": "Google"
};
var wsHost = "localhost";

main(List<String> args) {
  runZoned(() {
    http.get(ipMetadataUrl, headers: metadataHeaders).then((res) => wsHost = res.body);

    HttpServer.bind(InternetAddress.ANY_IP_V4, 8080).then((HttpServer server) {
      print("Listening on ws://localhost:8080/ws");

      server.listen((HttpRequest req) {
        sendOk(HttpRequest req) => (req.response
            ..headers.add('Content-Type', 'text/plain')
            ..write('ok')).close();

        if (req.uri.path == '/_ah/health' || req.uri.path == '/_ah/start') {
          sendOk(req);
        } else if (req.uri.path == '/_ah/stop') {
          sendOk(req).then((_) => exit(0));
        } else if (req.uri.path == '/ws/url') {
          req.response
              ..write("ws://$wsHost:8080/ws")
              ..close();          
        } else if (req.uri.path == '/ws') {
          WebSocketTransformer.upgrade(req).then(handleWebSocket);
        } else {
          req.response
              ..headers.add('Content-Type', 'text/html')
              ..write(content)
              ..close();
        }
      });
    });
  }, onError: (e) => print("An error occurred $e"));
}

void handleWebSocket(WebSocket ws) {
  ws.listen((data) => ws.add("PONG: $data"));
}
