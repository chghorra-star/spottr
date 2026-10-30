
import 'pose_camera_platform_interface.dart';

class PoseCamera {
  Future<String?> getPlatformVersion() {
    return PoseCameraPlatform.instance.getPlatformVersion();
  }
}
