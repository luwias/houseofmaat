# The House of Ma'at – A Ma'at Háza

Narratív nyomozós-rekonstrukciós játék az egyiptomi túlvilágon. A játékos a Ma'at Házának új
Őrzője: minden lélek életét bizonyítékokból, kihallgatásokból és emlékekből kell újraépítenie
egy papirusz-storyboardon, majd ítéletet mondania. A templom maga is reagál az ítéletekre.

**Jelenlegi állapot – 1. fázis:** teljes, végigjátszható **Kha-eset** (14 bizonyíték, 4 nyomozási
ág, kihallgatások kizáró döntésekkel, 5 jelenetes storyboard, 4 befejezés), mind a 7 terem,
templom-állapotrendszer, mentés. Nefru és Hori esete, valamint a végső rejtély a következő fázis.

## Futtatás

- **Godot 4.7** (standard, nem .NET). Nyisd meg a mappát a Godot projektkezelőjében, majd F5.
- Parancssorból:
  ```
  Godot_v4.7.2-stable_win64.exe --path .
  ```
- Logikai tesztek (fej nélkül):
  ```
  Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tests/test_runner.tscn
  ```
- Képernyőkép-forgatókönyvek (fejlesztéshez):
  ```
  Godot_v4.7.2-stable_win64.exe --path . -- --shot=<mappa> --scenario=tour|case|states
  ```

## A 3D templom újraépítése Blenderből

A teljes templom (7 terem) és a 3D-s bizonyítéktárgyak procedurálisan, Python-szkriptből készülnek:

```
blender --background --python tools/blender/build_temple.py -- assets/models
```

A szkript elnevezési konvenciói (`Interact_*`, `Cam_*`, `Crack_*`, `Plant_*`, anyagnevek…) a
`tools/blender/build_temple.py` fejlécében vannak leírva; a Godot ezekre építi a kattintható
tárgyakat, a kameranézeteket és az állapotfüggő látványt.

## Felépítés

```
data/hu/            minden szöveg és narratíva (nyelvenként egy mappa)
  cases/kha.json    egy lélek teljes esete: bizonyítékok, kártyák, párbeszédek, jelenetek,
                    értelmezések, befejezések, tippek
  souls.json        a lelkek listája
  temple.json       templom-értékek, ítélettípusok, kategóriák hatásai, paraméterek
  rooms.json        a 7 terem: cél, feloldás, bezárás, állapotleírások
  mystery.json      az átívelő rejtély nyomai
  ui.json           a felület szövegei
scripts/core/       Loc (nyelv), GameData (adatbetöltés), GameState (állapot + mentés)
scripts/systems/    conditions (feltételek/hatások), dialogue, story_validator, judgment
scripts/world/      temple_3d.gd – 3D templom, állapotfüggő látvány, interakció
scripts/ui/         HUD, képernyők, widgetek (storyboard, kártyák, illusztrációk, 3D-nézegető)
shaders/            papirusz, hieroglifafal, láng, szellem, árnyék, kiemelés
tools/blender/      a templom procedurális felépítése
tests/              logikai tesztek (befejezések, zsákutca-ellenőrzés, mentés)
```

### Rendszerek

| Rendszer | Hol | Mit csinál |
|---|---|---|
| Esetkezelés | `GameData`, `GameState.start_case` | esetek betöltése, állapot |
| Bizonyítékok | `GameState.unlock_evidence/reveal/compare_evidence` | feloldás, rejtett részletek, összevetés, megbízhatóság, Duat-romlás |
| Párbeszéd | `systems/dialogue.gd` | csomópontok, előfeltételek, hatások, kizáró csoportok |
| Rekonstrukció | `widgets/storyboard.gd` | drag & drop jelenetek |
| Jelenet-validáció | `systems/story_validator.gd` | Megerősített / Alátámasztott / Bizonytalan / Ellentmondásos / Kitalált |
| Ítélet | `systems/judgment.gd` | hat paraméter, befejezés feltételekből, magyarázat |
| Templom | `GameState.apply_outcome`, `world/temple_3d.gd` | Ma'at / Ankh / Duat, látható változások |
| Feloldás | `systems/conditions.gd` | adatvezérelt feltételek mindenhez |
| Mentés | `GameState.save_game/load_game` | `user://houseofmaat_save.json`, automatikus |

### Új eset hozzáadása

1. Írd meg a `data/hu/cases/<id>.json`-t a `kha.json` mintájára.
2. A `souls.json`-ban állítsd a lelket `"playable": true`-ra.
3. Futtasd a teszteket – az adatintegritás-ellenőrzés jelzi a hiányzó hivatkozásokat.

### Új nyelv

Másold le a `data/hu` mappát (pl. `data/en`), fordítsd le a JSON-okat, és hívd meg a
`Loc.load_locale("en")`-t, majd a `GameData.reload()`-ot.

## Mobil (Android)

Telefonon a játék automatikusan kompakt módban fut: nagyobb skála (olvasható szöveg),
ikonos HUD, koppintásos kártyalerakás, ✕ gomb a lehelyezett kártyákon, az Android vissza
gombja ablakot zár. A grafika a mobil renderelőt használja SSAO és térfogati köd nélkül.
Asztali gépen kipróbálható: `-- --mobile` (pl. `--resolution 1800x810`).

APK export (Android Studio SDK-val és JBR-rel):

```
ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD = a kiadási kulcstár adatai
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-release "Android" export/android/HouseOfMaat.apk
```

A kiadási kulcstár nincs a repóban – őrizd meg, nélküle nem adható ki frissítés.
