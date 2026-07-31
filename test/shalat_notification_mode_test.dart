import 'package:dilalquran/modules/shalat/controller/shalat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shalat notification modes', () {
    late ShalatController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = ShalatController();
    });

    test('default prayer modes are adzan and enabled', () {
      expect(controller.enabledPrayerCount, ShalatController.prayerNames.length);
      expect(controller.allPrayersEnabled, isTrue);

      for (final prayer in ShalatController.prayerNames) {
        expect(
          controller.prayerNotificationModes[prayer],
          ShalatController.notificationModeAdzan,
        );
        expect(controller.prayerModeLabel(prayer), 'Suara adzan');
        expect(controller.isPrayerEnabled(prayer), isTrue);
      }
    });

    test('custom mode label follows selected custom sound title', () {
      controller.prayerNotificationModes['Subuh'] =
          ShalatController.notificationModeCustom;

      expect(controller.prayerModeLabel('Subuh'), 'Pilih suara dari HP');

      controller.customSoundTitle.value = 'Adzan Merdu';

      expect(controller.prayerModeLabel('Subuh'), 'Adzan Merdu');
    });

    test('disabled prayer reduces enabled summary and marks mode as off', () {
      controller.prayerNotificationModes['Subuh'] =
          ShalatController.notificationModeOff;
      controller.prayerNotificationModes['Isya'] =
          ShalatController.notificationModeSilent;

      expect(controller.isPrayerEnabled('Subuh'), isFalse);
      expect(controller.prayerModeLabel('Subuh'), 'Nonaktif');
      expect(controller.isPrayerEnabled('Isya'), isTrue);
      expect(controller.prayerModeLabel('Isya'), 'Tanpa suara (notif saja)');
      expect(
        controller.enabledPrayerCount,
        ShalatController.prayerNames.length - 1,
      );
      expect(controller.allPrayersEnabled, isFalse);
    });

    test('sound label mirrors current top-level notification sound choice', () {
      controller.notificationSound.value = ShalatController.notificationModeDevice;
      expect(controller.soundLabel, 'Suara ringtone sistem');

      controller.notificationSound.value = ShalatController.notificationModeCustom;
      expect(controller.soundLabel, 'Suara HP');

      controller.customSoundTitle.value = 'Nada Subuh';
      expect(controller.soundLabel, 'Nada Subuh');
    });
  });
}
