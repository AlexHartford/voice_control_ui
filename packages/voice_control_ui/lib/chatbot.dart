import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ibm_watson_assistant/ibm_watson_assistant.dart';
import 'package:ibm_watson_assistant/models.dart';
import 'package:voice_control_ui/speech.dart';

class ChatbotService {
  IbmWatsonAssistant bot;
  String _sessionId;
  String get sessionId => _sessionId;

  ChatbotService() {
    final auth = IbmWatsonAssistantAuth(
      assistantId: DotEnv().env['ASSISTANT_ID'],
      url: DotEnv().env['ASSISTANT_URL'],
      apikey: DotEnv().env['API_KEY'],
    );

    this.bot = IbmWatsonAssistant(auth);
    print('Initialized Chatbot Service');
  }

  static final provider = Provider<ChatbotService>((_) => ChatbotService());

  Future<String> createSession() async {
    print('creating session');
    try {
      _sessionId = await bot.createSession();
    } catch (e) {
      print('session error: $e');
      return e;
    }
    print('created session: $_sessionId');
    return _sessionId;
  }

  Future<IbmWatsonAssistantResponse> sendInput(String input) async {
    input = input.replaceFirst(WAKE_WORD, '');
    print('Sending chatbot input: $input');
    if (_sessionId == null) await createSession();
    try {
      return await bot.sendInput(input, sessionId: _sessionId);
    } catch (e) {
      print('Error sending chatbot input: $input.\n$e');
      return e;
    }
  }

  Future<void> deleteSession() async {
    await bot.deleteSession(_sessionId);
    _sessionId = null;
  }
}
