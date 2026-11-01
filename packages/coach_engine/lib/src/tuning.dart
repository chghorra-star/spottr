import 'package:meta/meta.dart';

import 'counter_catalog.dart';
import 'counter_config.dart';
import 'form_catalog.dart';
import 'form_rule.dart';

/// Knob ids whose value came from a measurement rather than from somebody
/// being plausible about anatomy.
///
/// One of them. The accuracy harness was asked how far the trunk-length
/// ratio travels across the whole fixture suite and the answer separated
/// into two groups, so `back_rounding.max` sits between them. Every other
/// number in this engine is a considered guess, and the point of listing
/// this set is that the ratio can be printed.
const Set<String> measuredKnobs = {'back_rounding.max'};

/// One number in the engine that somebody chose.
///
/// Thresholds are configuration so that tuning is a data edit rather than a
/// code change. A knob is the next step along: a tuner can enumerate every
/// number, turn one, and ask what it cost — without knowing which class the
/// number happens to live in.
@immutable
class Knob<T> {
  const Knob({
    required this.id,
    required this.value,
    required this.unit,
    required this.apply,
  });

  /// `<config id>.<field>`, unique across the engine.
  final String id;

  final double value;

  /// 'deg' for an angle, '%' for a ratio, 'ms' for a duration, 'x' for a
  /// bare share. A sweep has to know what a step of 1 means.
  final String unit;

  /// The same configuration with this number changed, and nothing else.
  final T Function(double value) apply;

  /// Whether this one has ever been compared against anything.
  bool get measured => measuredKnobs.contains(id);

  @override
  String toString() => '$id = $value$unit';
}

/// Every number a counter was given.
List<Knob<CounterConfig>> counterKnobs(CounterConfig config) =>
    switch (config) {
      final RepCounterConfig rep => _repKnobs(rep),
      final HoldCounterConfig hold => _holdKnobs(hold),
    };

RepCounterConfig _rep(
  RepCounterConfig from, {
  double? topThreshold,
  double? bottomThreshold,
  double? minRangeOfMotion,
  double? hysteresis,
  Duration? minRepDuration,
  Duration? maxRepDuration,
  Duration? maxTrackingGap,
}) =>
    RepCounterConfig(
      id: from.id,
      signal: from.signal,
      direction: from.direction,
      topThreshold: topThreshold ?? from.topThreshold,
      bottomThreshold: bottomThreshold ?? from.bottomThreshold,
      minRangeOfMotion: minRangeOfMotion ?? from.minRangeOfMotion,
      hysteresis: hysteresis ?? from.hysteresis,
      minRepDuration: minRepDuration ?? from.minRepDuration,
      maxRepDuration: maxRepDuration ?? from.maxRepDuration,
      maxTrackingGap: maxTrackingGap ?? from.maxTrackingGap,
    );

Duration _ms(double value) => Duration(milliseconds: value.round());

List<Knob<CounterConfig>> _repKnobs(RepCounterConfig c) => [
      Knob(
        id: '${c.id}.topThreshold',
        value: c.topThreshold,
        unit: 'deg',
        apply: (v) => _rep(c, topThreshold: v),
      ),
      Knob(
        id: '${c.id}.bottomThreshold',
        value: c.bottomThreshold,
        unit: 'deg',
        apply: (v) => _rep(c, bottomThreshold: v),
      ),
      Knob(
        id: '${c.id}.minRangeOfMotion',
        value: c.minRangeOfMotion,
        unit: 'deg',
        apply: (v) => _rep(c, minRangeOfMotion: v),
      ),
      Knob(
        id: '${c.id}.hysteresis',
        value: c.hysteresis,
        unit: 'deg',
        apply: (v) => _rep(c, hysteresis: v),
      ),
      Knob(
        id: '${c.id}.minRepDuration',
        value: c.minRepDuration.inMilliseconds.toDouble(),
        unit: 'ms',
        apply: (v) => _rep(c, minRepDuration: _ms(v)),
      ),
      Knob(
        id: '${c.id}.maxRepDuration',
        value: c.maxRepDuration.inMilliseconds.toDouble(),
        unit: 'ms',
        apply: (v) => _rep(c, maxRepDuration: _ms(v)),
      ),
      Knob(
        id: '${c.id}.maxTrackingGap',
        value: c.maxTrackingGap.inMilliseconds.toDouble(),
        unit: 'ms',
        apply: (v) => _rep(c, maxTrackingGap: _ms(v)),
      ),
    ];

HoldCounterConfig _bandAt(
  HoldCounterConfig from,
  int index, {
  double? min,
  double? max,
}) =>
    HoldCounterConfig(
      id: from.id,
      maxTrackingGap: from.maxTrackingGap,
      bands: [
        for (var i = 0; i < from.bands.length; i++)
          if (i == index)
            SignalBand(
              signal: from.bands[i].signal,
              min: min ?? from.bands[i].min,
              max: max ?? from.bands[i].max,
            )
          else
            from.bands[i],
      ],
    );

List<Knob<CounterConfig>> _holdKnobs(HoldCounterConfig c) => [
      for (var i = 0; i < c.bands.length; i++) ...[
        if (c.bands[i].min case final double min)
          Knob(
            id: '${c.id}.band$i.min',
            value: min,
            unit: c.bands[i].signal.unit,
            apply: (v) => _bandAt(c, i, min: v),
          ),
        if (c.bands[i].max case final double max)
          Knob(
            id: '${c.id}.band$i.max',
            value: max,
            unit: c.bands[i].signal.unit,
            apply: (v) => _bandAt(c, i, max: v),
          ),
      ],
      Knob(
        id: '${c.id}.maxTrackingGap',
        value: c.maxTrackingGap.inMilliseconds.toDouble(),
        unit: 'ms',
        apply: (v) => HoldCounterConfig(
          id: c.id,
          bands: c.bands,
          maxTrackingGap: _ms(v),
        ),
      ),
    ];

/// Every number a form rule was given.
///
/// A rule the engine does not evaluate has none: there is nothing to turn
/// on a rule that always answers "not implemented", and offering one would
/// suggest it could be tuned into working.
List<Knob<FormRule>> ruleKnobs(FormRule rule) => switch (rule) {
      final SignalBoundRule bound => [
          if (bound.min case final double min)
            Knob(
              id: '${bound.id}.min',
              value: min,
              unit: bound.signal.unit,
              apply: (v) => SignalBoundRule(
                id: bound.id,
                severity: bound.severity,
                signal: bound.signal,
                at: bound.at,
                min: v,
                max: bound.max,
              ),
            ),
          if (bound.max case final double max)
            Knob(
              id: '${bound.id}.max',
              value: max,
              unit: bound.signal.unit,
              apply: (v) => SignalBoundRule(
                id: bound.id,
                severity: bound.severity,
                signal: bound.signal,
                at: bound.at,
                min: bound.min,
                max: v,
              ),
            ),
        ],
      final SignalHoldRule band => [
          if (band.min case final double min)
            Knob(
              id: '${band.id}.min',
              value: min,
              unit: band.signal.unit,
              apply: (v) => SignalHoldRule(
                id: band.id,
                severity: band.severity,
                signal: band.signal,
                min: v,
                max: band.max,
                tolerance: band.tolerance,
              ),
            ),
          if (band.max case final double max)
            Knob(
              id: '${band.id}.max',
              value: max,
              unit: band.signal.unit,
              apply: (v) => SignalHoldRule(
                id: band.id,
                severity: band.severity,
                signal: band.signal,
                min: band.min,
                max: v,
                tolerance: band.tolerance,
              ),
            ),
          Knob(
            id: '${band.id}.tolerance',
            value: band.tolerance,
            unit: 'x',
            apply: (v) => SignalHoldRule(
              id: band.id,
              severity: band.severity,
              signal: band.signal,
              min: band.min,
              max: band.max,
              tolerance: v,
            ),
          ),
        ],
      final SignalTravelRule travel => [
          Knob(
            id: '${travel.id}.max',
            value: travel.max,
            unit: travel.signal.unit,
            apply: (v) => SignalTravelRule(
              id: travel.id,
              severity: travel.severity,
              signal: travel.signal,
              max: v,
            ),
          ),
        ],
      final RangeConsistencyRule range => [
          Knob(
            id: '${range.id}.minFraction',
            value: range.minFraction,
            unit: 'x',
            apply: (v) => RangeConsistencyRule(
              id: range.id,
              severity: range.severity,
              minFraction: v,
            ),
          ),
        ],
      final DescentShareRule descent => [
          Knob(
            id: '${descent.id}.minShare',
            value: descent.minShare,
            unit: 'x',
            apply: (v) => DescentShareRule(
              id: descent.id,
              severity: descent.severity,
              minShare: v,
            ),
          ),
        ],
      PendingRule() => const [],
    };

/// Every number the shipping engine was given, counters and rules together.
///
/// The list is the honest inventory: this is how many things somebody chose
/// without measuring, and it is the list a tuner works through once there is
/// footage to work against.
List<Knob<Object>> engineKnobs({
  Map<String, CounterConfig> counters = counterCatalog,
  Map<String, FormRule> rules = formCatalog,
}) =>
    [
      for (final config in counters.values) ...counterKnobs(config),
      for (final rule in rules.values) ...ruleKnobs(rule),
    ];
