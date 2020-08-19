import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ibm_watson_assistant/ibm_watson_assistant.dart';
import 'package:ibm_watson_assistant/models.dart';

// final botProvider = Provider<IbmWatsonAssistant>((ref) {
//   load();

//   final auth = IbmWatsonAssistantAuth(
//     assistantId: env['ASSISTANT_ID'],
//     url: env['ASSISTANT_URL'],
//     apikey: env['API_KEY'],
//   );

//   print('chatbot init');

//   return IbmWatsonAssistant(auth);
// });

// final sessionIdProvider = StateProvider<String>((_) => null);

class ChatbotService {
  IbmWatsonAssistant bot;
  String _sessionId;
  String get sessionId => _sessionId;

  IbmWatsonAssistantResponse lastRes;

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

  Future<String> sendInput(String input) async {
    input = input.replaceFirst('popcorn', '');
    print('Sending chatbot input: $input');
    if (_sessionId == null) await createSession();
    try {
      final res = await bot.sendInput(input, sessionId: _sessionId);
      print('sent input');
      lastRes = res;
      print(res.responseText);
      return res.responseText;
    } catch (e) {
      print('error: $e');
      return e;
    }
  }

  Future<void> deleteSession() async {
    await bot.deleteSession(_sessionId);
    _sessionId = null;
  }
}
