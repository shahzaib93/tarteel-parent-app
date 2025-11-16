# If Flutter still tries VS 2019 on Windows desktop

Flutter 3.38 removed `--cmake-generator`. To get it to pick up your current VS install:

1) Clear the Flutter/CMake cache for Windows:
```bash
flutter clean
rd /s /q .dart_tool  # on Windows PowerShell/cmd
rd /s /q build
rd /s /q windows  # remove stale runner if you want to regenerate
```

2) Regenerate the Windows platform files with your current toolchain:
```bash
flutter create . --platforms=windows
```
This uses the default generator for the detected VS (per `flutter doctor`). If it still insists on 2019, add a `CMakeUserPresets.json` to force VS 2022/2026 below.

3) Optional: Force the generator via CMake preset (if Flutter picks the wrong one)
Create `windows/CMakeUserPresets.json` with:
```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "vs2022",
      "displayName": "VS 2022 x64",
      "generator": "Visual Studio 17 2022",
      "binaryDir": "${sourceDir}/out\/${presetName}",
      "toolchainFile": null,
      "cacheVariables": {
        "CMAKE_SYSTEM_VERSION": "10.0",
        "CMAKE_GENERATOR_PLATFORM": "x64"
      }
    }
  ]
}
```
Then build with:
```bash
cmake --preset vs2022 -S windows -B windows/out/vs2022
cmake --build windows/out/vs2022 --config Release
```
Or let Flutter use it by deleting old `windows/CMakeCache.txt` and rerunning `flutter run -d windows`; CMake will pick the preset.

4) Verify toolchain detection
```bash
cmake --help | findstr "Visual Studio"
```
Ensure your installed VS shows up (e.g., "Visual Studio 17 2022"). If CMake doesn’t list it, ensure Desktop C++ workload and the VS CMake tools are installed, then reopen your shell.

5) Final build
```bash
flutter pub get
flutter run -d windows   # or flutter build windows
```

If you still see the 2019 generator error, nuke `windows/CMakeCache.txt` and `windows/**/CMakeFiles`, regenerate with the preset, or run CMake manually with `-G "Visual Studio 17 2022" -A x64` and then `cmake --build`.
