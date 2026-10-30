import 'package:flutter_test/flutter_test.dart';
import 'package:pose_camera/pose_camera.dart';
import 'package:pose_camera/pose_camera_platform_interface.dart';
import 'package:pose_camera/pose_camera_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPoseCameraPlatform
    with MockPlatformInterfaceMixin
    implements PoseCameraPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PoseCameraPlatform initialPlatform = PoseCameraPlatform.instance;

  test('$MethodChannelPoseCamera is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPoseCamera>());
  });

  test('getPlatformVersion', () async {
    final PoseCamera poseCameraPlugin = PoseCamera();
    final MockPoseCameraPlatform fakePlatform = MockPoseCameraPlatform();
    PoseCameraPlatform.instance = fakePlatform;

    expect(await poseCameraPlugin.getPlatformVersion(), '42');
  });
}
