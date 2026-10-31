# Illusztrációk

Tedd ide a képeket (png, jpg vagy webp) a lent megadott fájlnévvel – a játék automatikusan
megjeleníti őket. Ha egy kép hiányzik, a játék hangulatos tartalékképet rajzol a helyére.
Új kép hozzáadása után nyisd meg egyszer a projektet a Godotban (importálás), majd exportálj.

**Közös stílus minden képhez (ezt tedd minden angol prompt elejére):**

> Painterly digital illustration, ancient Egypt, New Kingdom Thebes, warm golden-hour light, rich ochre, lapis blue and turquoise accents, cinematic composition, soft volumetric light, highly detailed, no text, no letters, no watermark, no modern objects.

Ajánlott méretek: lelkek 1600×900 (fejlécsáv és tábla, a játék vágja), jelenetek 600×800 (álló), párbeszéd-portrék 600×720 (álló), kártyák 400×400 (négyzet, egyszerű háttér előtt egyetlen tárgy vagy alak).

## Lelkek – `souls/`

- `souls/kha.png` – Portrait of Kha, a 40-year-old Egyptian merchant, white linen headcloth, short beard, gold collar, harbor of Thebes with sailing boats and palm trees in the background
- `souls/nefru.png` – Portrait of Nefru, an elderly Egyptian village midwife and healer, kind tired eyes, herb pouch, reed huts on the Nile bank in the background
- `souls/hori.png` – Portrait of Hori, a thin royal Egyptian scribe, shaved head, scribe palette and reed pen, royal granary silos in a drought-stricken landscape in the background

## Jelenetek – `scenes/<lélek>_<jelenet>.png`

A leírás magyarul van – fordítsd le a prompthoz, vagy írd le a jelenetet saját szavaiddal.

- `scenes/kha_childhood.png` – **Gyermekkor**: Kha a kikötő nádkunyhói között nőtt fel. Az apja hajója sosem tért vissza; a fiú megfogadta, hogy ő vissza fog.
- `scenes/kha_wealth.png` – **Gazdagság**: Kha a kincstári megbízásokkal gazdagodott meg, és eleinte maga is aláírta Djehuty hamis tételeit, elfogadva a részét.
- `scenes/kha_marriage.png` – **Házasság**: Merit nemcsak a felesége volt, hanem a szövetségese: együtt tervelték ki Kha halálának megrendezését.
- `scenes/kha_betrayal.png` – **Árulás**: Djehuty megvesztegette Hapu kapitányt, hogy Kha szökése csapdává váljon – a kincstár aranyából.
- `scenes/kha_death.png` – **Halál**: Kha a Hórusz Szeme fedélzetén halt meg, a szökés első éjjelén: Djehuty emberei megölték, a testét visszavitték a kikötőbe.

- `scenes/nefru_childhood.png` – **Gyermekkor**: Nefru a nagyanyjától, Tia gyógyítótól tanulta meg a gyógyfüvek ismeretét Per-Hapi faluban.
- `scenes/nefru_calling.png` – **Hivatás**: Nefru a falu bábája és gyógyítója lett; a járvány évében is ő segítette világra a gyermekeket.
- `scenes/nefru_births.png` – **A két születés**: Ugyanazon a lázas éjszakán két fiú született: Nebetta úrnő beteg örököse és Szatré özvegy egészséges fia.
- `scenes/nefru_secret.png` – **A titok**: A nemesek követelésére Nefru kicserélte a gyermekeket – de úgy, hogy a beteg örökös egy szerető anyához kerüljön, és ő maga gyógyíthassa. Aranyat nem fogadott el. Két anyától vette el a választás jogát.
- `scenes/nefru_death.png` – **Halál**: A csere kiderült, egy gyermek meghalt a járványban. Nefru halála előtt bevallotta a cserét, de sosem árulta el, melyik gyermek kié.

- `scenes/hori_childhood.png` – **Gyermekkor**: Hori az írnokiskolában tanult, és a tanítója arra intette, hogy a szíve a népé legyen.
- `scenes/hori_ambition.png` – **Ambíció**: Hori királyi írnok lett, a magtár gabonakönyveinek vezetője.
- `scenes/hori_corruption.png` – **Korrupció**: Az aszály idején Panehsy hatszáz zsák gabonát zárt a déli raktárba, hogy a drágulás idején eladja.
- `scenes/hori_rebellion.png` – **Lázadás**: Hori meghamisította a könyveket, és négyszáz zsák gabonát osztott ki az éhező falvaknak – de negyven zsákot a saját pincéjébe vitt, és húszat a családjának tartott meg.
- `scenes/hori_death.png` – **Halál**: Panehsy vádja alapján Horit bebörtönözték, és ítélet nélkül halt meg a börtönlázban – mielőtt a fáraó elé kerülhetett volna.

## Párbeszéd-portrék – `portraits/<lélek>_<párbeszéd>.png`

- `portraits/kha_ipy.png` – Ipy (balzsamozómester)
- `portraits/kha_harbor.png` – Kikötőmester (a thébai kikötő felügyelője)
- `portraits/kha_treasury.png` – Szenedzsem (kincstári írnok)
- `portraits/kha_djehuty.png` – Djehuty (kincstári felügyelő (élő))
- `portraits/kha_merit.png` – Merit (Kha özvegye)
- `portraits/kha_hapu.png` – Hapu (a Hórusz Szeme kapitánya)
- `portraits/nefru_priest.png` – Hesi-Ra (papi orvos)
- `portraits/nefru_satre.png` – Szatré (szegény özvegy)
- `portraits/nefru_hut.png` – Nefru kunyhója (a hely emlékezete)
- `portraits/nefru_henut.png` – Henut (szolgálólány Ptahmose házában)
- `portraits/nefru_nebetta.png` – Nebetta úrnő (Ptahmose felesége (élő))
- `portraits/hori_paser.png` – Paser (a magtár másodírnoka)
- `portraits/hori_nakht.png` – Nakht (Kemet falu öregje)
- `portraits/hori_tuya.png` – Tuya (Hori özvegye)
- `portraits/hori_panehsy.png` – Panehsy (a magtár felügyelője (élő))

## Kártyák – `cards/<azonosító>.png`

- `cards/c_kha.png` – Kha: Kereskedő a thébai kikötőből. A Házba érkezett lélek.
- `cards/c_merit.png` – Merit: Kha felesége.
- `cards/c_djehuty.png` – Djehuty: A Két Ország kincstárának felügyelője.
- `cards/c_hapu.png` – Hapu: A Hórusz Szeme nevű hajó kapitánya.
- `cards/c_ipy.png` – Ipy: Balzsamozómester a nyugati parton.
- `cards/c_nebi.png` – Nebi: Kha apja, szegény hajós.
- `cards/e_poverty.png` – Nélkülözés: Szegénység a kikötőnegyed nádkunyhói között.
- `cards/e_first_trade.png` – Az első üzlet: Egy fiatal kereskedő első saját alkuja.
- `cards/e_wedding.png` – Házasság: Két élet egybekötése.
- `cards/e_treasury_deal.png` – Kincstári megbízás: Szerződés a királyi kincstárral.
- `cards/e_embezzlement.png` – Sikkasztás: Arany tűnik el a kincstár tekercseiből.
- `cards/e_natural_death.png` – Váratlan halál: Hirtelen láz, halál otthon – a hivatalos változat.
- `cards/e_secret_agreement.png` – Titkos alku: Egy megállapodás, amelyről senki sem tudhat.
- `cards/e_exposure.png` – Leleplezési terv: Bizonyítékok gyűjtése egy hatalmas ember ellen.
- `cards/e_staged_death.png` – Megrendezett halál: Halál a tekercsen – élet a valóságban.
- `cards/e_escape.png` – Szökés: Menekülés új néven, idegen földre.
- `cards/e_murder.png` – Gyilkosság: Erőszakos halál.
- `cards/e_false_accusation.png` – Hamis vád: Bűn, amelyet valaki más nevére írtak.
- `cards/o_gold.png` – Kincstári arany: Debenben mért aranyrudak a királyi kincstárból.
- `cards/o_royal_seal.png` – Királyi pecsét: A kincstár hitelesítő pecsétje.
- `cards/o_ring.png` – Aranykéz-gyűrű: Pecsétgyűrű kinyújtott arany kézzel.
- `cards/l_harbor.png` – Thébai kikötő: Hajók, kötelek, nádkunyhók.
- `cards/l_treasury.png` – Királyi kincstár: A Két Ország aranyának őrzőhelye.
- `cards/l_merit_house.png` – Merit háza: Kha és Merit otthona.
- `cards/l_embalming.png` – Balzsamozóház: A nyugati part balzsamozóműhelye.
- `cards/l_ship.png` – A Hórusz Szeme: Hapu kapitány hajójának fedélzete.
- `cards/m_father_ship.png` – emlék: Az apa elveszett hajója
- `cards/m_merit_promise.png` – emlék: Merit ígérete
- `cards/m_last_night.png` – emlék: Az utolsó éj

- `cards/c_nefru.png` – Nefru: Per-Hapi falu bábája és gyógyítója. A Házba érkezett lélek.
- `cards/c_satre.png` – Szatré: Szegény özvegy Per-Hapi faluban.
- `cards/c_nebetta.png` – Nebetta úrnő: Ptahmose nemes felesége.
- `cards/c_children.png` – A két csecsemő: Két fiú, akik ugyanazon az éjjelen születtek.
- `cards/c_ptahmose.png` – Ptahmose: Nemes, a kincstár hivatalnoka.
- `cards/c_tia.png` – Tia nagyanya: Nefru nagyanyja, aki a gyógyfüveket tanította neki.
- `cards/c_henut.png` – Henut: Szolgálólány Ptahmose házában.
- `cards/e_village_life.png` – Falusi gyermekkor: Szegénység, munka, a folyó áradásai.
- `cards/e_herbs.png` – A gyógyfüvek tudománya: A növények ereje, nagyanyáról unokára.
- `cards/e_midwifery.png` – A bábaság: Életre segíteni az újszülötteket.
- `cards/e_epidemic.png` – Járvány: A láz éve.
- `cards/e_two_births.png` – Két születés: Két gyermek ugyanazon az éjszakán.
- `cards/e_accusation.png` – Gyermekrablás vádja: A nemesi ház vádja.
- `cards/e_child_death.png` – Egy gyermek halála: A láz elvitte az egyik fiút.
- `cards/e_noble_demand.png` – A nemesek követelése: Egy parancs, amelyet aranyba csomagoltak.
- `cards/e_exchange.png` – A csere: Két gyermek, két karperec, egy titok.
- `cards/e_care.png` – Titkos gondoskodás: Évekig tartó, csendes gyógyítás.
- `cards/e_discovery.png` – A csere lelepleződése: Évek múltán kiderül a titok.
- `cards/e_confession.png` – Vallomás: Az utolsó napon kimondott igazság.
- `cards/o_gold.png` – Nemesi arany: Egy erszény arany Ptahmose házából.
- `cards/o_herb_pouch.png` – Gyógyfüves erszény: Nefru szárított növényei.
- `cards/l_village.png` – Per-Hapi falu: Nádkunyhók a folyó partján.
- `cards/l_noble_house.png` – Ptahmose háza: Nemesi villa a város szélén.
- `cards/l_satre_hut.png` – Szatré kunyhója: Szegény özvegy otthona.
- `cards/l_temple_healing.png` – A gyógyító templom: Papi orvosok háza.
- `cards/m_grandmother.png` – emlék: A nagyanya kertje
- `cards/m_ninth_night.png` – emlék: A kilencedik éjszaka
- `cards/m_last_confession.png` – emlék: Az utolsó gyónás

- `cards/c_hori.png` – Hori: Királyi írnok. A Házba érkezett lélek.
- `cards/c_panehsy.png` – Panehsy: A királyi magtár felügyelője.
- `cards/c_tuya.png` – Tuya: Hori felesége.
- `cards/c_nakht.png` – Nakht: Kemet falu öregje.
- `cards/c_villagers.png` – Az éhező falvak: Az aszály sújtotta falvak népe.
- `cards/e_scribe_school.png` – Az írnokiskola: Nádtoll, tinta és fegyelem.
- `cards/e_appointment.png` – Királyi kinevezés: A magtár könyveinek vezetője.
- `cards/e_greed.png` – Gazdagodás: Hivatal, amely meghízlal.
- `cards/e_drought.png` – Aszály: Két év, amikor a folyó nem áradt.
- `cards/e_theft_accusation.png` – Lopás vádja: Négyszáz zsák „hiány”.
- `cards/e_hoarding.png` – A gabona visszatartása: Gabona, amelyet a drágulásig rejtenek.
- `cards/e_altered_records.png` – A könyvek meghamisítása: Számok, amelyek mást mondanak, mint a raktár.
- `cards/e_distribution.png` – Gabonaosztás: Éjjel, titokban, a falvaknak.
- `cards/e_family_share.png` – A család része: Gabona a saját pincében.
- `cards/e_imprisonment.png` – Bebörtönzés: Lánc és sötétség.
- `cards/e_illness_death.png` – Halál a börtönben: A börtönláz.
- `cards/o_grain.png` – A királyi gabona: Pecsétes zsákok a királyi magtárból.
- `cards/o_palette.png` – Írnokpaletta: Hori nádtolla és tintái.
- `cards/l_granary.png` – A királyi magtár: Hatalmas silók a város szélén.
- `cards/l_villages.png` – Az aszályos falvak: Kemet és a déli falvak.
- `cards/l_hori_house.png` – Hori háza: Írnokház a magtár közelében.
- `cards/l_prison.png` – A börtön: A magtár alatti tömlöc.
- `cards/m_school.png` – emlék: Az írnokiskola
- `cards/m_night_carts.png` – emlék: Éjszakai szekerek
- `cards/m_prison.png` – emlék: A börtön


## Párbeszéd-hátterek – `backgrounds/bg_<lélek>_<párbeszéd>.png`

16:9 (pl. 1920×1080), keret nélkül; a szereplő a kép bal harmadában, a jobb kétharmad sötétebb, nyugodt háttér.
Ha a kép létezik, a párbeszéd teljes képernyős jelenetes nézetben nyílik meg (idézet jobbra fent,
kérdések alul); ha nincs, marad a sima nézet a portréval.

- `backgrounds/bg_kha_ipy.png`, `bg_kha_harbor.png`, `bg_kha_treasury.png`, `bg_kha_merit.png`, `bg_kha_hapu.png`, `bg_kha_djehuty.png`
