import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static final String? exchangeApi = dotenv.env['EXCHANGE_API'];
}