#
# Run `pod lib lint pose_camera.podspec` to validate.
#
Pod::Spec.new do |s|
  s.name             = 'pose_camera'
  s.version          = '0.1.0'
  s.summary          = 'On-device pose estimation streaming landmark frames to Dart.'
  s.description      = <<-DESC
AVFoundation capture and ML Kit pose inference. Landmark frames cross the
bridge as a flat Float32 buffer; pixel buffers never do.
                       DESC
  s.homepage         = 'https://github.com/spottr/spottr'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Spottr' => 'ch.ghorra@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'pose_camera/Sources/pose_camera/**/*'
  s.dependency 'Flutter'

  # The same model Android runs, on purpose. Apple's Vision framework would
  # be one less dependency and nineteen joints instead of thirty-three, with
  # no heel and no toe — so `heel_lift` would silently stop existing and
  # every threshold in the coach engine would mean something different
  # depending on which phone it ran on. Parity is worth the pod.
  s.dependency 'GoogleMLKit/PoseDetection'

  # ML Kit's minimum, and above Flutter's.
  s.platform = :ios, '15.0'

  # ML Kit ships no arm64 simulator slice, so an Apple Silicon Mac cannot
  # run this in a simulator at all. CI builds for a device without signing
  # for that reason, and so does anybody wanting to check it compiles.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64'
  }
  s.swift_version = '5.0'

  s.resource_bundles = {'pose_camera_privacy' => ['pose_camera/Sources/pose_camera/PrivacyInfo.xcprivacy']}
end
