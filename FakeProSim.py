"""Feikki-ProSim 8 Robot Frameworkille: testaa skriptin logiikkaa ilman laitetta.

Korvaa CustomSerialLibrary.py:n vain testauksessa (--variable LIB:FakeProSim.py).
Avainsanat ovat samat: Initialize Serial, Send Command, Close Serial.

HUOM: tämä noudattaa vain ProSim 8 Communications Interface Rev 3.17 -manuaalin
tulkintaa ja tuntee vain tämän testisarjan komennot. Se ei korvaa testiä oikealla
laitteella eikä kerro mitään monitorista.

Virheiden simulointi ympäristömuuttujilla:
  FAKE_PROSIM_FAIL_OPEN=1   portti ei aukea (Initialize Serial palauttaa False)
  FAKE_PROSIM_MUTE=1        ProSim ei vastaa (aikakatkaisu, vastaus on tyhjä)
"""
import os
import re


def _int(text, width, lo, hi, signed=False):
    pattern = r"[+-]\d{%d}" if signed else r"\d{%d}"
    if not re.fullmatch(pattern % width, text):
        return False
    return lo <= int(text) <= hi


def _bool(text):
    return text in ("TRUE", "FALSE")


def _temp(text):
    if not re.fullmatch(r"\d{2}\.\d", text):
        return False
    value = float(text)
    return 30.0 <= value <= 42.0 and (value * 2).is_integer()


def _ibpw(text):
    parts = text.split(",")
    waves = {"ART", "RART", "LV", "LA", "RV", "PA", "PAW", "RA"}
    return len(parts) == 2 and parts[0] in ("1", "2") and parts[1] in waves


def _ibpp(text):
    parts = text.split(",")
    return (len(parts) == 3 and parts[0] in ("1", "2")
            and _int(parts[1], 3, 0, 300) and _int(parts[2], 3, 0, 300))


def _nibpp(text):
    parts = text.split(",")
    return (len(parts) == 2
            and _int(parts[0], 3, 0, 400) and _int(parts[1], 3, 0, 400))


COMMANDS = {
    "ECGRUN": _bool,
    "NSRA": lambda p: _int(p, 3, 10, 360),
    "VNTWAVE": lambda p: p in ("PVC6M", "ASYS"),
    "RESPRUN": _bool,
    "RESPRATE": lambda p: _int(p, 3, 10, 150),
    "SAT": lambda p: _int(p, 3, 0, 100),
    "TEMP": _temp,
    "IBPW": _ibpw,
    "IBPP": _ibpp,
    "NIBPRUN": _bool,
    "NIBPP": _nibpp,
    "NIBPES": lambda p: _int(p, 2, -10, 10, signed=True),
}


class FakeProSim:

    def __init__(self, port, baud_rate):
        self.port = port
        self.baud_rate = baud_rate
        self.ser = None
        self.mode = "LOCAL"

    def initialize_serial(self):
        if os.environ.get("FAKE_PROSIM_FAIL_OPEN"):
            print("Failed to initialize serial connection: (simuloitu)")
            return False
        self.ser = True
        return True

    def send_command(self, command):
        if not self.ser:
            print("Serial connection not initialized.")
            return None
        print(f"Sending command: {command}")
        if os.environ.get("FAKE_PROSIM_MUTE"):
            response = ""
        else:
            response = self._handle(command)
        print(f"Response from fake Pro Sim 8: {response}")
        return response

    def close_serial(self):
        self.ser = None

    def _handle(self, command):
        cmd = command.replace(" ", "")  # ProSim ohittaa välilyönnit
        if cmd == "LOCAL":
            self.mode = "LOCAL"
            return "LOCAL"
        if cmd == "REMOTE":
            self.mode = "RMAIN"
            return "RMAIN"
        if cmd == "QMODE":
            return self.mode
        name, sep, params = cmd.partition("=")
        validator = COMMANDS.get(name)
        if validator is None:
            return "!01"            # tuntematon komento
        if self.mode != "RMAIN":
            return "!02"            # ei sallittu tässä tilassa
        if not sep or not validator(params):
            return "!03"            # virheellinen parametri
        return "*"