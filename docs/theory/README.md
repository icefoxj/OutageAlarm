# OA-01 theory

OA-01 is a small machine with a single job: make a noise the moment the wall outlet goes dead, and keep making it on its own battery. It does that with no microcontroller and no firmware, only a USB charger, a TP4056 charger module with protection, an 18650 cell, a relay, a diode, a resistor, an LED, two switches and an active buzzer. Every decision a program would take is taken by physics: a magnet that lets go, a spring that pulls back, a contact that closes.

These chapters explain all of that theory, from the fundamentals to the actual circuit and enclosure of OA-01, for an engineering student or an advanced maker. They need basic circuit theory (Ohm's law, capacitors, inductors), a little physics and the patience to follow a few logarithms.

OA-01 is **in development**: the circuit is designed and documented, the enclosure has not been test-printed yet and nothing has been measured on a finished unit. The numbers taken from the kit (coil current, charge current, battery capacity, resistor values, dimensions) are **design values**. The figures marked *simulation* come from simple models run by [figures.py](figures.py); wherever a model needs a value the kit does not give (the capacitors inside the charger, the inductance of the coil, the sound level of the buzzer...), the value is an **illustrative assumption** and the caption says so.

## Reading order

| # | Chapter | What you learn | Needs |
|---|---|---|---|
| 1 | [The fail-safe principle](01-fail-safe-principle.md) | energise-to-alarm vs de-energise-to-alarm, the circuit as Boolean logic, its states, failure modes, hidden failures and why the TEST button cuts the coil | logic, a little probability |
| 2 | [Mains, isolation and the 5 V signal](02-mains-and-isolation.md) | the mains, why no mains on the board, how a charger isolates, USB-C detection, hold-up time, the response time | AC circuits, capacitors |
| 3 | [The relay K1](03-the-relay.md) | magnetic circuit, pull-in and drop-out, the coil as an inductor, the flyback diode D1, contacts, timing of the chain | magnetism, RL circuits |
| 4 | [The cell, the charger and the protection](04-cell-and-charger.md) | Li-ion basics, capacity and energy, CC/CV charging, the program resistor, heat in a linear charger, the DW01A and 8205A protection | chapter 2 |
| 5 | [The alarm sound](05-the-sound.md) | sound pressure and decibels, A-weighting, piezo buzzers, level vs distance, the grille, the boost option | logarithms |
| 6 | [Power budget and autonomy](06-power-budget.md) | sizing the charger, the LED, what standby costs, how long the alarm lasts, recharging | chapters 3–5 |
| 7 | [The enclosure](07-enclosure.md) | the wedge, heat in a closed box, materials, printing without supports, the inlaid livery, the glued joint | chapter 4 |

Chapters 1 and 2 are the core idea; 3 to 6 follow the energy through the circuit; 7 is the box around it. Each chapter ends with a summary table.

## Notation

| Symbol | Meaning | Unit | OA-01 value |
|---|---|---|---|
| $V_{USB}$ | output of the USB charger | V | 5 |
| $R_c$ | resistance of K1's coil (SRD-05VDC-SL-C) | Ω | ≈ 70 |
| $P_c$ | coil power | W | 0.36 |
| $I_c$ | coil current, $P_c / V_{USB}$ | mA | ≈ 72 |
| $L_c$ | coil inductance | H | 0.15 (illustrative assumption) |
| $V_{rel}$ | voltage below which K1 releases | V | ≈ 1–2 |
| $R_1$ | LED series resistor | Ω | 1 k (470 for a brighter LED) |
| $V_f$ | forward voltage of the green LED | V | ≈ 2.1 |
| $I_{LED}$ | LED current | mA | ≈ 2.9 |
| $C$ | capacity of the 18650 cell | mAh | 2000–3500 (2500 in the examples) |
| $V_{bat}$ | cell voltage | V | 2.5–4.2 (3.7 nominal) |
| $I_{chg}$ | TP4056 charge current | A | 1 (with $R_{PROG}$ = 1.2 kΩ) |
| $R_{PROG}$ | TP4056 program resistor (R3 on the module) | kΩ | 1.2 (2.4 for 500 mA) |
| $I_{bz}$ | buzzer current at 3.7 V | mA | 5–10 (estimate) |
| $t_{run}$ | run time of the alarm on the cell | h | > 100 |
| $L_p$ | sound pressure level | dB | |
| $r$ | distance from the buzzer | m | |

Designators are the ones of the schematic and the bill of materials: U1 (TP4056 module), BT1 (18650 cell), K1 (relay), D1 (1N4007), R1 (1 kΩ), LED1 (POWER), BZ1 (SFM-27), SW1 (ARM), SW2 (TEST). NC and NO are the normally closed and normally open contacts.

## Regenerating the figures

```bash
python docs/theory/figures.py     # all figures -> docs/img/theory/, numbers on stdout
```

The script needs numpy and matplotlib. It holds small models of the charger, the relay, the cell, the buzzer and the enclosure, with the kit values at the top and every assumption written next to the model that uses it. Change a value (a 3500 mAh cell, a 2.4 kΩ program resistor, a louder buzzer) and run it again to see what changes.
