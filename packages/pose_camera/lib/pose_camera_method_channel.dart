import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pose_camera_platform_interface.dart';

/// An implementation of [PoseCameraPlatform] that uses method channels.
class MethodChannelPoseCamera extends PoseCameraPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pose_camera');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
