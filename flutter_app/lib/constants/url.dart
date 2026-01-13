import 'package:flutter_dotenv/flutter_dotenv.dart';


final String baseURL = dotenv.env['BASE_URL1'] ?? 'http://localhost:3000';
