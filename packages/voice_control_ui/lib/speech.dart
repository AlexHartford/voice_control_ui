import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ibm_watson_assistant/models.dart';
import 'package:speech_to_text/speech_recognition_event.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:voice_control_ui/chatbot.dart';

const WAKE_WORD = 'board';

final sttProvider = Provider<SpeechToTextProvider>((_) => SpeechToTextProvider(SpeechToText()));

final sttInitProvider =
    FutureProvider<bool>((ref) async => await ref.watch(sttProvider).initialize());

final sttStreamProvider = StreamProvider<SpeechRecognitionEvent>((ref) {
  final stt = ref.watch(sttProvider);
  if (stt.isAvailable) {
    debugPrint('Initialized speech-to-text stream');
    return stt.stream;
  } else {
    throw Exception('Failed to initialize speech-to-text stream');
  }
});

class SpeechState {
  bool isListening;
  String input;
  IbmWatsonAssistantResponse output;

  SpeechState({
    this.isListening = false,
    this.input = '',
    this.output,
  });
}

class SpeechHandler extends StateNotifier<SpeechState> {
  SpeechHandler(this.ref) : super(SpeechState()) {
    print('SpeechHandler init');
    _listen();
  }

  final ProviderReference ref;

  static final provider = StateNotifierProvider<SpeechHandler>((ref) => SpeechHandler(ref));

  toggleListening() {
    state = SpeechState(
      isListening: !state.isListening,
      input: state.input,
      output: state.output,
    );
  }

  _listen() {
    final stt = ref.read(sttProvider)..listen(partialResults: true, pauseFor: const Duration(seconds: 2));
    final stream = ref.read(sttStreamProvider.stream);
    final chatbot = ref.read(ChatbotService.provider);

    stream.listen((event) async {
      print('event: ${event.eventType}');

      switch (event.eventType) {
        case SpeechRecognitionEventType.finalRecognitionEvent:
          if (event.recognitionResult.recognizedWords.contains(WAKE_WORD) || state.isListening) {
            final text = event.recognitionResult.recognizedWords;
            state = SpeechState(
              isListening: false,
              input: text,
              output: state.output,
            );
            // TODO: Add some sort of loading indicator
            state = SpeechState(
              isListening: state.isListening,
              input: state.input,
              output: await chatbot.sendInput(text),
            );
          }
          stt.listen(partialResults: true, pauseFor: const Duration(seconds: 2));
          break;
        case SpeechRecognitionEventType.partialRecognitionEvent:
          if (event.recognitionResult.recognizedWords.contains(WAKE_WORD) || state.isListening) {
            print('Waking up!!');
            state = SpeechState(
              isListening: true,
              input: event.recognitionResult.recognizedWords,
              output: state.output,
            );
          } else {
            print('Not waking up to: ${event.recognitionResult.recognizedWords}');
          }
          break;
        case SpeechRecognitionEventType.errorEvent:
          print('errorEvent: ${event.error}');
          stt.listen(partialResults: true, pauseFor: const Duration(seconds: 2));
          break;
        case SpeechRecognitionEventType.statusChangeEvent:
          print('Status changed: ${event.isListening ? 'listening' : 'stopped'}');
          break;
        case SpeechRecognitionEventType.soundLevelChangeEvent:
          break;
      }
    });
  }
}
