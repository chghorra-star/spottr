import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pose_camera_method_channel.dart';

abstract class PoseCameraPlatform extends PlatformInterface {
  /// Constructs a PoseCameraPlatform.
  PoseCameraPlatform() : super(token: _token);

  static final Object _token = Object();

  static PoseCameraPlatform _instance = MethodChannelPoseCamera();

  /// The default instance of [PoseCameraPlatform] to use.
  ///
  /// Defaults to [MethodChannelPoseCamera].
  static PoseCameraPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PoseCameraPlatform] when
  /// they register themselves.
  static set instance(PoseCameraPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
