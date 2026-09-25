# App Exposé Restore

Eine kleine macOS-App, die minimierte Fenster der aktiven App wieder in App Exposé zeigt. Sie ergänzt die native Übersicht bei ⌃↓ oder der Drei-Finger-Geste um anklickbare Fensterkarten mit Inhaltsvorschau. Auch minimierte Finder-Fenster werden berücksichtigt.

Dieses Projekt ist ein Workaround für das unter macOS 27 beobachtete Fehlen minimierter Fenster in App Exposé. Die automatische Erkennung beruht auf nicht dokumentierten Fenster-Layern von Dock und WindowManager und kann nach macOS-Updates Anpassungen brauchen.

## Aus dem Quellcode bauen

Benötigt: macOS mit Xcode 27 oder neuer. Es gibt keine externen Pakete oder Build-Dienste.

```sh
./test.sh
./build.sh
mkdir -p "$HOME/Applications"
ditto -x -k ../AppExposeRestore.zip "$HOME/Applications"
open "$HOME/Applications/AppExposeRestore.app"
```

`build.sh` erzeugt eine lokal **ad hoc signierte** App und legt die ZIP eine Ebene über dem Repository ab. Dafür sind weder ein Apple-Developer-Konto noch ein Zertifikat nötig. Für wiederholte Builds auf demselben Mac empfiehlt sich eine eigene stabile Code-Signing-Identität, damit macOS die Berechtigungen nicht wegen einer geänderten Signatur erneut verlangt:

```sh
APP_EXPOSE_SIGNING_IDENTITY="Name deiner lokalen Code-Signing-Identität" ./build.sh
```

Der private Schlüssel bleibt im eigenen Schlüsselbund und gehört **nicht** ins Repository. Dieses Repository veröffentlicht nur Quellcode. Ein fertig herunterladbarer Build wäre ein anderer Distributionsweg: Dafür sind Developer-ID-Signierung und Notarisierung bei Apple der übliche Weg.

## Berechtigungen und Bedienung

- **Bedienungshilfen/Accessibility:** nötig, um minimierte Fenster zu finden und per Klick wiederherzustellen. Die App zeigt einen Menüpunkt zur passenden Systemeinstellung. Unter macOS 27.0 liegt der Schalter unter *Datenschutz & Sicherheit → Gerätesteuerung und Datenzugriff*.
- **Bildschirmaufnahme:** nötig für Inhaltsbilder der Karten. Ohne Freigabe bleiben die Fensterkarten nutzbar und zeigen stattdessen das App-Symbol.

Im Menü und im Einstellungsfenster lassen sich die automatische Anzeige, das Menüleistensymbol und die Inhaltsvorschau schalten. Ohne Menüleistensymbol erscheint die App im Dock. Die Fensterkarten verwenden fest den klaren Liquid-Glass-Stil. Der Glasstil verändert weder die Leiste noch das Einstellungsfenster.

## Datenschutz

Fenstertitel und Vorschaubilder werden nur im Arbeitsspeicher verarbeitet und nicht als Dateien gespeichert oder ins Netz gesendet. Das lokale macOS-Protokoll enthält Ablauf- und Zeitmarken sowie Trefferzahlen, aber keine Fenstertitel oder Bildinhalte. Bildschirmbilder werden nur für sichtbare minimierte Fenster angefordert und bei erneutem Öffnen aktualisiert.

## Grenzen

- Getestet unter macOS 27. Andere Versionen können sich bei App Exposé anders verhalten.
- Die Karten zeigen einzelne Standbilder, keinen laufenden Stream. Falls macOS kein Bild liefert oder ein Fenster nicht eindeutig zuordenbar ist, bleibt das App-Symbol sichtbar.
- Manche Apps liefern minimierte Fenster nur über `AXChildren` statt `AXWindows`. Die App prüft beide Listen. Fenster, die eine App über keine davon zugänglich macht, können fehlen.
- Nach einem Neubau mit anderer Signatur kann macOS die Accessibility- oder Bildschirmaufnahmefreigabe erneut verlangen.

Die Tests in `./test.sh` prüfen Erkennung, Fensterzuordnung, Einstellungen und Darstellung. Sie benötigen keine echten Fensterinhalte. Für einen Praxistest zwei Fenster einer App öffnen, eines minimieren, App Exposé öffnen und die Karte anklicken. In Mission Control darf die Zusatzleiste nicht erscheinen.

## Lizenz

MIT – siehe [LICENSE](LICENSE).
