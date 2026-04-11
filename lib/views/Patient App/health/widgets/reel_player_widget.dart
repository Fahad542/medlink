import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medlink/models/health_video_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:medlink/views/Patient App/health/health_hub_viewmodel.dart';

class ReelPlayerWidget extends StatefulWidget {
  final HealthVideo video;
  final bool isActive;

  const ReelPlayerWidget({
    super.key,
    required this.video,
    required this.isActive,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;
  bool _initialized = false;
  bool _hasError = false;
  bool _showLikeAnimation = false;
  bool _isLikedLocal = false;
  late AnimationController _likeAnimationController;

  @override
  void initState() {
    super.initState();
    _isLikedLocal = widget.video.likedByMe;
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkAndInitPlayer();
  }

  void _checkAndInitPlayer() {
    final url = widget.video.videoUrl;
    if (widget.isActive) {
      Provider.of<HealthHubViewModel>(context, listen: false).recordReelView(widget.video.id);
    }
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      _isYoutube = true;
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            disableDragSeek: true,
            loop: true,
            isLive: false,
            forceHD: false,
            enableCaption: false,
            hideControls: true,
          ),
        );
        _initialized = true;
      } else {
        _hasError = true;
      }
    } else {
      _isYoutube = false;
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _initialized = true;
              _videoController!.setLooping(true);
              if (widget.isActive) {
                _videoController!.play();
              }
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
    }
  }

  void _handleDoubleTap() {
    if (!_isLikedLocal) {
      Provider.of<HealthHubViewModel>(context, listen: false).toggleLikeReel(widget.video.id, false);
    }
    setState(() {
      _showLikeAnimation = true;
      _isLikedLocal = true;
    });
    _likeAnimationController.forward(from: 0).then((_) {
      setState(() {
        _showLikeAnimation = false;
      });
    });
  }

  void _togglePlayPause() {
    if (!_initialized) return;
    setState(() {
      if (_isYoutube) {
        if (_youtubeController!.value.isPlaying) {
          _youtubeController!.pause();
        } else {
          _youtubeController!.play();
        }
      } else {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      }
    });
  }

  @override
  void didUpdateWidget(ReelPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        Provider.of<HealthHubViewModel>(context, listen: false).recordReelView(widget.video.id);
        _videoController?.play();
        _youtubeController?.play();
      } else {
        _videoController?.pause();
        _youtubeController?.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Player Area
          GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: _handleDoubleTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hasError)
                  _buildErrorContent()
                else if (!_initialized)
                  const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                else if (_isYoutube)
                  _buildYoutubePlayer()
                else
                  _buildVideoPlayer(),
              ],
            ),
          ),

          // Like Animation Overlay
          if (_showLikeAnimation)
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.2).animate(
                  CurvedAnimation(
                      parent: _likeAnimationController,
                      curve: Curves.elasticOut),
                ),
                child:
                    const Icon(Icons.favorite, color: Colors.white, size: 100),
              ),
            ),

          // Overlay (Reels Style)
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
          child:
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildYoutubePlayer() {
    if (_youtubeController == null) return Container();

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: false,
        onReady: () {
          if (widget.isActive) {
            _youtubeController!.play();
          }
        },
      ),
      builder: (context, player) {
        return Center(
          child: IgnorePointer(child: player),
        );
      },
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined,
              color: Colors.white.withOpacity(0.5), size: 64),
          const SizedBox(height: 16),
          Text(
            "Video check in progress...",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    final bool isPlaying = _isYoutube
        ? (_youtubeController?.value.isPlaying ?? false)
        : (_videoController?.value.isPlaying ?? false);

    return Stack(
      children: [
        // Gradient
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.2, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Play Indicator
        if (_initialized && !isPlaying)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    size: 60, color: Colors.white70),
              ),
            ),
          ),

        // Side Buttons
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: _isLikedLocal
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: _isLikedLocal ? Colors.red : Colors.white,
                label: (_isLikedLocal
                        ? (widget.video.likeCount +
                            (widget.video.likedByMe ? 0 : 1))
                        : (widget.video.likeCount -
                            (widget.video.likedByMe ? 1 : 0)))
                    .toString(),
                onTap: () {
                  Provider.of<HealthHubViewModel>(context, listen: false)
                      .toggleLikeReel(widget.video.id, _isLikedLocal);
                  setState(() {
                    _isLikedLocal = !_isLikedLocal;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.remove_red_eye_outlined,
                label: widget.video.viewCount.toString(),
                onTap: () {},
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.share_rounded,
                label: "Share",
                onTap: () {
                  Share.share(
                      'Check out this health video: ${widget.video.title}\n${widget.video.videoUrl}');
                },
              ),
            ],
          ),
        ),

        // Bottom Info
        Positioned(
          left: 16,
          bottom: 30,
          right: 80,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: const Icon(Icons.health_and_safety,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "@medlink_health",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.video.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.video.description != null &&
                    widget.video.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.video.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Progress Bar
        if (!_isYoutube && _initialized)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF009B8B),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [const Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
        ],
      ),
    );
  }
}
