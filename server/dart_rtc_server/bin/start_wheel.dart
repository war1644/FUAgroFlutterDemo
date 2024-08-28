import '../lib/rtc_server.dart';
import 'package:args/args.dart';

/*
 * Starts a wheel server
 */
void main(List<String> argv) {
  ArgParser argParser = new ArgParser();
  argParser.addOption('port', abbr: 'p', help: 'Port to use', defaultsTo: '8234');
  argParser.addOption('ip', abbr: 'i', help: 'Ip to use', defaultsTo: '0.0.0.0');
  var args = argParser.parse(argv);

  String port = args['port'];
  int p = int.parse(port);

  String ip = args['ip'];

  Server server = new WheelServer();
  try {
    server.listen(ip, p);
  } catch(e, s) {

  }
}



