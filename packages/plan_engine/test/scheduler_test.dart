import 'package:plan_engine/plan_engine.dart';
import 'package:test/test.dart';

List<int> weekdaysOf(WeekSchedule schedule) =>
    schedule.days.map((d) => d.weekday).toList();

List<DayType> typesOf(WeekSchedule schedule) =>
    schedule.days.map((d) => d.type).toList();

WeekSchedule scheduleFor(int daysPerWeek, {Set<int> runWeekdays = const {}}) =>
    PlanScheduler.schedule(
      template: WeekTemplate.forDays(daysPerWeek),
      runWeekdays: runWeekdays,
    );

void main() {
  group('WeekTemplate', () {
    test('picks full body for two or three days', () {
      expect(typesOf(scheduleFor(2)), [DayType.fullBody, DayType.fullBody]);
      expect(WeekTemplate.forDays(3).days.length, 3);
      expect(
        WeekTemplate.forDays(3).days.every((d) => d.type == DayType.fullBody),
        isTrue,
      );
    });

    test('picks upper/lower for four days and alternates them', () {
      expect(typesOf(scheduleFor(4)), [
        DayType.upper,
        DayType.lower,
        DayType.upper,
        DayType.lower,
      ]);
    });

    test('picks push/pull/legs plus upper/lower for five days', () {
      expect(WeekTemplate.forDays(5).days.map((d) => d.type), [
        DayType.push,
        DayType.pull,
        DayType.legs,
        DayType.upper,
        DayType.lower,
      ]);
    });

    test('picks a double push/pull/legs for six days', () {
      expect(WeekTemplate.forDays(6).days.map((d) => d.type), [
        DayType.push,
        DayType.pull,
        DayType.legs,
        DayType.push,
        DayType.pull,
        DayType.legs,
      ]);
    });

    test('rejects a frequency outside the supported range', () {
      expect(() => WeekTemplate.forDays(1), throwsA(isA<ArgumentError>()));
      expect(() => WeekTemplate.forDays(7), throwsA(isA<ArgumentError>()));
    });

    test('every template day carries an ARB label key', () {
      for (var days = 2; days <= 6; days++) {
        for (final day in WeekTemplate.forDays(days).days) {
          expect(day.labelKey, matches(RegExp(r'^day_[a-z_]+$')));
        }
      }
    });

    test('every slot of every template is reachable in a full gym', () {
      // A template that asks for something the catalog cannot supply would
      // silently produce short sessions for everyone.
      for (var days = 2; days <= 6; days++) {
        for (final day in WeekTemplate.forDays(days).days) {
          expect(day.slots, isNotEmpty);
          expect(
            day.slots.where((s) => s.priority == SlotPriority.primary),
            isNotEmpty,
            reason: '${day.type.name} has no primary slot',
          );
        }
      }
    });

    test('knows how much each day leans on the legs', () {
      DayTemplate dayOf(DayType type) => WeekTemplate.forDays(6)
          .days
          .followedBy(WeekTemplate.forDays(4).days)
          .firstWhere((d) => d.type == type);

      expect(dayOf(DayType.legs).legEmphasis, 1.0);
      expect(dayOf(DayType.lower).legEmphasis, 1.0);
      expect(dayOf(DayType.push).legEmphasis, 0.0);
      expect(dayOf(DayType.pull).legEmphasis, 0.0);
      expect(dayOf(DayType.upper).legEmphasis, 0.0);
    });
  });

  group('weekday assignment', () {
    test('spreads training days across the week', () {
      expect(weekdaysOf(scheduleFor(2)), [1, 4]);
      expect(weekdaysOf(scheduleFor(3)), [1, 3, 5]);
      expect(weekdaysOf(scheduleFor(4)), [1, 2, 4, 5]);
      expect(weekdaysOf(scheduleFor(5)), [1, 2, 3, 5, 6]);
      expect(weekdaysOf(scheduleFor(6)), [1, 2, 3, 4, 5, 6]);
    });

    test('always returns the requested number of days', () {
      for (var days = 2; days <= 6; days++) {
        expect(weekdaysOf(scheduleFor(days)).length, days);
      }
    });

    test('never schedules two sessions on the same weekday', () {
      for (var days = 2; days <= 6; days++) {
        for (final runs in [<int>{}, {1}, {3, 6}, {2, 4, 6}, {1, 2, 3}]) {
          final weekdays = weekdaysOf(scheduleFor(days, runWeekdays: runs));
          expect(
            weekdays.toSet().length,
            weekdays.length,
            reason: 'days=$days runs=$runs produced duplicates',
          );
        }
      }
    });

    test('returns days in ascending weekday order', () {
      for (var days = 2; days <= 6; days++) {
        final weekdays = weekdaysOf(scheduleFor(days, runWeekdays: {2, 5}));
        expect(weekdays, orderedEquals(List<int>.from(weekdays)..sort()));
      }
    });

    test('moves a session off a run day when a free day exists', () {
      final weekdays = weekdaysOf(scheduleFor(3, runWeekdays: {1}));
      expect(weekdays, isNot(contains(1)));
      expect(weekdays.length, 3);
    });

    test('shares a day with a run only when the week is genuinely full', () {
      // Six gym days and three run days cannot all be kept apart.
      final weekdays = weekdaysOf(scheduleFor(6, runWeekdays: {2, 4, 6}));
      expect(weekdays.length, 6);
      expect(weekdays.toSet().intersection({2, 4, 6}), isNotEmpty);
    });

    test('flags the days that come immediately before a run', () {
      final schedule = scheduleFor(3, runWeekdays: {4});
      final flagged = schedule.days
          .where((d) => d.precedesRunDay)
          .map((d) => d.weekday)
          .toList();
      expect(flagged, [3]);
    });

    test('treats Sunday as preceding a Monday run', () {
      final schedule = PlanScheduler.schedule(
        template: WeekTemplate.forDays(6),
        runWeekdays: const {1},
      );
      // Monday is a run day, so the displaced session rolls onto Sunday,
      // which must know that a Monday run follows it.
      for (final day in schedule.days) {
        expect(day.precedesRunDay, day.weekday == 7);
      }
    });

    test('flags nothing when the user does not run', () {
      expect(
        scheduleFor(4).days.every((d) => !d.precedesRunDay),
        isTrue,
      );
    });
  });

  group('leg day placement', () {
    test('rotates the template to keep leg work off pre-run days', () {
      // Monday/Tuesday/Thursday/Friday with a Wednesday run: Tuesday is the
      // pre-run slot, so the lower day must not land there.
      final schedule = scheduleFor(4, runWeekdays: {3});
      final tuesday = schedule.days.firstWhere((d) => d.weekday == 2);

      expect(tuesday.precedesRunDay, isTrue);
      expect(tuesday.type, DayType.upper);
      expect(typesOf(schedule), [
        DayType.lower,
        DayType.upper,
        DayType.lower,
        DayType.upper,
      ]);
    });

    test('keeps the template order when no rotation is needed', () {
      expect(typesOf(scheduleFor(4)), [
        DayType.upper,
        DayType.lower,
        DayType.upper,
        DayType.lower,
      ]);
    });

    test('preserves the alternation a rotation cannot break', () {
      // Rotation is used rather than free reordering precisely so that
      // upper/lower never collapses into two lower days back to back.
      for (final runs in [<int>{}, {3}, {6}, {3, 6}, {7}]) {
        final types = typesOf(scheduleFor(4, runWeekdays: runs));
        expect(
          types.where((t) => t == DayType.lower).length,
          2,
          reason: 'runs=$runs changed the upper/lower balance',
        );
        for (var i = 1; i < types.length; i++) {
          expect(
            types[i],
            isNot(types[i - 1]),
            reason: 'runs=$runs put two ${types[i]} days together',
          );
        }
      }
    });

    test('accepts an unavoidable conflict for a full-body week', () {
      // Every full-body day trains legs, so with runs on both sides there is
      // no placement that avoids it. The generator handles this by lightening
      // the day, not by refusing to schedule it.
      final schedule = scheduleFor(3, runWeekdays: {2, 4, 6});
      expect(schedule.days.length, 3);
      expect(schedule.days.any((d) => d.precedesRunDay), isTrue);
    });
  });
}
