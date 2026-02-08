import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static final String? exchangeApi = dotenv.env['EXCHANGE_API'];
  static final String? supabaseUrl = dotenv.env['SUPABASE_URL'];
  static final String? supabaseKey = dotenv.env['SUPABASE_KEY'];
  static final String? enviroment = dotenv.env['ENVIROMENT'];
}