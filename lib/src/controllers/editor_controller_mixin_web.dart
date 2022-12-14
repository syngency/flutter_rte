import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_rich_text_editor/src/controllers/editor_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

abstract class PlatformSpecificMixin {
  ///
  String viewId = '';

  ///
  final String filePath =
      'packages/flutter_rich_text_editor/lib/assets/document.html';

  ///
  WebViewController get editorController =>
      throw Exception('webview controller does not exist on web.');

  ///
  set editorController(WebViewController controller) =>
      throw Exception('webview controller does not exist on web.');

  ///
  StreamSubscription<html.MessageEvent>? _eventSub;

  ///
  HtmlEditorController? _c;

  ///
  /// Helper function to run javascript and check current environment
  Future<void> evaluateJavascript({required Map<String, Object?> data}) async {
    if (_c == null) return;
    if (!(_c?.initialized ?? false)) {
      log('HtmlEditorController error:',
          error:
              'HtmlEditorController called an editor widget that\n does not exist.\n'
              'This may happen because the widget\n'
              'initialization has been called but not completed,\n'
              'or because the editor widget was destroyed.\n'
              'Method called: [${data['type']}]');
      return;
    }
    data['view'] = viewId;
    final jsonEncoder = JsonEncoder();
    var json = jsonEncoder.convert(data);
    html.window.postMessage(json, '*');
  }

  ///
  Future<void> init(
      BuildContext initBC, double initHeight, HtmlEditorController c) async {
    await _eventSub?.cancel();
    _eventSub = html.window.onMessage.listen((event) {
      c.processEvent(event.data);
    }, onError: (e, s) {
      log('Event stream error: ${e.toString()}');
      log('Stack trace: ${s.toString()}');
    }, onDone: () {
      log('Event stream done.');
    });

    final iframe = html.IFrameElement()
      ..width = MediaQuery.of(initBC).size.width.toString() //'800'
      ..height = '100%'
      // ignore: unsafe_html, necessary to load HTML string
      ..srcdoc = await c.getInitialContent()
      ..style.border = 'none'
      ..style.overflow = 'hidden'
      ..id = viewId
      ..onLoad.listen((event) async {
        var data = <String, Object>{'type': 'toIframe: initEditor'};
        data['view'] = viewId;
        final jsonEncoder = JsonEncoder();
        var jsonStr = jsonEncoder.convert(data);
        html.window.postMessage(jsonStr, '*');
      });
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) => iframe);
  }

  ///
  void dispose() {
    _eventSub?.cancel();
  }

  ///
  Widget view(HtmlEditorController controller) {
    _c = controller;
    return HtmlElementView(viewType: viewId);
  }
}
