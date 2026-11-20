"""Figures and numbers for the OA-01 (OutageAlarm v1) theory chapters.

Self-contained: numpy + matplotlib. It re-implements, in a few lines of Python,
simple models of the parts described in docs/electronics.md (USB charger, relay
K1, TP4056 + DW01A module, 18650 cell, SFM-27 buzzer, enclosure), so the plots
in docs/img/theory/ can be regenerated.

    python docs/theory/figures.py      # all figures -> docs/img/theory/, numbers on stdout

The kit values (coil 70 ohm / 72 mA, 1 A charge, 1.2 kOhm program resistor,
2000-3500 mAh cell, 5-10 mA buzzer current, 1 kOhm LED resistor, enclosure
dimensions) come from the repository. Everything else (charger capacitors,
coil inductance, cell curve, sound levels, thermal masses...) is an
ILLUSTRATIVE assumption, stated next to each model. OA-01 is in development:
nothing here has been measured on the kit.
"""
from __future__ import annotations

import math
import os

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "img", "theory"))

# ----------------------------------------------------------------------------
# Kit values (docs/electronics.md, README.md, hardware/mechanical/enclosure.scad)
# ----------------------------------------------------------------------------

V_USB = 5.0            # USB charger output (V)
R_COIL = 70.0          # K1 coil, SRD-05VDC-SL-C (ohm)
P_COIL = 0.36          # K1 coil power (W)
V_LED = 2.1            # green LED forward voltage (V)
R1 = 1000.0            # LED resistor (ohm)
I_CHG = 1.0            # TP4056 charge current with R_PROG = 1.2 kOhm (A)
R_PROG = 1200.0
CAP_MAH = (2000, 2500, 3500)   # 18650 capacity range (mAh)
I_BZ = (5e-3, 10e-3)   # SFM-27 current at 3.7 V, estimate (A)
V_DW01_CUT = 2.5       # over-discharge cut, "about 2.5 V" in electronics.md (DW01A typ. 2.4 V)
V_TRICKLE = 2.9        # TP4056 pre-charge threshold (datasheet)
V_CV = 4.2             # TP4056 regulation voltage
V_RECHARGE = 4.05      # TP4056 automatic recharge threshold
V_OVERCHARGE = 4.3     # DW01A over-charge detection (typ. 4.25-4.3 V)
V_BZ_MIN = 3.0         # SFM-27 rated range 3-24 V

# enclosure outer box: 122.8 x 74.8 mm, 33 mm high at the front, 58.5 mm at the back
BOX_X, BOX_Y, BOX_HF, BOX_HB = 0.1228, 0.0748, 0.033, 0.0585

# ----------------------------------------------------------------------------
# Plot style: graphite + yellow (same as the other 3DTesla kits)
# ----------------------------------------------------------------------------

BG, AX, GRID, FG = "#1d2125", "#252a30", "#3b424b", "#e6e6e6"
YELLOW, WHITE, CYAN, GREEN, RED, GREY = "#ffcc00", "#f2f2f2", "#4fc3f7", "#38d47a", "#ff5c5c", "#9aa3ad"


def style():
    plt.rcParams.update({
        "figure.facecolor": BG, "axes.facecolor": AX, "savefig.facecolor": BG,
        "axes.edgecolor": GRID, "axes.labelcolor": FG, "xtick.color": FG, "ytick.color": FG,
        "text.color": FG, "grid.color": GRID, "grid.linestyle": "-", "grid.linewidth": 0.6,
        "axes.grid": True, "axes.titleweight": "bold", "axes.titlesize": 11, "font.size": 9.5,
        "legend.facecolor": AX, "legend.edgecolor": GRID, "lines.linewidth": 1.8,
        "axes.prop_cycle": matplotlib.cycler(color=[YELLOW, WHITE, CYAN, GREEN, RED, GREY]),
    })


def banner(fig, text):
    fig.text(0.008, 0.985, text, ha="left", va="top", fontsize=8, color=YELLOW, family="monospace",
             fontweight="bold")
    fig.text(0.992, 0.985, "OA-01 // SIMULATION", ha="right", va="top", fontsize=8, color=GREY,
             family="monospace")


def save(fig, name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=130)
    plt.close(fig)
    print(f"  wrote {os.path.relpath(path, os.path.join(HERE, '..', '..'))}")


# ----------------------------------------------------------------------------
# Models
# ----------------------------------------------------------------------------

# Generic NMC 18650 open-circuit voltage vs state of charge (illustrative, typical shape)
_SOC = np.array([0.0, 0.01, 0.03, 0.06, 0.10, 0.15, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 0.95, 1.0])
_OCV = np.array([2.50, 2.90, 3.20, 3.36, 3.45, 3.50, 3.55, 3.62, 3.68, 3.74, 3.82, 3.90, 3.98, 4.07, 4.13, 4.20])


def ocv(soc):
    return np.interp(soc, _SOC, _OCV)


R_CELL = 0.25   # effective cell + contact + polarisation resistance seen while charging (ohm, illustrative)


def charge(cap_mah, i_set, soc0=0.0, dt=5.0, t_max=10 * 3600):
    """TP4056-style pre-charge / CC / CV charge of the cell model. Returns t (s), I (A), Vbat (V), SOC."""
    cap = cap_mah / 1000 * 3600   # coulombs
    t, soc = 0.0, soc0
    T, I, V, S = [], [], [], []
    while t < t_max:
        e = ocv(soc)
        if e < V_TRICKLE:
            i = 0.1 * i_set
        else:
            i = min(i_set, (V_CV - e) / R_CELL)
        v = e + i * R_CELL
        T.append(t); I.append(i); V.append(v); S.append(soc)
        if e >= V_TRICKLE and i < 0.1 * i_set:
            break   # termination at C/10 of the programmed current
        soc = min(1.0, soc + i * dt / cap)
        t += dt
    return np.array(T), np.array(I), np.array(V), np.array(S)


def discharge(cap_mah, i_load, dt=60.0):
    """Constant-current discharge until the DW01A cuts the output. Returns t (h), V."""
    cap = cap_mah / 1000 * 3600
    t, soc = 0.0, 1.0
    T, V = [], []
    while True:
        v = ocv(soc) - i_load * 0.05
        T.append(t / 3600); V.append(v)
        if v <= V_DW01_CUT or soc <= 0:
            break
        soc -= i_load * dt / cap
        t += dt
    return np.array(T), np.array(V)


def holdup(c_bulk, v_peak, p_out, eta=0.75, v_uvlo=70.0):
    """Time the charger keeps its 5 V up after the mains disappears, from its bulk capacitor energy."""
    return c_bulk * (v_peak ** 2 - v_uvlo ** 2) / (2 * p_out / eta)


# ----------------------------------------------------------------------------
# Figures
# ----------------------------------------------------------------------------

def fig_proof_test():
    lam = 0.1 / (365 * 24)             # one hidden failure per 10 years (per hour, illustrative)
    t = np.linspace(0, 2 * 365 * 24, 4000)
    fig, ax = plt.subplots(figsize=(7.2, 4.0))
    banner(fig, "FIG T1 // HIDDEN FAILURES AND THE MONTHLY TEST")
    cases = [(None, RED, "never tested"), (182 * 24, CYAN, "tested every 6 months"),
             (30 * 24, YELLOW, "tested every month (as the README asks)")]
    print("T1 proof test (lambda = 0.1 /year):")
    for T, col, lab in cases:
        since = t if T is None else np.mod(t, T)
        p = 1 - np.exp(-lam * since)
        ax.plot(t / 24 / 30.4, p * 100, color=col, label=lab)
        if T is not None:
            avg = lam * T / 2
            ax.axhline(avg * 100, color=col, lw=0.9, ls="--")
            print(f"  test every {T / 24:.0f} days: average probability of a hidden failure {avg * 100:.2f} %")
    ax.set_xlabel("time (months)")
    ax.set_ylabel("probability that a failure is hidden (%)")
    ax.set_xlim(0, 24)
    ax.set_ylim(0, 20)
    ax.legend(fontsize=8, loc="upper left")
    ax.annotate("dashed: average over the test interval", (13, 3.6), color=GREY, fontsize=8)
    ax.annotate("assumed failure rate: 1 in 10 years", (13, 16.5), color=GREY, fontsize=8)
    save(fig, "proof_test.png")


def fig_outage_timeline():
    """Mains cut at t = 0: bulk capacitor, 5 V output, coil current, relay contact."""
    f, vpk = 50.0, 325.0
    cb, co = 4.7e-6, 470e-6              # bulk and output capacitors (illustrative)
    p_in = (V_USB ** 2 / R_COIL + (V_USB - V_LED) / R1 * V_USB) / 0.75
    v_uvlo, v_rel = 70.0, 1.5
    dt = 2e-5
    t = np.arange(-0.06, 0.8, dt)
    vb = np.empty_like(t); vo = np.empty_like(t)
    b, o = vpk, V_USB
    regulating = True
    t_off = t_rel = None
    for k, tk in enumerate(t):
        ac = vpk * abs(math.sin(2 * math.pi * f * tk)) if tk < 0 else 0.0
        if regulating:
            b = max(b - p_in / max(b, 1) / cb * dt, 0)
            if b < v_uvlo:
                regulating = False
                t_off = tk
        if ac > b:
            b = ac
            regulating = True
        if regulating:
            o = V_USB
        else:
            i_load = o / R_COIL + max(o - V_LED, 0) / R1
            o = max(o - i_load / co * dt, 0)
            if t_rel is None and o < v_rel:
                t_rel = tk
        vb[k], vo[k] = b, o
    ac_wave = np.where(t < 0, vpk * np.sin(2 * math.pi * f * t), 0)
    fig, axs = plt.subplots(3, 1, figsize=(7.2, 5.6), sharex=True)
    banner(fig, "FIG T2 // FROM OUTAGE TO ALARM")
    axs[0].plot(t * 1000, ac_wave, color=GREY, lw=1, label="mains (230 V, 50 Hz)")
    axs[0].plot(t * 1000, vb, color=YELLOW, label="bulk capacitor in the charger")
    axs[0].axhline(v_uvlo, color=RED, lw=0.9, ls="--")
    axs[0].annotate("converter stops", (t_off * 1000 + 8, v_uvlo + 18), color=RED, fontsize=8)
    axs[0].set_ylabel("V")
    axs[0].legend(fontsize=7.5, loc="upper right")
    axs[1].plot(t * 1000, vo, color=CYAN, label="5 V output = coil voltage")
    axs[1].axhspan(1.0, 2.0, color=RED, alpha=0.18)
    axs[1].annotate("release band 1-2 V", (20, 1.25), color=RED, fontsize=8)
    axs[1].set_ylabel("V")
    axs[1].set_ylim(0, 6)
    axs[1].legend(fontsize=7.5, loc="lower left")
    contact = np.where(t < t_rel, 0, 1)
    axs[2].step(t * 1000, contact, color=GREEN, where="post")
    axs[2].set_yticks([0, 1])
    axs[2].set_yticklabels(["open", "closed"])
    axs[2].set_ylabel("NC contact")
    axs[2].set_ylim(-0.3, 1.4)
    axs[2].annotate(f"buzzer on after {t_rel * 1000:.0f} ms", (t_rel * 1000 + 10, 0.55), color=GREEN, fontsize=8)
    axs[2].set_xlabel("time after the outage (ms); bulk 4.7 µF, output 470 µF: illustrative values")
    for a in axs:
        a.axvline(0, color=GREY, lw=0.9)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    save(fig, "outage_timeline.png")
    print(f"T2 outage timeline: input power {p_in:.2f} W, converter stops at {t_off * 1000:.0f} ms, "
          f"relay releases at {t_rel * 1000:.0f} ms")


def fig_holdup():
    p = np.logspace(-1, 1.2, 200)
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    banner(fig, "FIG T3 // HOLD-UP TIME OF THE CHARGER")
    for cb, col in [(4.7e-6, YELLOW), (10e-6, CYAN), (22e-6, GREEN)]:
        ax.loglog(p, holdup(cb, 325, p), color=col, label=f"{cb * 1e6:.1f} µF, 230 V mains")
        ax.loglog(p, holdup(cb, 170, p), color=col, ls="--", lw=1.3, label=f"{cb * 1e6:.1f} µF, 120 V mains")
    p_standby = V_USB ** 2 / R_COIL + (V_USB - V_LED) / R1 * V_USB
    p_charge = V_USB * (I_CHG + V_USB / R_COIL + (V_USB - V_LED) / R1)
    for pp, lab in [(p_standby, "standby\n(relay + LED)"), (p_charge, "recharging\nthe cell")]:
        ax.axvline(pp, color=WHITE, lw=1)
        ax.annotate(lab, (pp * 1.08, 4.0), fontsize=8, color=WHITE)
    ax.axhline(0.1, color=RED, lw=0.9, ls=":")
    ax.annotate("0.1 s", (0.105, 0.115), color=RED, fontsize=8)
    ax.set_xlabel("load on the 5 V output (W)")
    ax.set_ylabel("hold-up time (s)")
    ax.set_ylim(0.005, 10)
    ax.legend(fontsize=7, loc="lower left", ncol=2)
    ax.set_title("efficiency 75 %, converter stops at 70 V (assumed)", fontsize=8.5, color=GREY, fontweight="normal")
    save(fig, "holdup.png")
    print(f"T3 hold-up: standby load {p_standby:.3f} W, charging load {p_charge:.2f} W; "
          f"4.7 uF @230 V: {holdup(4.7e-6, 325, p_standby):.2f} s standby, {holdup(4.7e-6, 325, p_charge) * 1000:.0f} ms charging")


def fig_relay_forces():
    g = np.linspace(0, 0.4, 200)          # armature gap (mm), 0 = closed (energised)
    g0 = 0.1                              # residual (non-magnetic) gap, illustrative
    # spring: 1 unit with the armature open (0.4 mm), 4.6 units closed: chosen so that
    # pull-in is at 3.5 V and drop-out at 1.5 V, typical of a 5 V relay
    fs = 1.0 + (4.6 - 1.0) * (0.4 - g) / 0.4
    a = 1.0 * (0.4 + g0) ** 2 / 3.5 ** 2
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    banner(fig, "FIG T4 // RELAY: MAGNET AGAINST SPRING")
    ax.plot(g, fs, color=WHITE, lw=2.2, label="return spring (and contact springs)")
    for v, col in [(1.0, RED), (1.5, GREY), (3.5, CYAN), (5.0, YELLOW)]:
        fm = a * v ** 2 / (g + g0) ** 2
        ax.plot(g, fm, color=col, label=f"magnetic pull, coil at {v:.1f} V")
    ax.set_xlabel("air gap between armature and core (mm); 0 = relay energised")
    ax.set_ylabel("force (relative)")
    ax.set_ylim(0, 8)
    ax.set_xlim(0, 0.4)
    ax.invert_xaxis()
    ax.legend(fontsize=7.5, loc="upper left")
    ax.annotate("pull-in: magnet wins\nat the open gap", (0.395, 1.6), color=CYAN, fontsize=8)
    ax.annotate("drop-out: spring wins\nat the closed gap", (0.15, 2.3), color=GREY, fontsize=7.5)
    ax.set_title("illustrative model: force ~ (V / gap)²", fontsize=8.5, color=GREY, fontweight="normal")
    save(fig, "relay_forces.png")


def fig_flyback():
    L = 0.15                              # coil inductance (H), illustrative
    tau = L / R_COIL
    i0 = V_USB / R_COIL
    t = np.linspace(-2e-3, 12e-3, 1400)
    fig, axs = plt.subplots(1, 2, figsize=(7.2, 3.9))
    banner(fig, "FIG T5 // SWITCHING THE COIL OFF")
    vd = 0.7
    i_d = np.where(t < 0, i0, np.maximum((i0 + vd / R_COIL) * np.exp(-t / tau) - vd / R_COIL, 0))
    axs[0].plot(t * 1000, i_d * 1000, color=YELLOW, label="with D1: decays through the diode")
    axs[0].plot(t * 1000, np.where(t < 0, i0, 0) * 1000, color=RED, lw=1.3, label="without D1: forced to zero")
    axs[0].axhline(1.5 / R_COIL * 1000, color=GREY, ls="--", lw=0.9)
    axs[0].annotate("release current", (5, 1.5 / R_COIL * 1000 + 2), color=GREY, fontsize=8)
    axs[0].set_xlabel("time after TEST opens (ms)")
    axs[0].set_ylabel("coil current (mA)")
    axs[0].set_ylim(0, 85)
    axs[0].legend(fontsize=7, loc="upper right")
    # without the diode: the coil rings with the stray capacitance of the wiring and the switch
    cs = 100e-12
    w = 1 / math.sqrt(L * cs)
    ts = np.linspace(0, 40e-6, 800)
    alpha = R_COIL / (2 * L)
    v = -i0 * math.sqrt(L / cs) * np.exp(-alpha * ts) * np.sin(w * ts)
    axs[1].plot(ts * 1e6, v / 1000, color=RED, label="without D1 (no arc, ideal)")
    axs[1].plot(ts * 1e6, np.full_like(ts, -vd / 1000), color=YELLOW, label="with D1: -0.7 V")
    axs[1].set_xlabel("time (µs)")
    axs[1].set_ylabel("voltage across the coil (kV)")
    axs[1].legend(fontsize=7, loc="upper left")
    axs[1].set_ylim(-3.6, 4.2)
    axs[1].annotate(f"peak ≈ {i0 * math.sqrt(L / cs) / 1000:.1f} kV", (8, -3.35), color=RED, fontsize=8)
    fig.text(0.5, 0.005, "assumed: coil inductance 0.15 H, stray capacitance 100 pF", ha="center", fontsize=7.5,
             color=GREY)
    fig.tight_layout(rect=(0, 0.03, 1, 0.95))
    save(fig, "flyback.png")
    print(f"T5 flyback: I0 = {i0 * 1000:.1f} mA, tau = {tau * 1000:.2f} ms, ideal peak {i0 * math.sqrt(L / cs):.0f} V, "
          f"energy {0.5 * L * i0 ** 2 * 1000:.2f} mJ")


def fig_ocv():
    s = np.linspace(0, 1, 400)
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    banner(fig, "FIG T6 // THE CELL AND ITS THRESHOLDS")
    ax.plot(s * 100, ocv(s), color=YELLOW, lw=2.4, label="open-circuit voltage, generic 18650 (typical shape)")
    marks = [(V_OVERCHARGE, RED, "4.3 V: DW01A over-charge cut"), (V_CV, CYAN, "4.2 V: TP4056 constant-voltage level"),
             (V_RECHARGE, CYAN, "4.05 V: TP4056 starts a new charge"), (V_BZ_MIN, GREY, "3.0 V: lowest rated buzzer voltage"),
             (V_TRICKLE, GREEN, "2.9 V: below it, pre-charge at 1/10 current"),
             (V_DW01_CUT, RED, "≈ 2.5 V: DW01A cuts the output (alarm stops)")]
    for v, col, lab in marks:
        ax.axhline(v, color=col, lw=0.9, ls="--")
        ax.annotate(lab, (99, v + 0.025), color=col, fontsize=7.5, ha="right")
    ax.set_xlabel("state of charge (%)")
    ax.set_ylabel("cell voltage (V)")
    ax.set_xlim(0, 100)
    ax.set_ylim(2.35, 4.45)
    ax.legend(fontsize=7.5, loc="center left", bbox_to_anchor=(0.0, 0.62))
    save(fig, "cell_ocv.png")


def fig_charge():
    fig, axs = plt.subplots(2, 1, figsize=(7.2, 5.2), sharex=True)
    banner(fig, "FIG T7 // RECHARGING AFTER A LONG OUTAGE")
    print("T7 charge (2500 mAh from the DW01A cut):")
    for i_set, col, lab in [(1.0, YELLOW, "1 A (R_PROG = 1.2 kΩ, as built)"), (0.5, CYAN, "0.5 A (R_PROG = 2.4 kΩ, cooler)")]:
        t, i, v, s = charge(2500, i_set)
        h = t / 3600
        axs[0].plot(h, v, color=col, label=lab)
        axs[1].plot(h, i * 1000, color=col)
        axs[1].plot(h, s * 1000, color=col, ls=":", lw=1.3)
        k_cv = np.argmax(v >= V_CV - 1e-3)
        print(f"  {i_set:.1f} A: CV from {h[k_cv]:.2f} h, terminates at {h[-1]:.2f} h, SOC {s[-1] * 100:.0f} %")
    axs[0].axhline(V_CV, color=GREY, ls="--", lw=0.9)
    axs[0].set_ylabel("cell terminal voltage (V)")
    axs[0].set_ylim(2.4, 4.4)
    axs[0].legend(fontsize=7.5, loc="lower right")
    axs[0].annotate("CC", (0.6, 3.95), color=WHITE, fontsize=9, fontweight="bold")
    axs[0].annotate("CV", (2.4, 4.25), color=WHITE, fontsize=9, fontweight="bold")
    axs[1].set_ylabel("current (mA), dotted: charge in (‰)")
    axs[1].set_xlabel("time (h); 2500 mAh cell, illustrative cell model")
    axs[1].set_ylim(0, 1100)
    fig.tight_layout(rect=(0, 0, 1, 0.96))
    save(fig, "charge_cccv.png")


def fig_dissipation():
    fig, ax = plt.subplots(figsize=(7.2, 3.9))
    banner(fig, "FIG T8 // HEAT IN THE LINEAR CHARGER")
    print("T8 TP4056 dissipation:")
    for i_set, col in [(1.0, YELLOW), (0.5, CYAN)]:
        t, i, v, s = charge(2500, i_set)
        p = (V_USB - v) * i
        e = np.trapezoid(p, t) if hasattr(np, "trapezoid") else np.trapz(p, t)
        ax.plot(t / 3600, p, color=col, label=f"{i_set:.1f} A charge: {e / 3600:.2f} Wh of heat")
        print(f"  {i_set:.1f} A: peak {p.max():.2f} W, mean in CC {p[(i >= 0.999 * i_set)].mean():.2f} W, "
              f"heat {e / 3600:.2f} Wh")
    ax.set_xlabel("time (h); 2500 mAh cell recharged from the cut-off")
    ax.set_ylabel("power dissipated in the TP4056 (W)")
    ax.set_ylim(0, 2.0)
    ax.legend(fontsize=8)
    ax.annotate("P = (5 V - Vbat) × I", (3.6, 1.6), color=WHITE, fontsize=9)
    ax.set_title("thermal regulation may lower the current when the chip is hot", fontsize=8.5, color=GREY,
                 fontweight="normal")
    save(fig, "charger_heat.png")


def a_weight(f):
    f2 = f ** 2
    ra = (12194 ** 2 * f2 ** 2) / ((f2 + 20.6 ** 2) * np.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2)) * (f2 + 12194 ** 2))
    return 20 * np.log10(ra) + 2.0


def fig_a_weight():
    f = np.logspace(np.log10(20), np.log10(20000), 400)
    fig, ax = plt.subplots(figsize=(7.2, 3.9))
    banner(fig, "FIG T9 // HOW LOUD THE EAR FINDS EACH PITCH")
    ax.semilogx(f, a_weight(f), color=YELLOW, lw=2.2, label="A-weighting (IEC 61672)")
    ax.axvspan(2000, 4000, color=CYAN, alpha=0.18)
    ax.annotate("2-4 kHz: where small piezo\nbuzzers usually sing", (2100, -32), color=CYAN, fontsize=8)
    ax.axvspan(85, 3400, ymin=0.93, ymax=0.97, color=GREY, alpha=0.6)
    ax.annotate("voice band", (300, 1.0), color=GREY, fontsize=7.5)
    ax.set_xlabel("frequency (Hz)")
    ax.set_ylabel("relative level (dB)")
    ax.set_ylim(-50, 6)
    ax.set_xlim(20, 20000)
    ax.legend(fontsize=8, loc="lower right")
    save(fig, "a_weighting.png")


def fig_spl_distance():
    r = np.logspace(-1, 1.2, 300)
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    banner(fig, "FIG T10 // SOUND LEVEL AND DISTANCE")
    for l1, col in [(70, CYAN), (80, YELLOW)]:
        ax.semilogx(r, l1 - 20 * np.log10(r), color=col, lw=1.6, ls="--", label=f"free field, {l1} dB at 1 m")
    # same 80 dB source in a room: direct + reverberant field (Sabine)
    S, alpha, Q = 85.0, 0.3, 2.0          # 4 x 5 x 2.5 m room, alpha 0.3, source on a shelf
    Rr = S * alpha / (1 - alpha)
    lw = 80 - 10 * np.log10(Q / (4 * np.pi))
    lroom = lw + 10 * np.log10(Q / (4 * np.pi * r ** 2) + 4 / Rr)
    ax.semilogx(r, lroom, color=YELLOW, lw=2.4, label="the 80 dB source in a 4 × 5 m room")
    rc = math.sqrt(Q * Rr / (16 * math.pi))
    ax.axvline(rc, color=GREY, lw=0.9, ls=":")
    ax.annotate(f"reverberation radius ≈ {rc:.1f} m", (rc * 1.07, 22.5), color=GREY, fontsize=8)
    for lvl, lab in [(30, "quiet bedroom at night"), (45, "quiet living room"), (60, "conversation, TV")]:
        ax.axhline(lvl, color=GREY, lw=0.8)
        ax.annotate(lab, (0.105, lvl + 1), color=GREY, fontsize=7.5)
    ax.set_xlabel("distance from the buzzer (m)")
    ax.set_ylabel("sound pressure level (dB)")
    ax.set_xlim(0.1, 16)
    ax.set_ylim(20, 105)
    ax.legend(fontsize=7.5, loc="upper right")
    ax.set_title("illustrative source levels, not a measurement of the SFM-27", fontsize=8.5, color=GREY,
                 fontweight="normal")
    save(fig, "spl_distance.png")
    print(f"T10 room: room constant {Rr:.1f} m2, reverberation radius {rc:.2f} m, "
          f"level at 4 m: free {80 - 20 * math.log10(4):.1f} dB, room {lw + 10 * math.log10(Q / (4 * math.pi * 16) + 4 / Rr):.1f} dB")


def fig_drive_boost():
    fig, axs = plt.subplots(1, 2, figsize=(7.2, 3.9))
    banner(fig, "FIG T11 // LOUDER WITH A BOOST CONVERTER")
    v = np.linspace(2.5, 24, 300)
    axs[0].plot(v, 20 * np.log10(v / 3.7), color=YELLOW)
    for vv, lab in [(3.0, "3.0 V"), (3.7, "3.7 V cell"), (4.2, "4.2 V"), (12.0, "12 V boost")]:
        d = 20 * math.log10(vv / 3.7)
        axs[0].plot([vv], [d], "o", color=CYAN, ms=5)
        axs[0].annotate(f"{lab}: {d:+.1f} dB", (vv + 0.6, d - 1.6), color=CYAN, fontsize=7.5)
    axs[0].set_xlabel("buzzer supply voltage (V)")
    axs[0].set_ylabel("level relative to 3.7 V (dB)")
    axs[0].set_title("idealised: pressure ∝ drive voltage", fontsize=8.5, color=GREY, fontweight="normal")
    ib12 = np.linspace(5, 20, 100) * 1e-3
    eta = 0.85
    for cap, col in [(2000, CYAN), (2500, YELLOW), (3500, GREEN)]:
        ibat = 12 * ib12 / (3.7 * eta)
        axs[1].plot(ib12 * 1000, cap / 1000 / ibat, color=col, label=f"{cap} mAh")
    axs[1].axhline(24, color=GREY, ls="--", lw=0.9)
    axs[1].annotate("1 day", (5.3, 26), color=GREY, fontsize=8)
    axs[1].set_xlabel("buzzer current at 12 V (mA)")
    axs[1].set_ylabel("run time with the boost (h)")
    axs[1].set_title("MT3608 at 85 % efficiency (assumed)", fontsize=8.5, color=GREY, fontweight="normal")
    axs[1].legend(fontsize=7.5)
    axs[1].set_ylim(0, 160)
    fig.tight_layout(rect=(0, 0, 1, 0.95))
    save(fig, "boost.png")
    print(f"T11 boost: 12 V vs 3.7 V = {20 * math.log10(12 / 3.7):+.1f} dB; 2500 mAh at 20 mA/12 V: "
          f"{2.5 / (12 * 0.02 / (3.7 * eta)):.0f} h")


def fig_discharge():
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    banner(fig, "FIG T12 // THE CELL RUNNING THE ALARM")
    print("T12 discharge at 10 mA:")
    for cap, col in [(2000, CYAN), (2500, YELLOW), (3500, GREEN)]:
        t, v = discharge(cap, 10e-3)
        ax.plot(t, v, color=col, label=f"{cap} mAh at 10 mA: {t[-1]:.0f} h")
        t3 = t[np.argmax(v <= V_BZ_MIN)]
        print(f"  {cap} mAh: below 3.0 V after {t3:.0f} h, cut at {t[-1]:.0f} h ({t[-1] / 24:.1f} days)")
    ax.axhline(V_BZ_MIN, color=GREY, ls="--", lw=0.9)
    ax.annotate("3.0 V: lowest rated buzzer voltage", (5, V_BZ_MIN + 0.03), color=GREY, fontsize=8)
    ax.axhline(V_DW01_CUT, color=RED, ls="--", lw=0.9)
    ax.annotate("DW01A cut-off: the alarm stops", (5, V_DW01_CUT + 0.03), color=RED, fontsize=8)
    ax.set_xlabel("hours of alarm (buzzer at its estimated 10 mA)")
    ax.set_ylabel("cell voltage (V)")
    ax.set_ylim(2.4, 4.3)
    ax.set_xlim(0, 370)
    ax.legend(fontsize=8, loc="upper right")
    save(fig, "discharge.png")


def fig_autonomy():
    i = np.logspace(np.log10(1e-3), np.log10(0.3), 200)
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    banner(fig, "FIG T13 // HOW LONG THE ALARM LASTS")
    for cap, col in [(2000, CYAN), (2500, YELLOW), (3500, GREEN)]:
        ax.loglog(i * 1000, 0.95 * cap / 1000 / i, color=col, label=f"{cap} mAh (95 % usable)")
    ax.axvspan(5, 10, color=YELLOW, alpha=0.15)
    ax.annotate("SFM-27 at 3.7 V\n(estimate 5-10 mA)", (5.4, 2.0), color=YELLOW, fontsize=8)
    ib = 12 * 0.02 / (3.7 * 0.85) * 1000
    ax.axvline(ib, color=CYAN, lw=0.9, ls=":")
    ax.annotate("boost to 12 V,\n20 mA buzzer", (ib * 1.08, 400), color=CYAN, fontsize=8)
    for h, lab in [(24, "1 day"), (24 * 7, "1 week")]:
        ax.axhline(h, color=GREY, lw=0.8, ls="--")
        ax.annotate(lab, (1.05, h * 1.1), color=GREY, fontsize=8)
    ax.set_xlabel("alarm current drawn from the cell (mA)")
    ax.set_ylabel("run time (h)")
    ax.set_ylim(1, 5000)
    ax.legend(fontsize=8, loc="upper right")
    save(fig, "autonomy.png")


def fig_standby():
    p_coil = V_USB ** 2 / R_COIL
    i_led = (V_USB - V_LED) / R1
    p_r1, p_led = i_led ** 2 * R1, i_led * V_LED
    p_top = 0.02 * 2.5 * 3.7 / (30 * 24)     # self-discharge 2 %/month of a 2500 mAh cell, topped up (W)
    p_load = p_coil + p_r1 + p_led + p_top
    p_loss = p_load / 0.75 - p_load
    items = [("relay coil", p_coil, YELLOW), ("R1", p_r1, GREY), ("LED", p_led, GREEN),
             ("cell top-up", p_top, CYAN), ("charger losses (75 % assumed)", p_loss, RED)]
    fig, ax = plt.subplots(figsize=(7.2, 3.7))
    banner(fig, "FIG T14 // WHAT STANDBY COSTS")
    y = np.arange(len(items))[::-1]
    for yy, (lab, p, col) in zip(y, items):
        ax.barh(yy, p * 1000, color=col, height=0.6)
        ax.annotate(f"{p * 1000:.1f} mW", (p * 1000 + 6, yy - 0.12), fontsize=8, color=WHITE)
    ax.set_yticks(y)
    ax.set_yticklabels([it[0] for it in items], fontsize=8.5)
    ax.set_xlabel("power (mW)")
    ax.set_xlim(0, 480)
    total = p_load + p_loss
    ax.annotate(f"from the wall ≈ {total * 1000:.0f} mW ≈ {total * 8.766:.1f} kWh per year", (80, 1.4),
                color=YELLOW, fontsize=9)
    ax.grid(axis="y", visible=False)
    fig.tight_layout(rect=(0, 0, 1, 0.94))
    save(fig, "standby_power.png")
    print(f"T14 standby: coil {p_coil * 1000:.0f} mW, LED branch {(p_r1 + p_led) * 1000:.1f} mW, "
          f"top-up {p_top * 1000:.2f} mW, losses {p_loss * 1000:.0f} mW, wall {total * 1000:.0f} mW, "
          f"{total * 8.766:.2f} kWh/year")


def fig_led():
    v = np.linspace(0, 3.0, 30001)
    n_vt, i_s = 2 * 0.02585, 1e-19
    i_led = i_s * (np.exp(v / n_vt) - 1)
    # scale so that the LED gives 2.1 V at 2.9 mA (typical green, illustrative)
    i_led *= 2.9e-3 / (i_s * (math.exp(2.1 / n_vt) - 1))
    fig, ax = plt.subplots(figsize=(7.2, 3.9))
    banner(fig, "FIG T15 // THE POWER LED AND ITS RESISTOR")
    ax.plot(v, i_led * 1000, color=GREEN, lw=2.2, label="green LED (diode law, illustrative)")
    for r, col in [(1000, YELLOW), (470, CYAN)]:
        ax.plot(v, (V_USB - v) / r * 1000, color=col, label=f"load line, R1 = {r} Ω")
        k = np.argmin(np.abs(i_led - (V_USB - v) / r))
        ax.plot([v[k]], [i_led[k] * 1000], "o", color=col, ms=6)
        ax.annotate(f"{i_led[k] * 1000:.1f} mA at {v[k]:.2f} V", (v[k] - 1.05, i_led[k] * 1000 - 1.1),
                    color=col, fontsize=8)
    ax.set_xlabel("LED voltage (V)")
    ax.set_ylabel("current (mA)")
    ax.set_ylim(0, 11)
    ax.set_xlim(0, 3.0)
    ax.legend(fontsize=8, loc="upper left")
    save(fig, "led_load_line.png")


def fig_box_temperature():
    # outer surface of the wedge (base underside excluded: it stands on a shelf)
    top = BOX_X * BOX_Y / math.cos(math.radians(20))
    front, back = BOX_X * BOX_HF, BOX_X * BOX_HB
    sides = 2 * BOX_Y * (BOX_HF + BOX_HB) / 2
    area = top + front + back + sides
    h = 9.0                                   # convection + radiation (W/m2K), illustrative
    G = h * area
    C = 70 * 1.8 + 46 * 1.0 + 20 * 0.9        # shell+base PLA 70 g, cell 46 g, board and parts 20 g (J/K)
    p_standby = V_USB ** 2 / R_COIL + (V_USB - V_LED) / R1 * V_USB
    fig, ax = plt.subplots(figsize=(7.2, 4.0))
    banner(fig, "FIG T16 // INSIDE THE BOX WHILE IT RECHARGES")
    print(f"T16 box: area {area * 1e4:.0f} cm2, G = {G:.2f} W/K, C = {C:.0f} J/K, tau = {C / G / 60:.0f} min, "
          f"standby rise {p_standby / G:.1f} K")
    for i_set, col in [(1.0, YELLOW), (0.5, CYAN)]:
        t, i, v, s = charge(2500, i_set)
        p_chg = (V_USB - v) * i + i ** 2 * 0.05
        tt = np.arange(0, 7 * 3600, 5.0)
        p = p_standby + np.interp(tt, t, p_chg, right=0.0)
        dT = np.empty_like(tt)
        x = p_standby / G
        for k in range(len(tt)):
            dT[k] = x
            x += (p[k] - G * x) / C * 5.0
        ax.plot(tt / 3600, dT, color=col, label=f"{i_set:.1f} A charge, peak +{dT.max():.1f} K")
        print(f"  {i_set:.1f} A: peak rise {dT.max():.1f} K")
    ax.axhline(p_standby / G, color=GREY, ls="--", lw=0.9)
    ax.annotate("standby: relay coil and LED only", (4.4, p_standby / G - 0.45), color=GREY, fontsize=8)
    ax.set_xlabel("time after the power returns (h)")
    ax.set_ylabel("mean rise of the enclosure over the room (K)")
    ax.set_ylim(0, 8)
    ax.legend(fontsize=8)
    ax.set_title("lumped model: one temperature for the whole box (the TP4056 itself runs much hotter)",
                 fontsize=8.5, color=GREY, fontweight="normal")
    save(fig, "box_temperature.png")


def numbers():
    i_coil = P_COIL / V_USB
    i_led = (V_USB - V_LED) / R1
    print("Kit numbers:")
    print(f"  coil current {i_coil * 1000:.0f} mA (from 0.36 W) / {V_USB / R_COIL * 1000:.0f} mA (from 70 ohm)")
    print(f"  LED current {i_led * 1000:.1f} mA (1 kOhm), {(V_USB - V_LED) / 470 * 1000:.1f} mA (470 ohm)")
    print(f"  charge current 1200 V / R_PROG: {1200 / R_PROG:.2f} A (1.2 kOhm), {1200 / 2400:.2f} A (2.4 kOhm)")
    print(f"  peak USB load {(I_CHG + i_coil + i_led):.3f} A")
    for cap in CAP_MAH:
        print(f"  {cap} mAh: {cap * 3.7 / 1000:.1f} Wh, {cap / 10:.0f} h at 10 mA, {cap / 5:.0f} h at 5 mA, "
              f"recharge >= {cap / 1000:.1f} h at 1 A")
    # speaker grille open area (enclosure.scad: centre hole 3.4 mm, rings r = 5, 8.5, 12 mm, slots 1.8 mm, bridges 1.6 mm)
    w, bridge = 1.8, 1.6
    a = math.pi * 3.4 ** 2 / 4
    for r in (5, 8.5, 12):
        gap = (bridge + w) / r
        a += 4 * (r * (math.pi / 2 - gap) * w + math.pi * w ** 2 / 4)
    print(f"  grille open area {a:.0f} mm2 = {a / (math.pi * 15 ** 2) * 100:.0f} % of the 30 mm buzzer face")


def main():
    style()
    numbers()
    fig_proof_test()
    fig_outage_timeline()
    fig_holdup()
    fig_relay_forces()
    fig_flyback()
    fig_ocv()
    fig_charge()
    fig_dissipation()
    fig_a_weight()
    fig_spl_distance()
    fig_drive_boost()
    fig_discharge()
    fig_autonomy()
    fig_standby()
    fig_led()
    fig_box_temperature()


if __name__ == "__main__":
    main()
