*** Settings ***
Documentation     Lab 4: B650 PSMP -automaatiotesti ProSim 8 -simulaattorilla.
...               Vaihda COM-portti komentoriviltä (--variable COM:COM5).
...               Tiedostoa ei ole ajettu oikealla laitteella.
Library           ${LIB}    ${COM}    115200
Test Setup        Avaa ProSim
Test Teardown     Sulje ProSim

*** Variables ***
${LIB}                   CustomSerialLibrary.py
${COM}                   COM3
${SETTLE}                30s    # HR-vaste noin 8 s (Lisätiedot-manuaali), varaa reilusti marginaalia
${SETTLE_ASYS}           20s    # asystolen hälytysviive noin 7 s
${SETTLE_SPO2_ALARM}     60s    # matalan SpO2:n hälytysviive (GE Ohmeda) noin 40 s
${SETTLE_TEMP_ALARM}     90s    # lämpötilahälytyksen viive noin 68 s
${NIBP_WAIT}             60s    # käynnistä NIBP-mittaus monitorista tämän aikana

*** Keywords ***
Avaa ProSim
    [Documentation]    Avaa yhteyden ja siirtää ProSimin REMOTE-tilaan (vastaus RMAIN).
    ${ok}=    Initialize Serial
    Should Be True    ${ok}    Sarjayhteys ei aukea: tarkista COM-portti ja kaapeli
    Aseta ProSimille    REMOTE    RMAIN

Sulje ProSim
    [Documentation]    Palauttaa ProSimin LOCAL-tilaan ja sulkee portin myös virhetilanteessa.
    Run Keyword And Ignore Error    Aseta ProSimille    LOCAL    LOCAL
    Close Serial

Palauta arvo ja sulje
    [Documentation]    Palauttaa simuloidun arvon normaaliksi, jotta hälytys ei vuoda seuraavaan testiin.
    [Arguments]    ${komento}
    Run Keyword And Ignore Error    Aseta ProSimille    ${komento}
    Sulje ProSim

Aseta ProSimille
    [Documentation]    Lähettää komennon ja hylkää testin, ellei ProSim kuittaa odotetusti.
    ...    Asetuskomennot kuittautuvat merkillä *, REMOTE/LOCAL palauttavat tilansa nimen.
    [Arguments]    ${komento}    ${odotettu}=*
    ${vastaus}=    Send Command    ${komento}
    Log    ${komento} -> ${vastaus}
    Should Be Equal As Strings    ${vastaus}    ${odotettu}
    ...    msg=ProSim ei kuitannut komentoa ${komento} odotetusti

Muistuta monitorin rajan muutoksesta
    [Documentation]    Hälytystestit vaativat monitorin hälytysrajan käsin muuttamisen. Näkyy varoituksena.
    [Arguments]    ${esiehto}
    Log    ESIEHTO (tee monitorilla ennen ajoa): ${esiehto}    WARN
    Log    JÄLKIEHTO: palauta monitorin hälytysraja alkuperäiseen arvoon    WARN

*** Test Cases ***
T00 Kuittaustarkistus tunnistaa virheellisen komennon
    [Documentation]    Testin testi: ohjeen muoto "NSRA 60" on virheellinen, ja sen PITÄÄ hylkääntyä.
    ...    Jos tämä testi ei läpäise, kuittaustarkistus ei toimi eikä muihin tuloksiin voi luottaa.
    [Tags]    varmennus
    Run Keyword And Expect Error    *ei kuitannut*    Aseta ProSimille    NSRA 60

T01 EKG NSR 60 bpm
    [Documentation]    Kohde: HR-laskenta. Lähtötila: REMOTE (Test Setup).
    ...    Odotettu tulos: HR 60 bpm, NSR-käyrä ja RR-käyrä näkyvissä.
    ...    Hyväksymisehto: HR 60 ±1 bpm (E-PSMP: ±1 % tai ±1 bpm, kumpi suurempi).
    [Tags]    EKG
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    NSRA=060
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T02 EKG bradykardia 40 bpm
    [Documentation]    Kohde: HR-laskenta alarajalla. Odotettu tulos: HR 40 bpm.
    ...    Hyväksymisehto: HR 40 ±1 bpm. Hälytystä ei odoteta oletusrajoilla, kirjaa tulos.
    [Tags]    EKG
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    NSRA=040
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T03 EKG takykardia 150 bpm
    [Documentation]    Kohde: HR-laskenta ylärajalla. Odotettu tulos: HR 150 bpm.
    ...    Hyväksymisehto: HR 150 ±1,5 bpm. Hälytystä ei odoteta oletusrajoilla, kirjaa tulos.
    [Tags]    EKG
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    NSRA=150
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T04 EKG arytmia PVC
    [Documentation]    Kohde: rytmihäiriön tunnistus. Lähtötila: NSR 60 bpm.
    ...    Odotettu tulos: PVC-lyönnit näkyvät käyrällä (6 / min).
    ...    Hyväksymisehto: PVC-lyönnit näkyvät käyrällä ja mahdollinen PVC-lukema vastaa.
    [Tags]    EKG
    [Teardown]    Palauta arvo ja sulje    NSRA=060
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    NSRA=060
    Aseta ProSimille    VNTWAVE=PVC6M
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T05 Hälytys asystole
    [Documentation]    HÄLYTYSSKENAARIO 1. Kohde: asystolen hälytys (ei riipu käyttäjän asettamasta rajasta).
    ...    Odotettu tulos: asystolehälytys monitorissa.
    ...    Hyväksymisehto: hälytys laukeaa. Kirjaa hälytysteksti ja prioriteetti.
    [Tags]    EKG    hälytys
    [Teardown]    Palauta arvo ja sulje    NSRA=060
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    VNTWAVE=ASYS
    Sleep    ${SETTLE_ASYS}
    Log    Tarkista hälytys näytöltä ja ota valokuva

T06 Hengitys 20 brpm
    [Documentation]    Kohde: impedanssihengitys. Odotettu tulos: RR 20, käyrä luettavissa.
    ...    Hyväksymisehto: RR 20 ±5 brpm (E-PSMP: ±5 % tai ±5 brpm, kumpi suurempi), käyrä luettavissa.
    [Tags]    hengitys
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    RESPRUN=TRUE
    Aseta ProSimille    RESPRATE=020
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T07 SpO2 normaali 98 prosenttia
    [Documentation]    Kohde: SpO2-lukema. Odotettu tulos: SpO2 98 %, PR näkyvissä.
    ...    Hyväksymisehto: SpO2 98 ±2 %, PR näkyvissä.
    [Tags]    SpO2
    Aseta ProSimille    SAT=098
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T14 SpO2 90 prosenttia
    [Documentation]    Kohde: SpO2-lukema ja hälytysrajan kartoitus. Aja ENNEN T08:aa (ennen SpO2-rajan muutosta).
    ...    Odotettu tulos: SpO2 90 %, PR näkyvissä. Kirjaa, laukeaako hälytys oletusrajalla.
    ...    Hyväksymisehto: SpO2 90 ±2 %, PR näkyvissä.
    [Tags]    SpO2
    [Teardown]    Palauta arvo ja sulje    SAT=098
    Aseta ProSimille    SAT=090
    Sleep    ${SETTLE_SPO2_ALARM}
    Log    Tarkista monitorin näyttö ja mahdollinen hälytys, ota valokuva

T08 Hälytys matala SpO2
    [Documentation]    HÄLYTYSSKENAARIO 2. Kohde: matalan SpO2:n hälytys. Asetettu arvo 85 %.
    ...    Esiehto: aseta monitorin SpO2-alaraja arvon 85 yläpuolelle (esim. 90) ja kirjaa alkuperäinen raja.
    ...    Odotettu tulos: hälytys, kun lukema alittaa asetetun rajan.
    ...    Hyväksymisehto: hälytys laukeaa, SpO2 85 ±2 %. Kirjaa raja, arvo ja hälytysteksti.
    [Tags]    SpO2    hälytys
    [Teardown]    Palauta arvo ja sulje    SAT=098
    Muistuta monitorin rajan muutoksesta    SpO2-alaraja esim. 90 %
    Aseta ProSimille    SAT=085
    Sleep    ${SETTLE_SPO2_ALARM}
    Log    Tarkista hälytys näytöltä ja ota valokuva

T09 Lämpötila normaali 37.0
    [Documentation]    Kohde: lämpötilalukema. Odotettu tulos: 37.0 °C.
    ...    Hyväksymisehto: 37,0 ±0,2 °C (E-PSMP, 400-sarjan anturi).
    [Tags]    lämpötila
    Aseta ProSimille    TEMP=37.0
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T10 Hälytys korkea lämpötila
    [Documentation]    Valinnainen hälytysskenaario. Kohde: korkean lämpötilan hälytys. Asetettu arvo 39.0 °C.
    ...    Esiehto: monitorin lämpötilan yläraja oletuksena 45 °C, ProSim yltää vain 42 °C:seen.
    ...    Aseta yläraja arvon 39,0 alle (esim. 38,0). Hälytysviive noin 68 s.
    ...    Hyväksymisehto: hälytys laukeaa, lämpötila 39,0 ±0,2 °C.
    [Tags]    lämpötila    hälytys
    [Teardown]    Palauta arvo ja sulje    TEMP=37.0
    Muistuta monitorin rajan muutoksesta    Lämpötilan yläraja esim. 38,0 °C
    Aseta ProSimille    TEMP=39.0
    Sleep    ${SETTLE_TEMP_ALARM}
    Log    Tarkista hälytys näytöltä ja ota valokuva

T11 IBP kanava 1 valtimopaine 120/80
    [Documentation]    Kohde: invasiivinen verenpaine. Lähtötila: IBP-kanava 1 kytketty ja
    ...    monitorin IBP-kanavan nimi asetettu (esim. ART). Odotettu tulos: 120/80 mmHg.
    ...    Hyväksymisehto: syst 120 ±4,8 mmHg (±4 %), dia 80 ±4 mmHg, aaltomuoto näkyvissä.
    [Tags]    IBP
    Aseta ProSimille    IBPW=1,ART
    Aseta ProSimille    IBPP=1,120,080
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T15 IBP kanava 1 keuhkovaltimopaine 25/10
    [Documentation]    Kohde: invasiivinen verenpaine toisessa mittauskohdassa. Lähtötila: IBP-kanava 1 kytketty
    ...    ja monitorin kanavan nimi vaihdettu arvoon PA (T11:n ART:n jälkeen). Odotettu tulos: 25/10 mmHg.
    ...    Hyväksymisehto: syst 25 ±4 mmHg, dia 10 ±4 mmHg (±4 % tai ±4 mmHg, kumpi suurempi), aaltomuoto näkyvissä.
    [Tags]    IBP
    Aseta ProSimille    IBPW=1,PA
    Aseta ProSimille    IBPP=1,025,010
    Sleep    ${SETTLE}
    Log    Tarkista monitorin näyttö ja ota valokuva

T12 NIBP envelope-siirto
    [Documentation]    Kohde: NIBP-mittaus ja verhokäyrän siirron vaikutus.
    ...    Toimenpide: ProSim tuottaa 120/80, monitorin mittaus käynnistetään käsin.
    ...    Mittaus 1 siirrolla 0 %, mittaus 2 siirrolla +5 %, mittaus 3 siirrolla -5 %.
    ...    Hyväksymisehto: kaikki lukemat ja niiden erot 0 %:n mittaukseen kirjataan
    ...    (ei numeerista rajaa dynaamiselle simulaatiolle).
    [Tags]    NIBP
    [Teardown]    Palauta arvo ja sulje    NIBPES=+00
    Aseta ProSimille    NIBPRUN=TRUE
    Aseta ProSimille    NIBPP=120,080
    Aseta ProSimille    NIBPES=+00
    Log    Käynnistä NIBP-mittaus monitorista ja ota valokuva (siirto 0 %)
    Sleep    ${NIBP_WAIT}
    Aseta ProSimille    NIBPES=+05
    Log    Käynnistä NIBP-mittaus uudelleen ja ota valokuva (siirto +5 %)
    Sleep    ${NIBP_WAIT}
    Aseta ProSimille    NIBPES=-05
    Log    Käynnistä NIBP-mittaus uudelleen ja ota valokuva (siirto -5 %)
    Sleep    ${NIBP_WAIT}

T13 Hälytys korkea syke
    [Documentation]    HÄLYTYSSKENAARIO 3. Kohde: korkean HR-rajan hälytys. Asetettu arvo 150 bpm.
    ...    Esiehto: aseta monitorin HR:n yläraja arvon 150 alle (esim. 120) ja kirjaa alkuperäinen raja.
    ...    Odotettu tulos: korkean sykkeen hälytys, kun HR ylittää asetetun rajan.
    ...    Hyväksymisehto: hälytys laukeaa, HR 150 ±1,5 bpm. Kirjaa raja, arvo ja hälytysteksti.
    [Tags]    EKG    hälytys
    [Teardown]    Palauta arvo ja sulje    NSRA=060
    Muistuta monitorin rajan muutoksesta    HR:n yläraja esim. 120 bpm
    Aseta ProSimille    ECGRUN=TRUE
    Aseta ProSimille    NSRA=150
    Sleep    ${SETTLE}
    Log    Tarkista hälytys näytöltä ja ota valokuva
