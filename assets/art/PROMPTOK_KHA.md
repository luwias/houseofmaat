# Kha esetének illusztrációi – promptok

## Hol készítsd el?

| Eszköz | Ár | Mire jó |
|---|---|---|
| **ChatGPT (képgenerálás)** – chatgpt.com | ingyenes keret / Plus előfizetés | **Ezt ajánlom.** Magyarul is beszélhetsz vele, és ha feltöltöd az első Kha-portrét, a többi képen is ugyanúgy rajzolja meg Khát. |
| **Midjourney** – midjourney.com | előfizetés | A legszebb festett hatás. A szereplők egységességéhez: `--cref <a Kha-portré linkje>`. |
| **Leonardo.ai** | ingyenes napi keret | Jó ingyenes alternatíva, van „Character Reference” funkciója. |
| **Microsoft Designer / Bing Image Creator** | ingyenes | Gyors, de kevésbé egységes. |

**Licenc:** ha a játékot pénzért árulod itch.io-n, nézd meg az eszköz feltételeit. A ChatGPT és a fizetős Midjourney engedi a kereskedelmi felhasználást, az ingyenes eszközöknél ezt külön ellenőrizd.

## Így dolgozz

1. **Először a Kha-portrét** (1. kép) készítsd el. Ha tetszik, minden további képnél töltsd fel referenciaként, és írd mellé: *„Keep the same character as in the reference image.”*
2. Merit első képe után ugyanígy használd azt is referenciaként.
3. Minden prompt végére másold oda a **közös stílusblokkot** (lent), és állítsd be a megadott **méretarányt**.
   ChatGPT-ben ezt írd a prompt végére: *„Aspect ratio 16:9.”*; Midjourney-ben pedig: `--ar 16:9`.
4. **PNG-ként** mentsd, **pontosan a megadott néven** (kisbetű, ékezet nélkül), a megadott mappába.
5. Ha végeztél (vagy akár csak néhány képpel), szólj, és beépítem, illetve újraexportálom a játékot.

A mappák helye: `C:\Users\nitta\Desktop\houseofmaat\assets\art\` → `souls`, `scenes`, `portraits`, `cards`.

### Közös stílusblokk – minden prompt végére

```
Painterly digital illustration, ancient Egypt, New Kingdom Thebes, warm golden-hour light, rich ochre, lapis blue and turquoise accents, cinematic composition, soft volumetric light, highly detailed, no text, no letters, no watermark, no modern objects.
```

### A szereplők állandó leírása (már benne van a promptokban)

- **Kha:** 40-year-old Egyptian merchant, warm brown skin, short dark beard, white linen headcloth, broad gold-and-lapis collar, simple linen tunic, thoughtful eyes
- **Merit:** 35-year-old Egyptian woman, black braided wig with a thin gold headband, kohl-lined eyes, white linen dress, turquoise bead collar
- **Djehuty:** heavy-set treasury overseer in his fifties, shaved head, fine pleated linen, many gold rings, one signet ring shaped like an outstretched golden hand, arrogant expression
- **Hapu:** weathered Nile ship captain, sun-darkened skin, rope-scarred hands, simple kilt and headband
- **Ipy:** middle-aged embalmer, shaved head, linen apron, resin-stained hands

---

## 1. A lélek – fejlécsáv és a Lelkek Táblája (1 kép)

| # | Fájlnév → mappa | Arány |
|---|---|---|
| 1 | `kha.png` → `souls\` | 16:9 |

```
Portrait of Kha, a 40-year-old Egyptian merchant, warm brown skin, short dark beard, white linen headcloth, broad gold-and-lapis collar, simple linen tunic, thoughtful eyes looking into the distance. He stands on the right third of the image; the left side is open sky and the harbor of Thebes with sailing boats, palm trees and temple pylons, leaving empty space on the left for a title.
```

## 2. Jelenetek – a Papirusz öt jelenete (5 kép)

Álló képek; a felső harmadban maradjon nyugodtabb rész (ég, fal), mert oda kerül a jelenet címe.

| # | Fájlnév → mappa | Arány |
|---|---|---|
| 2 | `kha_childhood.png` → `scenes\` | 3:4 |
| 3 | `kha_wealth.png` → `scenes\` | 3:4 |
| 4 | `kha_marriage.png` → `scenes\` | 3:4 |
| 5 | `kha_betrayal.png` → `scenes\` | 3:4 |
| 6 | `kha_death.png` → `scenes\` | 3:4 |

**2 – Gyermekkor**
```
A poor Egyptian boy of about eight sits on a muddy Nile riverbank in front of reed huts, holding a small carved wooden boat, watching a distant sail disappear at sunset. Calm sky in the upper third.
```

**3 – Gazdagság**
```
Interior of a rich Egyptian merchant's storehouse: Kha (40-year-old merchant, short dark beard, white linen headcloth, gold-and-lapis collar) stands among stacked goods, chests of gold rings, amphorae and papyrus scrolls, with a heavy-set treasury overseer in the shadows behind him. Warm lamplight, hanging red cloth, calm upper third.
```

**4 – Házasság**
```
Merit, a 35-year-old Egyptian woman with a black braided wig, thin gold headband, kohl-lined eyes, white linen dress and turquoise bead collar, seen from behind and in profile, standing in a lamp-lit house at night, holding a folded secret letter, looking toward a window. Warm candlelight, soft shadows, calm upper third.
```

**5 – Árulás**
```
Night at the Theban harbor under a purple starry sky: a heavy-set Egyptian official in fine linen hands a small bag of gold to a weathered ship captain beside a moored sailing ship; a hooded guard with a spear watches in the shadows. Moody blue and violet tones with warm torchlight accents, calm upper third.
```

**6 – Halál**
```
A solemn Egyptian embalming chamber: a linen-wrapped body lies on a stone table, flanked by two black Anubis statues and burning braziers, river mud on the floor hinting the body came from the water. Dark gold and amber light, quiet and respectful, not gory, calm upper third.
```

## 3. Párbeszéd-portrék – a megidézett ka-k (6 kép)

Mellképek, sötét háttér előtt; az alakot halvány arany derengés veszi körül (megidézett szellem).
Mindegyik prompt végére írd hozzá még ezt is: `faint ethereal golden glow around the figure, like a summoned spirit, dark background`.

| # | Fájlnév → mappa | Arány | Ki |
|---|---|---|---|
| 7 | `kha_ipy.png` → `portraits\` | 5:6 | Ipy, a balzsamozó |
| 8 | `kha_harbor.png` → `portraits\` | 5:6 | a kikötőmester |
| 9 | `kha_treasury.png` → `portraits\` | 5:6 | Szenedzsem, kincstári írnok |
| 10 | `kha_merit.png` → `portraits\` | 5:6 | Merit |
| 11 | `kha_hapu.png` → `portraits\` | 5:6 | Hapu kapitány |
| 12 | `kha_djehuty.png` → `portraits\` | 5:6 | Djehuty |

**7 – Ipy**
```
Bust portrait of Ipy, a middle-aged Egyptian embalmer, shaved head, linen apron, resin-stained hands, holding a small oil lamp, inside a dim workshop with linen bandages and jars.
```
**8 – Kikötőmester**
```
Bust portrait of an old Egyptian harbor master with a grey stubble and a simple headcloth, holding a papyrus ledger and a reed pen, ropes and masts blurred behind him.
```
**9 – Szenedzsem**
```
Bust portrait of Senedjem, a young nervous Egyptian treasury scribe, shaved head, white linen, holding a scribe palette, dusty shelves of scrolls behind him.
```
**10 – Merit**
```
Bust portrait of Merit, a 35-year-old Egyptian woman, black braided wig with a thin gold headband, kohl-lined eyes, wearing a white mourning linen veil over her dress and a turquoise bead collar, sad but determined expression.
```
**11 – Hapu**
```
Bust portrait of Hapu, a weathered Nile ship captain, sun-darkened skin, rope-scarred hands, simple headband, guilty eyes looking down, the deck of a ship at night behind him.
```
**12 – Djehuty**
```
Bust portrait of Djehuty, a heavy-set Egyptian treasury overseer in his fifties, shaved head, fine pleated linen, heavy gold collar, many gold rings with one signet ring shaped like an outstretched golden hand clearly visible, arrogant cold expression.
```

## 4. Kártyák – a Papirusz kártyatálcája (28 kép + 14 nem kötelező)

Négyzetes képek; egyetlen alak vagy tárgy középen, **egyszerű, meleg pergamen háttér előtt**.
Mindegyik prompt végére írd hozzá: `single subject centered, plain warm parchment background, soft vignette, icon-like card illustration`.

### Szereplők (6) → `cards\`, 1:1
| # | Fájlnév | Prompt |
|---|---|---|
| 13 | `c_kha.png` | `Bust of Kha, 40-year-old Egyptian merchant, short dark beard, white linen headcloth, gold-and-lapis collar` |
| 14 | `c_merit.png` | `Bust of Merit, Egyptian woman, black braided wig, thin gold headband, kohl eyes, turquoise bead collar` |
| 15 | `c_djehuty.png` | `Bust of Djehuty, heavy-set Egyptian treasury overseer, shaved head, gold rings, arrogant expression` |
| 16 | `c_hapu.png` | `Bust of Hapu, weathered Egyptian ship captain, sun-darkened skin, simple headband` |
| 17 | `c_ipy.png` | `Bust of Ipy, Egyptian embalmer, shaved head, linen apron, resin-stained hands` |
| 18 | `c_nebi.png` | `Bust of Nebi, a poor old Egyptian boatman with a reed hat and a fishing net over his shoulder` |

### Események (12) → `cards\`, 1:1
| # | Fájlnév | Prompt |
|---|---|---|
| 19 | `e_poverty.png` | `A humble reed hut with empty clay jars on a muddy Nile bank` |
| 20 | `e_first_trade.png` | `A young man trading a basket of fish for copper rings at a small market stall` |
| 21 | `e_wedding.png` | `Two joined hands with gold bracelets above a blooming lotus flower` |
| 22 | `e_treasury_deal.png` | `A papyrus contract with a red clay seal and a reed pen` |
| 23 | `e_embezzlement.png` | `Gold ingots slipping from an open wooden chest into deep shadow` |
| 24 | `e_natural_death.png` | `An oil lamp burning low beside a linen-draped bed in a dark room` |
| 25 | `e_secret_agreement.png` | `Two hands secretly exchanging a folded papyrus in lamplight` |
| 26 | `e_exposure.png` | `Copied clay seal impressions laid out on a wooden table under a lamp` |
| 27 | `e_staged_death.png` | `An empty sealed wooden coffin in an embalming workshop` |
| 28 | `e_escape.png` | `A hooded figure boarding a small sailing ship at night` |
| 29 | `e_murder.png` | `A dark river at night with the shadow of a raised club on a ship deck, ominous, not gory` |
| 30 | `e_false_accusation.png` | `A papyrus scroll with two overlapping clay seals, one forged, under an ominous shadow` |

### Tárgyak (3) → `cards\`, 1:1
| # | Fájlnév | Prompt |
|---|---|---|
| 31 | `o_gold.png` | `A stack of ancient Egyptian gold ingots and gold rings` |
| 32 | `o_royal_seal.png` | `An ancient Egyptian cylinder seal of dark stone beside its clay impression with carved symbols` |
| 33 | `o_ring.png` | `A gold signet ring with an outstretched golden hand emblem` |

### Helyszínek (5) → `cards\`, 1:1
| # | Fájlnév | Prompt |
|---|---|---|
| 34 | `l_harbor.png` | `The harbor of Thebes with sailing boats and palm trees` |
| 35 | `l_treasury.png` | `The royal treasury of Thebes, a stone building with guarded doors and stacked chests` |
| 36 | `l_merit_house.png` | `A modest whitewashed Egyptian house with a palm tree and a lamp in the window` |
| 37 | `l_embalming.png` | `An Egyptian embalming workshop on the west bank with linen and jars` |
| 38 | `l_ship.png` | `The deck of the Egyptian sailing ship "Eye of Horus" at night, an Eye of Horus painted on the bow` |

### Emlékek (3) → `cards\`, 1:1
| # | Fájlnév | Prompt |
|---|---|---|
| 39 | `m_father_ship.png` | `A boy on a riverbank watching a distant sail at sunset, dreamlike and faded like a memory` |
| 40 | `m_merit_promise.png` | `Two hands holding each other in warm lamplight, dreamlike and faded like a memory` |
| 41 | `m_last_night.png` | `The bow of a ship cutting through black water under stars, dreamlike and faded like a memory` |

### Bizonyítékok – nem kötelező (14) → `cards\`, 1:1
Ha nem készíted el, a bizonyítékkártyákon az arany jel marad, ami szintén jól mutat.

| # | Fájlnév | Prompt |
|---|---|---|
| 42 | `K01.png` | `A cracked painted wooden panel showing a boatman, a woman and a boy with a toy boat` |
| 43 | `K02.png` | `An official papyrus trade ledger with columns of hieroglyphs and a red seal` |
| 44 | `K03.png` | `A folded secret letter covered in a few large hieroglyphs` |
| 45 | `K04.png` | `An official papyrus death report with a blue seal` |
| 46 | `K05.png` | `A storehouse record papyrus with a scraped-out name` |
| 47 | `K06.png` | `An embalmer's work ledger beside linen bandages` |
| 48 | `K07.png` | `A small payment papyrus beside thirty gold rings` |
| 49 | `K08.png` | `A clay tablet with two overlapping seal impressions` |
| 50 | `K09.png` | `A secret contract papyrus with two seals, glowing hidden ink in lamplight` |
| 51 | `K10.png` | `A grieving Egyptian woman speaking, her words drifting as golden light` |
| 52 | `K11.png` | `A papyrus with a bold official countersignature cartouche` |
| 53 | `K12.png` | `A ship passenger manifest papyrus with a small painted boat` |
| 54 | `K13.png` | `A weathered sailor confessing in the dark, golden light around his words` |
| 55 | `K14.png` | `A harbor guard's report papyrus beside a merchant's signet ring` |
