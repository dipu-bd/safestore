import 'package:safestore/src/app.dart';
import 'package:catcher/catcher_plugin.dart';

void main() {
  CatcherOptions debugOptions = CatcherOptions(
    DialogReportMode(),
    [
      ConsoleHandler(),
    ],
  );
  CatcherOptions releaseOptions = CatcherOptions(
    DialogReportMode(),
    [
      // EmailManualHandler(["dipu.sudipta@gmail.com"]),
    ],
  );

  Catcher(
    App(),
    debugConfig: debugOptions,
    releaseConfig: releaseOptions,
  );
}
