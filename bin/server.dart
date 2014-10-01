import 'dart:io';
import 'dart:async';

var content = '''<html>
  <head>
    <script type="application/javascript">
      var output = function(data) { document.write(data + "<br>"); };
      var socket = new WebSocket("ws://" + location.host + "/ws");
      socket.onopen = function(event) {
        output('Socket opened');
        socket.send("Hello");
        socket.send("World!");
      };
      socket.onmessage = function(event) {
        output('Message ' + event.data);
      }
    </script>    
  </head>
  <body>...</body>
</html>''';

main(List<String> args) {
  runZoned(() {
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