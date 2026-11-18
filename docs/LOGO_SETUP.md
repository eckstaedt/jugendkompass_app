# Logo Setup Anleitung

## ✅ Was wurde bereits eingerichtet:

1. **flutter_launcher_icons Package** wurde zu [pubspec.yaml](pubspec.yaml) hinzugefügt
2. **Konfigurationsdatei** [flutter_launcher_icons.yaml](flutter_launcher_icons.yaml) wurde erstellt
3. **Web Manifest** [web/manifest.json](web/manifest.json) wurde mit "Jugendkompass" aktualisiert
4. **Web Index** [web/index.html](web/index.html) wurde mit korrektem Titel und Meta-Tags aktualisiert
5. **Assets Ordner** wurde in [pubspec.yaml](pubspec.yaml) registriert

## 📋 Nächste Schritte (Manuell erforderlich):

### 1. Logo-Datei platzieren
Speichere das Logo als `assets/images/logo.png` in deinem Projekt:
- Erstelle den Ordner `assets/images/` (falls noch nicht vorhanden)
- Speichere das Logo als `logo.png` in diesem Ordner
- Empfohlene Mindestgröße: 1024x1024 Pixel für beste Qualität

### 2. Dependencies installieren
```bash
flutter pub get
```

### 3. Icons generieren
```bash
flutter pub run flutter_launcher_icons
```

Dieser Befehl generiert automatisch:
- ✅ Android App Icons (alle Größen)
- ✅ iOS App Icons (alle Größen)
- ✅ Web Icons (favicon.png, Icon-192.png, Icon-512.png, maskable variants)
- ✅ Windows Icon
- ✅ macOS Icon

### 4. Überprüfung
Nach dem Generieren sollten folgende Dateien aktualisiert sein:
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`
- Android Icons in `android/app/src/main/res/`
- iOS Icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## 🎨 Verwendete Farbschema:
- **Theme Color**: `#E53935` (Rot aus dem Logo)
- **Background Color**: `#ffffff` (Weiß)

## 💡 Hinweise:
- Das Logo sollte ein PNG mit transparentem Hintergrund sein
- Für beste Ergebnisse sollte das Logo quadratisch sein (1:1 Aspect Ratio)
- Mindestgröße: 512x512px, empfohlen: 1024x1024px oder höher
- Das Flutter Launcher Icons Package generiert automatisch alle benötigten Größen

## 🔄 Icons neu generieren (bei Logo-Änderung):
Wenn du das Logo später ändern möchtest:
1. Ersetze `assets/images/logo.png` mit dem neuen Logo
2. Führe erneut aus: `flutter pub run flutter_launcher_icons`

---

**Status**: Bereit zur Logo-Platzierung und Icon-Generierung! 🚀
