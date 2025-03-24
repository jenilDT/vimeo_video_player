import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VimeoVideoPlayer extends StatefulWidget {
  /// Defines the vimeo video ID to be played
  ///
  /// [videoId] is required and cannot be empty
  final String videoId;

  /// Used to auto-play the video once initialized
  ///
  /// Default value: [false]
  final bool isAutoPlay;

  /// Used to play the video in a loop after it ends
  ///
  /// Default value: [false]
  final bool isLooping;

  /// Used to play the video with the sound muted
  ///
  /// Default value: [false]
  final bool isMuted;

  /// Used to display the video title
  ///
  /// Default value: [false]
  final bool showTitle;

  /// Used to display the video byline/author
  ///
  /// Default value: [false]
  final bool showByline;

  /// Used to display the vimeo logo
  ///
  /// Default value: [false]
  final bool badge;

  /// Used to display the profile avatar
  ///
  /// Default value: [false]
  final bool portrait;

  /// Used to display the video playback controls
  ///
  /// Default value: [true]
  final bool showControls;

  /// Used to enable Do Not Track (DNT) mode
  /// When enabled, the player will not track any viewing information
  ///
  /// Default value: [true]
  final bool enableDNT;

  /// Defines the background color of the InAppWebView
  ///
  /// Default Value: [Colors.black]
  final Color backgroundColor;

  /// Defines a callback function triggered when the player is ready to play the video
  final VoidCallback? onReady;

  /// Defines a callback function triggered when the video begins playing
  final VoidCallback? onPlay;

  /// Defines a callback function triggered when the video is paused
  final VoidCallback? onPause;

  /// Defines a callback function triggered when the video playback finishes
  final VoidCallback? onFinish;

  /// Defines a callback function triggered when the video playback position is modified
  final VoidCallback? onSeek;

  /// Defines a callback function triggered when the WebView is created
  final Function(InAppWebViewController controller)? onInAppWebViewCreated;

  /// Defines a callback function triggered when the WebView starts to load an url
  final Function(InAppWebViewController controller, WebUri? url)?
      onInAppWebViewLoadStart;

  /// Defines a callback function triggered when the WebView finishes loading an url
  final Function(InAppWebViewController controller, WebUri? url)?
      onInAppWebViewLoadStop;

  /// Defines a callback function triggered when the WebView encounters an error loading a request
  final Function(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  )? onInAppWebViewReceivedError;

  VimeoVideoPlayer({
    super.key,
    required this.videoId,
    this.isAutoPlay = false,
    this.isLooping = false,
    this.isMuted = false,
    this.showTitle = false,
    this.showByline = false,
    this.showControls = true,
    this.enableDNT = true,
    this.portrait = false,
    this.badge = false,
    this.backgroundColor = Colors.black,
    this.onReady,
    this.onPlay,
    this.onPause,
    this.onFinish,
    this.onSeek,
    this.onInAppWebViewCreated,
    this.onInAppWebViewLoadStart,
    this.onInAppWebViewLoadStop,
    this.onInAppWebViewReceivedError,
  }) : assert(videoId.isNotEmpty, 'videoId cannot be empty!');

  @override
  _VimeoVideoPlayerState createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _buildHtmlContent(widget.videoId),
        ),
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useHybridComposition: true,
          javaScriptEnabled: true,
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;

          // Handle JavaScript callbacks
          controller.addJavaScriptHandler(
            handlerName: 'onVimeoEvent',
            callback: (args) {
              String event = args.isNotEmpty ? args[0].toString() : "unknown";
              debugPrint("Vimeo Event: $event");

              if (event == "play") widget.onPlay?.call();
              if (event == "pause") widget.onPause?.call();
              if (event == "ready") widget.onReady?.call();
              if (event == "seek") widget.onSeek?.call();
              if (event == "finish") widget.onFinish?.call();
            },
          );

          controller.addJavaScriptHandler(
            handlerName: 'onEnterFullscreen',
            callback: (args) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeRight,
                DeviceOrientation.landscapeLeft,
              ]);
            },
          );

          controller.addJavaScriptHandler(
            handlerName: 'onExitFullscreen',
            callback: (args) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
            },
          );
        },
        onLoadStop: (controller, url) {
          controller.evaluateJavascript(source: """
                    document.addEventListener('fullscreenchange', function() {
                      if (document.fullscreenElement) {
                        window.flutter_inappwebview.callHandler('onEnterFullscreen');
                      } else {
                        window.flutter_inappwebview.callHandler('onExitFullscreen');
                      }
                    });
                  """);
        },
      ),
    );
  }

  String _buildHtmlContent(String videoId) {
    return '''
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          body {
            margin: 0;
            padding: 0;
            background-color: ${_colorToHex(Colors.black)};
          }
          .video-container {
            position: relative;
            width: 100%;
            height: 100vh;
          }
          iframe {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
          }
        </style>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <script src="https://player.vimeo.com/api/player.js"></script>
    </head>
    <body>
      <iframe id="vimeoPlayer" src="${_buildIframeUrl()}" 
      frameborder="0" allow="autoplay; fullscreen; picture-in-picture"allowfullscreen 
            webkitallowfullscreen 
            mozallowfullscreen>
      </iframe>

      <script>
        var iframe = document.getElementById('vimeoPlayer');
        var player = new Vimeo.Player(iframe);

        player.on('play', function() {
          window.flutter_inappwebview.callHandler('onVimeoEvent', 'play');
        });

        player.on('pause', function() {
          window.flutter_inappwebview.callHandler('onVimeoEvent', 'pause');
        });

        player.on('loaded', function() {
          window.flutter_inappwebview.callHandler('onVimeoEvent', 'ready');
        });

        player.on('seeked', function() {
          window.flutter_inappwebview.callHandler('onVimeoEvent', 'seek');
        });

        player.on('ended', function() {
          window.flutter_inappwebview.callHandler('onVimeoEvent', 'finish');
        });
      </script>
    </body>
    </html>
    ''';
  }

  String _buildIframeUrl() {
    return 'https://player.vimeo.com/video/${widget.videoId}?'
        'autoplay=${widget.isAutoPlay}'
        '&loop=${widget.isLooping}'
        '&muted=${widget.isMuted}'
        '&title=${widget.showTitle}'
        '&byline=${widget.showByline}'
        '&portrait=${widget.portrait}'
        '&badge=${widget.badge}'
        '&controls=${widget.showControls}'
        '&dnt=${widget.enableDNT}';
  }

  /// Converts Color to a hexadecimal string
  String _colorToHex(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2)}'; // Remove the leading 'ff' for opacity
  }
}
