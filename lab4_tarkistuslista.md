# Lab 4 – Tarkistuslista (ProSim 8 + B650 PSMP + Robot Framework)

**Muista:** Robotin PASS kertoo vain, että ProSim kuittasi komennon. Hyväksytty/hylätty päätetään monitorin näytöltä luetusta arvosta ja hyväksymisehdosta.

## 0. Mukaan
- [x] Läppäri, USB-kaapeli, monitorin ja ProSimin kaapelit
- [x] `CustomSerialLibrary.py`, `minimal.robot`, `lab4_testit.robot`
- [x] Varalta: `FakeProSim.py` ja `fake.args`
- [x] Täytetyt suunnittelutaulukot, kamera/puhelin (kuvat ja video)

## 1. Kytkentä ja ympäristö (vaihe 1)
- [x] ProSim kytketty monitoriin (EKG, SpO₂, lämpötila, IBP, NIBP), ProSim LOCAL-tilassa
- [x] USB: ProSim ↔ läppäri
- [x] COM-portti Laitehallinnasta (Device Manager) (Portit): `COM10`
- [x] Versiot kirjattu: `python --version`, `pip show robotframework`, `pip show pyserial`, `pip show robotframework-seriallibrary`
- [x] Kuva kytkennästä (ProSim ← USB → läppäri)
- [x] Baudrate 115 200, 8N1

## 2. Yhteyden testi (vaihe 2)
- [x] Vaihda `minimal.robot`in `Library`-riville oma COM-portti, aja `robot minimal.robot` ja ota kuvakaappaus tulosteesta
- [x] `robot --variable COM:COM10 --test "T00*" --test "T01*" lab4_testit.robot`
- [x] Vertaa oikean ProSimin vastauksia feikin vastauksiin, korjaa `FakeProSim.py` jos poikkeaa

## 3. Kirjaa monitorin alkuperäiset hälytysrajat
Hälytysasetukset > Hälytysrajat. Kirjaa ennen kuin muutat mitään.

| Raja | Alkuperäinen | Testissä asetettu |
|---|---|---|
| HR yläraja |160 |147 |
| HR alaraja |40 |35 |
| SpO₂ alaraja |90 | |
| Lämpötilan yläraja (vain jos T10) |37,9 | |

## 4. Testiajot yksi testi kerrallaan (vaiheet 4–8)
Aja kansiossa, jossa ovat `lab4_testit.robot` ja `CustomSerialLibrary.py`. Korvaa `COM5` omalla portillasi.

**COM-portti, valitse yksi tapa:**
- A: jätä tiedoston `${COM}` ennalleen ja käytä komennoissa `--variable COM:COMx` (komentorivi ylikirjoittaa tiedoston arvon)
- B: muuta tiedoston `${COM}` oikeaksi ja poista `--variable COM:...` komennoista
- Pidä `${LIB}` arvossa `CustomSerialLibrary.py` (feikki vain `fake.args`in kautta)

`-d tulokset/Txx` tallentaa jokaisen testin tulokset omaan kansioonsa, jotta edellinen ajo ei ylikirjoitu.

```
robot --variable COM:COM10 --test "T00*" -d tulokset/T00 lab4_testit.robot
robot --variable COM:COM10 --test "T01*" -d tulokset/T01 lab4_testit.robot
robot --variable COM:COM10 --test "T02*" -d tulokset/T02 lab4_testit.robot
robot --variable COM:COM10 --test "T03*" -d tulokset/T03 lab4_testit.robot
robot --variable COM:COM10 --test "T04*" -d tulokset/T04 lab4_testit.robot
robot --variable COM:COM10 --test "T05*" -d tulokset/T05 lab4_testit.robot
robot --variable COM:COM10 --test "T06*" -d tulokset/T06 lab4_testit.robot
robot --variable COM:COM10 --test "T07*" -d tulokset/T07 lab4_testit.robot
robot --variable COM:COM10 --test "T08*" -d tulokset/T08 lab4_testit.robot
robot --variable COM:COM10 --test "T09*" -d tulokset/T09 lab4_testit.robot
robot --variable COM:COM10 --test "T10*" -d tulokset/T10 lab4_testit.robot
robot --variable COM:COM10 --test "T11*" -d tulokset/T11 lab4_testit.robot
robot --variable COM:COM10 --test "T12*" -d tulokset/T12 lab4_testit.robot
robot --variable COM:COM10 --test "T13*" -d tulokset/T13 lab4_testit.robot
robot --variable COM:COM10 --test "T14*" -d tulokset/T14 lab4_testit.robot
robot --variable COM:COM10 --test "T15*" -d tulokset/T15 lab4_testit.robot
```

| Testi | Huomio ennen ajoa |
|---|---|
| T00 | Ei vaadi monitoria, ProSimin pitää olla kytketty |
| T01–T04, T06, T07, T09 | Ei erityisiä esiehtoja |
| T11 IBP (ART) | Monitorin IBP-kanavan nimi asetettu arvoon ART |
| T14 SpO₂ 90 % | Aja **ennen** T08:aa, ennen SpO₂-rajan muutosta. Kirjaa oletusraja monitorista ja laukeaako hälytys |
| T15 IBP (PA) | Aja T11:n jälkeen. Vaihda monitorin IBP-kanavan nimi arvoon PA |
| T05 asystole | Hälytysskenaario 1. Ei rajan muutosta |
| T08 matala SpO₂ | Hälytysskenaario 2. Aseta SpO₂-alaraja (esim. 90) ennen ajoa, palauta heti jälkeen |
| T10 lämpötila | Valinnainen. Laske ylärajaa (esim. 38,0), kestää noin 90 s |
| T12 NIBP | Käynnistä NIBP-mittaus monitorista käsin odotusajan aikana kolme kertaa (0 %, +5 % ja −5 %) |
| T13 korkea HR | Hälytysskenaario 3. Aseta HR-yläraja (esim. 120) ennen ajoa, palauta heti jälkeen |

Jokaisessa testissä:
- [x] Aja testi, katso konsolin `Log`-rivit
- [x] Odota `SETTLE`-aika, lue monitorin arvo ja ota valokuva
- [x] Kirjaa näytetty arvo taulukkoon ja vertaa hyväksymisehtoon
- [x] Jos poikkeaa: skripti → menetelmä → laite. Toista mittaus ennen johtopäätöstä

## 5. Hälytysskenaariot (vaihe 9)
- [x] **T05 asystole:** ei rajan muutosta. Kirjaa hälytysteksti ja prioriteetti
- [x] **T08 matala SpO₂:** aseta SpO₂-alaraja esim. 90, aja, kirjaa raja, arvo ja hälytys. Palauta raja
- [x] **T13 korkea HR:** aseta HR-yläraja esim. 120, aja, kirjaa raja, arvo ja hälytys. Palauta raja
- [x] Kuva tai video jokaisesta, linkki raporttiin
- Komennot: T05, T08 ja T13 omina ajoinaan (kohta 4)

## 6. IBP ja NIBP
- [x] IBP: monitorin kanavan nimi vastaa mittauskohtaa (T11: ART, T15: PA)
- [x] NIBP: käynnistä mittaus monitorista käsin `NIBP_WAIT`-ajan aikana, kuva siirrolla 0 %, +5 % ja −5 %

## 7. Koko sarja (vaihe 10)
- [x] Hälytysrajat asetettu T08:aa ja T13:a varten (tai jätä pois: `--exclude hälytys`)
- [x] `robot --variable COM:COM10 -d tulokset/koko_sarja lab4_testit.robot`
- [x] Kuvakaappaus `report.html`-yhteenvedosta
- Huom: HR-yläraja 120 (T13:a varten) saa T03:n hälyttämään koko sarjassa. Kirjaa tämä raporttiin
- Testejä on yhteensä 16 (T00–T15)

| Testejä yhteensä | PASS | FAIL | Suoritusaika (s) |
|---|---|---|---|
|16 |16 | 0 |

## 8. Purku (vaihe 11)
- [x] ProSim LOCAL-tilaan (jos jäi REMOTE: lähetä `LOCAL` tai käynnistä uudelleen)
- [x] Monitorin hälytysrajat palautettu alkuperäisiin
- [ ] Kytkennät irti, tila siivottu

## Vianetsintä

| Oire | Tarkista |
|---|---|
| COM ei aukea | Portti, kaapeli, ajuri, ProSim päällä, ei toista ohjelmaa portissa |
| Vastaus `!01` | Komento väärin. Muoto `NSRA=060`, ei `NSRA 60` |
| Vastaus `!02` | Ei REMOTE-tilassa |
| Vastaus `!03` | Parametrin muoto tai arvo väärin (esim. `SAT=95` → `SAT=095`) |
| Tyhjä vastaus | Aikakatkaisu: kaapeli, portti tai ProSim ei vastaa |
| Arvo ei vastaa odotusta | Odotusaika, kytkentä, monitorin asetukset, referenssi |

## Raportin liitteet
- [ ] Kuvat: kytkentä, jokainen simuloitu tila, hälytykset
- [ ] Kuvakaappaukset: `minimal.robot`, `report.html`
- [ ] Koodilistaukset: EKG-testit ja muut
- [ ] Linkki videoihin (jos käytössä)
- [ ] Pohdinta myöhemmin
