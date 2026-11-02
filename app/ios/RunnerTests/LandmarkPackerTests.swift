import MLKitPoseDetection
import XCTest

@testable import pose_camera

/// The iOS half of the wire contract, checked without a camera.
///
/// The mirror of `LandmarkPackerTest.kt`, and the test that this project
/// has wanted since M4: the Kotlin one has never run, because a Gradle unit
/// test needs an example app to host it and the plugin has none. The iOS
/// one has a host — the Runner's own test target — so this is the first
/// native arithmetic in Spottr that anything automated compiles on every
/// push, and runs wherever ML Kit will link against a simulator.
///
/// What it cannot do is prove the model's output is what this assumes. That
/// is a device question, and `docs/dev-loop.md` says where to look.
final class LandmarkPackerTests: XCTestCase {
  private func landmark(
    _ type: Int,
    x: Float = 0,
    y: Float = 0,
    z: Float = 0,
    likelihood: Float = 1
  ) -> SourceLandmark {
    SourceLandmark(type: type, x: x, y: y, z: z, likelihood: likelihood)
  }

  func testBufferMatchesTheDartContract() {
    let buffer = LandmarkPacker.pack([], width: 100, height: 100)

    XCTAssertEqual(buffer.count, 132)
    XCTAssertEqual(LandmarkPacker.jointCount, 33)
    XCTAssertEqual(LandmarkPacker.valuesPerJoint, 4)
  }

  func testWritesEachJointAtItsOrdinalOffset() {
    // Joint 25 is the left knee. Four floats a joint, so it starts at 100,
    // and an off-by-one here is a left knee that arrives as a right one.
    let buffer = LandmarkPacker.pack(
      [landmark(25, x: 50, y: 25, z: 10, likelihood: 0.5)],
      width: 100, height: 50)

    XCTAssertEqual(buffer[100], 0.5, accuracy: 1e-6)
    XCTAssertEqual(buffer[101], 0.5, accuracy: 1e-6)
    XCTAssertEqual(buffer[102], 0.1, accuracy: 1e-6)
    XCTAssertEqual(buffer[103], 0.5, accuracy: 1e-6)
  }

  func testNormalizesByTheImageItWasGiven() {
    let buffer = LandmarkPacker.pack(
      [landmark(0, x: 120, y: 80)],
      width: 480, height: 640)

    XCTAssertEqual(buffer[0], 0.25, accuracy: 1e-6)
    XCTAssertEqual(buffer[1], 0.125, accuracy: 1e-6)
  }

  func testMarksAJointTheModelDidNotPlaceAsAbsent() {
    // Not zero. (0, 0) is the top left corner of the image, and a form rule
    // cannot tell that apart from a real measurement.
    let buffer = LandmarkPacker.pack(
      [landmark(0, x: 10, y: 10)],
      width: 100, height: 100)

    XCTAssertFalse(buffer[0].isNaN)
    XCTAssertTrue(buffer[4].isNaN)
    XCTAssertTrue(buffer[5].isNaN)
  }

  func testIgnoresALandmarkTypeOutsideTheContract() {
    let buffer = LandmarkPacker.pack(
      [landmark(33, x: 10, y: 10), landmark(-1, x: 10, y: 10)],
      width: 100, height: 100)

    for joint in 0..<LandmarkPacker.jointCount {
      XCTAssertTrue(buffer[joint * 4].isNaN)
    }
  }

  func testDoesNotMirrorAnything() {
    // The front lens is displayed mirrored and Flutter does that, to the
    // preview and the overlay together. Flipping x here as well would
    // cancel it on screen and reverse the landmark axis relative to
    // Android, which no form rule should have to know about.
    let buffer = LandmarkPacker.pack(
      [landmark(0, x: 10, y: 50)],
      width: 100, height: 100)

    XCTAssertEqual(buffer[0], 0.1, accuracy: 1e-6)
  }

  func testConfidenceIsZeroWhenThereIsNoPose() {
    XCTAssertEqual(LandmarkPacker.confidence([]), 0)
  }

  func testConfidenceAveragesOverEveryJointNotJustTheReportedOnes() {
    // A frame with three confident joints is not a confident frame. The
    // framing check reads this to decide whether it can see anybody.
    let confidence = LandmarkPacker.confidence([
      landmark(0, likelihood: 1),
      landmark(1, likelihood: 1),
      landmark(2, likelihood: 1),
    ])

    XCTAssertEqual(confidence, 3.0 / 33.0, accuracy: 1e-6)
  }

  func testUprightSizeTransposesForAQuarterTurn() {
    XCTAssertTrue(LandmarkPacker.uprightSize(width: 640, height: 480, rotationDegrees: 90) == (480, 640))
    XCTAssertTrue(LandmarkPacker.uprightSize(width: 640, height: 480, rotationDegrees: 270) == (480, 640))
    XCTAssertTrue(LandmarkPacker.uprightSize(width: 640, height: 480, rotationDegrees: 0) == (640, 480))
  }
}

/// The ordinal table, which is the part of the iOS port that has no Android
/// equivalent: there, the landmark type *is* the index.
final class PoseLandmarkOrdinalTests: XCTestCase {
  func testNamesEveryJointExactlyOnce() {
    // The likeliest way to break this file is a duplicated or a missing
    // line, and either one silently remaps every joint after it.
    XCTAssertEqual(PoseLandmarkOrdinal.order.count, LandmarkPacker.jointCount)
    XCTAssertEqual(Set(PoseLandmarkOrdinal.order).count, LandmarkPacker.jointCount)
  }

  func testIndexesInBlazePoseOrder() {
    // The three the whole skeleton hangs off, and the ones a form rule
    // would get wrong most visibly.
    XCTAssertEqual(PoseLandmarkOrdinal.index(of: .nose), 0)
    XCTAssertEqual(PoseLandmarkOrdinal.index(of: .leftShoulder), 11)
    XCTAssertEqual(PoseLandmarkOrdinal.index(of: .rightShoulder), 12)
    XCTAssertEqual(PoseLandmarkOrdinal.index(of: .leftHip), 23)
    XCTAssertEqual(PoseLandmarkOrdinal.index(of: .leftKnee), 25)
    XCTAssertEqual(PoseLandmarkOrdinal.index(of: .leftAnkle), 27)
  }

  func testLeftAndRightAreNeverTheSameSlot() {
    // A swapped pair draws a figure that is exactly right until a form rule
    // reads it.
    for (left, right) in [
      (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
      (.leftElbow, .rightElbow),
      (.leftWrist, .rightWrist),
      (.leftHip, .rightHip),
      (.leftKnee, .rightKnee),
      (.leftAnkle, .rightAnkle),
      (.leftHeel, .rightHeel),
      (.leftToe, .rightToe),
    ] {
      XCTAssertNotEqual(
        PoseLandmarkOrdinal.index(of: left),
        PoseLandmarkOrdinal.index(of: right))
    }
  }
}
