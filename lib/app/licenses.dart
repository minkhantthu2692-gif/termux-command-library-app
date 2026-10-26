import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled font families are shipped with the application, so their licences
/// must appear in the in-app licence page alongside Flutter's package notices.
/// The files are registered lazily; nothing is read until the user opens it.
void registerBundledLicenses() {
  for (final entry in _licenses) {
    LicenseRegistry.addLicense(() async* {
      final text = await rootBundle.loadString(entry.path);
      yield LicenseEntryWithLineBreaks([entry.label], text);
    });
  }
}

class _BundledLicense {
  const _BundledLicense(this.label, this.path);

  final String label;
  final String path;
}

const _licenses = <_BundledLicense>[
  _BundledLicense(
    'Inter — SIL Open Font License 1.1',
    'assets/fonts/licenses/Inter-OFL.txt',
  ),
  _BundledLicense(
    'Open Sans — SIL Open Font License 1.1',
    'assets/fonts/licenses/OpenSans-OFL.txt',
  ),
  _BundledLicense(
    'Lato — SIL Open Font License 1.1',
    'assets/fonts/licenses/Lato-OFL.txt',
  ),
  _BundledLicense(
    'Montserrat — SIL Open Font License 1.1',
    'assets/fonts/licenses/Montserrat-OFL.txt',
  ),
  _BundledLicense(
    'Nunito Sans — SIL Open Font License 1.1',
    'assets/fonts/licenses/NunitoSans-OFL.txt',
  ),
  _BundledLicense(
    'Source Sans 3 — SIL Open Font License 1.1',
    'assets/fonts/licenses/SourceSans3-OFL.txt',
  ),
  _BundledLicense(
    'Lora — SIL Open Font License 1.1',
    'assets/fonts/licenses/Lora-OFL.txt',
  ),
  _BundledLicense(
    'Roboto Slab — Apache License 2.0',
    'assets/fonts/licenses/RobotoSlab-LICENSE.txt',
  ),
  _BundledLicense(
    'JetBrains Mono — SIL Open Font License 1.1',
    'assets/fonts/licenses/JetBrainsMono-OFL.txt',
  ),
  _BundledLicense(
    'Noto Sans Myanmar — SIL Open Font License 1.1',
    'assets/fonts/licenses/NotoSansMyanmar-OFL.txt',
  ),
];
