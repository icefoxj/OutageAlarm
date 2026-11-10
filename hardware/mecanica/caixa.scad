// =============================================================================
//  OutageAlarm v1 — Caixa imprimível em 3D (base + tampa de encaixe)
//  Unidades: milímetros
//
//  Exportar STL pela linha de comando:
//    openscad -o stl/caixa_base.stl  -D "parte=\"base\""  caixa.scad
//    openscad -o stl/caixa_tampa.stl -D "parte=\"tampa\"" caixa.scad
//
//  Sistema de coordenadas:
//    origem = canto interno frontal-esquerdo, na face superior do fundo
//    X -> direita | Y -> traseira | Z -> cima
//    (posições de componentes abaixo são medidas a partir dessa origem)
//
//  Visão de cima (tampa removida):
//
//      traseira (USB-C)
//    +--------------------------------------------+
//    | [clip 9V]   [USB-C]  +------------------+  |
//    | +--------+           |  placa 4x6 cm    |  |
//    | |        |           |   (relé atrás)   |  |
//    | | bat 9V |           |                  |  |
//    | |        |           |                  |  |
//    | +--------+           +------------------+  |
//    +--------------------------------------------+
//      frente (chave ARMAR)
//
//  O buzzer e o LED ficam presos na tampa (buzzer sobre a bateria,
//  LED sobre a placa).
// =============================================================================

/* [Parte a renderizar] */
parte = "montagem"; // [montagem, explodida, base, tampa]

/* [Caixa] */
int_x = 90;        // largura interna
int_y = 66;        // profundidade interna
int_z = 36;        // altura interna (do fundo até a borda)
parede = 2.4;      // espessura das paredes (6 linhas de 0,4 mm)
fundo = 2.0;       // espessura do fundo
raio_canto = 3;    // raio externo dos cantos

/* [Tampa] */
tampa_esp = 2.4;   // espessura da placa da tampa
aba_h = 4;         // altura da aba de encaixe
aba_esp = 1.6;     // espessura da aba de encaixe
folga = 0.25;      // folga do encaixe (aumente se a tampa ficar justa demais)

/* [Bateria 9 V (6LR61)] */
bat_x = 26.5;      // largura
bat_y = 48.5;      // comprimento (sem o clip)
bat_z = 17.5;      // espessura
bat_folga = 0.8;
trava_bat_h = 10;  // altura da nervura que segura a bateria
trava_bat_esp = 2;

/* [Placa perfurada 4x6 cm] */
pcb_x = 40;
pcb_y = 60;
pcb_x0 = 48;            // canto frontal-esquerdo da placa (X)
pcb_y0 = 3;             // canto frontal-esquerdo da placa (Y)
pcb_furo_margem = 2.0;  // distância do centro do furo de fixação à borda da placa (meça a sua!)
espacador_h = 5;
espacador_d = 6;
espacador_furo = 1.8;   // furo-piloto para parafuso M2 autoatarraxante

/* [Entrada USB-C (breakout 6 pinos)] */
usb_x = 38;                  // centro do conector em X (parede traseira)
usb_z = 9;                   // altura do centro do conector acima do fundo
usb_abertura = [12.6, 7.2];  // grande o bastante para a capa do plugue encostar no conector
usb_pcb = [15, 21];          // plaquinha: largura (X) x comprimento (Y)
usb_pcb_esp = 1.6;
usb_conector_h = 3.2;        // altura do receptáculo USB-C

/* [Chave liga/desliga (MTS-101)] */
chave_x = 68;      // centro em X (parede frontal)
chave_z = 24;      // altura do centro acima do fundo
chave_d = 6.4;     // furo da rosca M6

/* [LED 5 mm] */
led_x = 68;
led_y = 50;
led_d = 5.2;

/* [Buzzer SFM-27] */
buzzer_x = 18.5;
buzzer_y = 26;
buzzer_d = 30;     // diâmetro do corpo (confira o seu: 29–30 mm)
buzzer_h = 15;
anel_h = 4;        // altura do anel centralizador
anel_esp = 1.6;

/* [Textos gravados] */
texto = "OutageAlarm";
texto_tam = 6;
gravacao = 0.6;    // profundidade da gravação
fonte = "Liberation Sans:style=Bold";

/* [Hidden] */
$fn = 64;
eps = 0.01;
ext_x = int_x + 2 * parede;
ext_y = int_y + 2 * parede;
base_h = fundo + int_z;
raio_int = max(raio_canto - parede, 0.5);
usb_apoio_h = usb_z - usb_conector_h / 2 - usb_pcb_esp;  // altura onde a plaquinha USB apoia

// -----------------------------------------------------------------------------
//  Utilitários
// -----------------------------------------------------------------------------

// Bloco com cantos arredondados no plano XY, origem no canto (0,0,0)
module bloco_arredondado(x, y, z, r) {
    hull()
        for (i = [r, x - r], j = [r, y - r])
            translate([i, j, 0]) cylinder(r = r, h = z);
}

// Retângulo 2D centrado com cantos arredondados
module retangulo_centro(x, y, r) {
    offset(r = r) square([x - 2 * r, y - 2 * r], center = true);
}

function furos_pcb() = [
    for (i = [pcb_furo_margem, pcb_x - pcb_furo_margem])
        for (j = [pcb_furo_margem, pcb_y - pcb_furo_margem])
            [pcb_x0 + i, pcb_y0 + j]
];

// Texto gravado numa parede vertical. lado = "frente" (normal -Y) ou "tras" (normal +Y)
module texto_parede(t, tam, x, z, lado) {
    if (lado == "frente")
        translate([x, -parede + gravacao, z]) rotate([90, 0, 0])
            linear_extrude(gravacao + 1)
                text(t, size = tam, font = fonte, halign = "center", valign = "center");
    else
        translate([x, int_y + parede - gravacao, z]) rotate([90, 0, 180])
            linear_extrude(gravacao + 1)
                text(t, size = tam, font = fonte, halign = "center", valign = "center");
}

// -----------------------------------------------------------------------------
//  Base
// -----------------------------------------------------------------------------

module base() {
    difference() {
        union() {
            difference() {
                translate([-parede, -parede, 0])
                    bloco_arredondado(ext_x, ext_y, base_h, raio_canto);
                translate([0, 0, fundo])
                    bloco_arredondado(int_x, int_y, int_z + 1, raio_int);
            }
            translate([0, 0, fundo - eps]) internos_base();
        }
        furos_base();
    }
}

module internos_base() {
    // Nervura que segura a bateria contra a parede esquerda
    translate([bat_x + bat_folga, 0, 0])
        cube([trava_bat_esp, bat_y * 0.8, trava_bat_h]);

    // Espaçadores da placa perfurada
    for (p = furos_pcb())
        translate([p[0], p[1], 0]) cylinder(d = espacador_d, h = espacador_h);

    // Berço da plaquinha USB-C: duas guias em "L" encostadas na parede traseira.
    // A plaquinha apoia nos degraus pelas bordas; o meio fica livre para pinos/solda.
    y0 = int_y - usb_pcb[1];
    for (s = [-1, 1]) {
        xg = (s < 0) ? usb_x - usb_pcb[0] / 2 - folga - 1.6
                     : usb_x + usb_pcb[0] / 2 + folga;
        translate([xg, y0, 0])
            cube([1.6, usb_pcb[1], usb_apoio_h + usb_pcb_esp + 1.5]);
        xa = (s < 0) ? usb_x - usb_pcb[0] / 2 - folga
                     : usb_x + usb_pcb[0] / 2 + folga - 1.5;
        translate([xa, y0, 0])
            cube([1.5, usb_pcb[1], usb_apoio_h]);
    }
}

module furos_base() {
    // Furos-piloto dos espaçadores (deixam 1 mm de fundo)
    for (p = furos_pcb())
        translate([p[0], p[1], fundo - 1])
            cylinder(d = espacador_furo, h = espacador_h + 2);

    // Abertura USB-C na parede traseira
    translate([usb_x, int_y - 1, fundo + usb_z]) rotate([-90, 0, 0])
        linear_extrude(parede + 2) retangulo_centro(usb_abertura[0], usb_abertura[1], 2);

    // Furo da chave na parede frontal
    translate([chave_x, -parede - 1, fundo + chave_z]) rotate([-90, 0, 0])
        cylinder(d = chave_d, h = parede + 2);

    // Entalhe na borda esquerda para abrir a tampa com a unha
    translate([-parede - 1, int_y / 2 - 8, base_h - 1.5])
        cube([parede + 2, 16, 2]);

    // Textos nas paredes
    texto_parede("ARMAR", 4, chave_x, fundo + chave_z - 9, "frente");
    texto_parede("5V", 4, usb_x, fundo + usb_z + 8, "tras");
}

// -----------------------------------------------------------------------------
//  Tampa — desenhada na posição de uso: z = 0 é a face de baixo da placa,
//  que apoia na borda das paredes.
// -----------------------------------------------------------------------------

module tampa() {
    difference() {
        union() {
            // Placa
            translate([-parede, -parede, 0])
                bloco_arredondado(ext_x, ext_y, tampa_esp, raio_canto);

            // Aba de encaixe (entra na base)
            translate([folga, folga, -aba_h])
                difference() {
                    bloco_arredondado(int_x - 2 * folga, int_y - 2 * folga, aba_h + eps,
                                      max(raio_int - folga, 0.3));
                    translate([aba_esp, aba_esp, -1])
                        bloco_arredondado(int_x - 2 * folga - 2 * aba_esp,
                                          int_y - 2 * folga - 2 * aba_esp, aba_h + 2, 0.3);
                }

            // Anel centralizador do buzzer: 4 segmentos, vãos em 0/90/180/270°
            // deixam passar as orelhas de fixação do SFM-27 (alinhe-as com Y).
            translate([buzzer_x, buzzer_y, -anel_h])
                for (a = [45, 135, 225, 315])
                    rotate([0, 0, a - 20])
                        rotate_extrude(angle = 40)
                            translate([buzzer_d / 2 + 0.3, 0])
                                square([anel_esp, anel_h + eps]);
        }

        // Furos de som sobre o buzzer
        translate([buzzer_x, buzzer_y, -1]) {
            cylinder(d = 3, h = tampa_esp + 2);
            for (a = [0 : 60 : 359])
                rotate([0, 0, a]) translate([5, 0, 0]) cylinder(d = 2.2, h = tampa_esp + 2);
            for (a = [15 : 30 : 359])
                rotate([0, 0, a]) translate([9, 0, 0]) cylinder(d = 2.2, h = tampa_esp + 2);
        }

        // Furo do LED (o LED entra por baixo; a aba do LED trava na tampa)
        translate([led_x, led_y, -1]) cylinder(d = led_d, h = tampa_esp + 2);

        // Textos gravados no topo
        translate([led_x, led_y - 8, tampa_esp - gravacao])
            linear_extrude(gravacao + 1)
                text("REDE", size = 4, font = fonte, halign = "center", valign = "center");
        translate([pcb_x0 + pcb_x / 2, 22, tampa_esp - gravacao])
            linear_extrude(gravacao + 1)
                text(texto, size = texto_tam, font = fonte, halign = "center", valign = "center");
    }
}

// -----------------------------------------------------------------------------
//  Componentes (só para visualização; não são impressos)
// -----------------------------------------------------------------------------

module componentes_base() {
    translate([0, 0, fundo]) {
        // Bateria 9 V + clip
        color("SteelBlue") translate([0.4, 0.5, 0]) cube([bat_x, bat_y, bat_z]);
        color("Black") translate([3.5, bat_y + 0.5, 3]) cube([bat_x - 6, 9, bat_z - 6]);
        // Placa perfurada
        color("DarkGreen") translate([pcb_x0, pcb_y0, espacador_h]) cube([pcb_x, pcb_y, 1.6]);
        // Relé SRD-05VDC (19 x 15,5 x 15,3), na metade de trás da placa
        color("RoyalBlue") translate([pcb_x0 + 10, pcb_y0 + 38, espacador_h + 1.6])
            cube([19, 15.5, 15.3]);
        // Diodo e resistor
        color("Black") translate([pcb_x0 + 8, pcb_y0 + 28, espacador_h + 1.6 + 1.3])
            rotate([0, 90, 0]) cylinder(d = 2.7, h = 5.2);
        color("Tan") translate([pcb_x0 + 22, pcb_y0 + 28, espacador_h + 1.6 + 1.2])
            rotate([0, 90, 0]) cylinder(d = 2.4, h = 6.3);
        // Plaquinha USB-C + receptáculo
        color("Purple") translate([usb_x - usb_pcb[0] / 2, int_y - usb_pcb[1], usb_apoio_h])
            cube([usb_pcb[0], usb_pcb[1], usb_pcb_esp]);
        color("Silver") translate([usb_x - 4.5, int_y - 7.5, usb_apoio_h + usb_pcb_esp])
            cube([9, 7.5, usb_conector_h]);
        // Chave MTS-101 (corpo interno + alavanca externa)
        color("Silver") translate([chave_x - 3.9, 0, chave_z - 6.6]) cube([7.8, 9.5, 13.2]);
        color("Silver") translate([chave_x, 0, chave_z]) rotate([90, 0, 0])
            cylinder(d = 6, h = parede + 8);
        color("Silver") translate([chave_x, -parede - 8, chave_z]) rotate([90, 0, 0])
            rotate([0, 20, 0]) cylinder(d1 = 3, d2 = 2.2, h = 10);
    }
}

module componentes_tampa() {
    // Buzzer pendurado sob a tampa
    color([0.15, 0.15, 0.15]) translate([buzzer_x, buzzer_y, -buzzer_h])
        cylinder(d = buzzer_d, h = buzzer_h);
    // LED (aba sob a tampa, cúpula para fora)
    color("Lime") translate([led_x, led_y, 0]) {
        translate([0, 0, -1]) cylinder(d = 5.8, h = 1);
        cylinder(d = 5, h = tampa_esp + 2.5);
        translate([0, 0, tampa_esp + 2.5]) sphere(d = 5);
    }
}

// -----------------------------------------------------------------------------
//  Seleção da parte
// -----------------------------------------------------------------------------

if (parte == "base") {
    base();
} else if (parte == "tampa") {
    // Virada de cabeça para baixo: topo apoiado na mesa da impressora
    translate([0, 0, tampa_esp]) rotate([180, 0, 0]) tampa();
} else if (parte == "explodida") {
    color("Gainsboro") base();
    componentes_base();
    translate([0, 0, base_h + 40]) {
        color("WhiteSmoke") tampa();
        componentes_tampa();
    }
} else {  // montagem
    color("Gainsboro") base();
    componentes_base();
    translate([0, 0, base_h]) {
        color("WhiteSmoke") tampa();
        componentes_tampa();
    }
}
