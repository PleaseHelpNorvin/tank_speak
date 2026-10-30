# TankSpeak mobile app

Flutter client for the TankSpeak FastAPI backend (`tankspeak-backend_claude`).
All data comes from the backend API; the app has no database or business
logic of its own. Mobile roles are **owner**, **manager** and **member**.
Administrator accounts belong to the web administration portal.

## Configure the API URL

By default the app talks to the live TankSpeak server
(`https://129.121.115.28/api`), so a plain build works on a phone:

```powershell
flutter build apk --release        # or: flutter build apk --debug / flutter run
```

To use another server, pass its origin (with or without `/api`):

```powershell
flutter run --dart-define=API_BASE_URL=https://other-server
```

For a backend running on your PC, use `API_BASE_URL=local`:

| Target | URL used |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (the emulator's alias for your PC) |
| Web, Windows, macOS, Linux, iOS simulator | `http://127.0.0.1:8000/api` |
| Physical phone | `local` does not work; use `API_BASE_URL=http://<your PC's LAN IP>:8000` and start uvicorn with `--host 0.0.0.0` |

The address in use is shown at the bottom of the Profile screen, and on the
sign-in screen when the server cannot be reached.

Optional settings (must match the backend's environment if you change them
there):

| Define | Default | Meaning |
|---|---|---|
| `DEVICE_ONLINE_MINUTES` | 15 | device counts as online if it reported within this time |
| `DEVICE_STALE_MINUTES` | 60 | after this, the device is offline and readings are outdated |
| `TELEMETRY_REFRESH_SECONDS` | 30 | auto-refresh interval of station and tank screens |

## Run locally against the backend

```powershell
# terminal 1 – backend
cd C:\Users\Admin\Desktop\tankspeak-backend_claude
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# terminal 2 – app
cd C:\Users\Admin\Desktop\tank_speak
flutter pub get
flutter run --dart-define=API_BASE_URL=local   # emulator / desktop / web
```

## Checks

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

`test/fixtures/*.json` are real responses captured from the backend (password
hashes redacted) and are used by the model and service tests.

## Structure

```
lib/config/app_config.dart     build-time settings (API_BASE_URL, thresholds)
lib/core/                      errors, JSON helpers, secure token storage, formatting
lib/services/api_service.dart  the only HTTP client (auth header, timeouts, errors, 401 handling)
lib/services/*_service.dart    one service per backend area (auth, company, station, invitation, device, calibration)
lib/models/                    typed models parsed from backend JSON
lib/screens/                   UI
lib/widgets/                   shared UI (theme, loading/empty/error views, auto refresh)
```

BLE provisioning (`ble_provision_service.dart`, `web_bluetooth_service*.dart`,
`web/bluetooth.js`) is unchanged apart from the final "Register" call, which now
goes through `DeviceService`.
