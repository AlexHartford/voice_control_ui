import 'package:dotenv/dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ibm_watson_assistant/ibm_watson_assistant.dart';

class ChatbotService {
  IbmWatsonAssistant bot;
  String _sessionId;
  String get sessionId => _sessionId;

  ChatbotService() {
    load();

    final auth = IbmWatsonAssistantAuth(
      assistantId: env['ASSISTANT_ID'],
      url: env['ASSISTANT_URL'],
      apikey: env['API_KEY'],
    );

    this.bot = IbmWatsonAssistant(auth);
  }

  static final provider = Provider<ChatbotService>((_) => ChatbotService());

  Future<String> createSession() async {
    _sessionId = await bot.createSession();
    return _sessionId;
  }

  Future<void> deleteSession() async {
    await bot.deleteSession(_sessionId);
    _sessionId = null;
  }
}
