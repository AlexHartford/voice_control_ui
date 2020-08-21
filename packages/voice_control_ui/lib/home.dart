import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:voice_control_ui/hybrid_widget.dart';
import 'package:voice_control_ui/speech.dart';

class Home extends HookWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = useTabController(initialLength: 3, initialIndex: 1);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hybrid UI Demo'),
        centerTitle: true,
        bottom: TabBar(
          controller: controller,
          tabs: [
            Hybrid(
              key: ValueKey('ADD'),
              onSelect: () => controller.animateTo(0),
              child: Tab(key: PageStorageKey('Scan'), text: 'Scan'),
            ),
            Hybrid(
              key: ValueKey('HOME'),
              onSelect: () => controller.animateTo(1),
              child: Tab(key: PageStorageKey('Home'), text: 'Home'),
            ),
            Hybrid(
              key: ValueKey('SEARCH'),
              onSelect: () => controller.animateTo(2),
              child: Tab(key: PageStorageKey('Search'), text: 'Search'),
            ),
          ],
        ),
      ),
      body: TabViews(controller),
    );
  }
}

class TabViews extends HookWidget {
  const TabViews(this.controller, {Key key}) : super(key: key);

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final sttAvailable = useProvider(sttInitProvider);

    final hybrid = useProvider(HybridService.provider);

    return sttAvailable.when(
      loading: () => Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Speech recognition not available.\n$err',
        ),
      ),
      data: (_) {
        return Stack(
          children: [
            TabBarView(
              controller: controller,
              children: [
                Container(
                  color: Colors.blue[300],
                ),
                Container(
                  child: Column(
                    children: [
                      RaisedButton(
                        child: Text('ADD'),
                        onPressed: () => hybrid.trigger('ADD'),
                      ),
                    ],
                  ),
                ),
                Container(color: Colors.red[300]),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ActivateVoiceButton(),
            ),
            Align(
              alignment: Alignment.center,
              child: SpeechDisplay(),
            ),
          ],
        );
      },
    );
  }
}

class SpeechDisplay extends HookWidget {
  const SpeechDisplay({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final speech = useProvider(SpeechHandler.provider.state);

    return Container(
      child: Center(
        child: Card(
          color: Colors.grey[600].withOpacity(0.75),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  speech.input,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  speech.output?.responseText ?? 'N/A',
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivateVoiceButton extends HookWidget {
  const ActivateVoiceButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;
    final listening = useProvider(SpeechHandler.provider.state).isListening;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(bottom: listening ? 0 : 16),
      child: Card(
        elevation: 8,
        color: Colors.blueAccent,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(listening ? 0 : 25),
          ),
        ),
        child: InkWell(
          onTap: () => context.read(SpeechHandler.provider).toggleListening(),
          borderRadius: BorderRadius.all(
            Radius.circular(listening ? 0 : 25),
          ),
          splashColor: Colors.white70,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: listening ? 100 : 50,
            width: listening ? fullWidth : 100,
            child: listening
                ? SoundWaves()
                : Icon(
                    Icons.mic,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}

class SoundWaves extends HookWidget {
  SoundWaves({Key key}) : super(key: key);

  static const double barWidth = 3;
  static const double barHeight = 5;
  static const double spaceWidth = 2;

  final rng = Random();

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;

    return ListView.separated(
      itemCount: (fullWidth / (SoundWaves.barWidth + SoundWaves.spaceWidth)).ceil(),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, int index) {
        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: Colors.white,
            height: SoundWaves.barHeight + rng.nextInt(75),
            width: SoundWaves.barWidth,
          ),
        );
      },
      separatorBuilder: (_, __) => SizedBox(width: SoundWaves.spaceWidth),
    );
  }
}
