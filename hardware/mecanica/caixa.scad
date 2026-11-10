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
//                       traseira
//    +--------------------------------------------------+
//    | [========= suporte 18650 =========]              |
//    |  ------------ nervura ------------               |
//    | +------------------------------+                 |
//    | |   placa perfurada 6x4 cm     |  +----------+   |
//    | |        (relé à direita)      |  |  TP4056  |===| USB-C
//    | +------------------------------+  +----------+   |
//    +--------------------------------------------------+
//                frente: chave ARMAR, botão TESTE
//
//  O buzzer fica preso na tampa sobre o suporte da bateria; o LED REDE
//  fica na tampa do lado direito.
// =============================================================================

/* [Parte a renderizar] */
parte = "montagem"; // [montagem, explodida, base, tampa]

/* [Caixa] */
int_x = 96;        // largura interna
int_y = 70;        // profundidade interna
int_z = 38;        // altura interna (do fundo até a borda)
parede = 2.4;      // espessura das paredes (6 linhas de 0,4 mm)
fundo = 2.0;       // espessura do fundo
raio_canto = 3;    // raio externo dos cantos

/* [Tampa] */
tampa_esp = 2.4;   // espessura da placa da tampa
aba_h = 4;         // altura da aba de encaixe
aba_esp = 1.6;     // espessura da aba de encaixe
folga = 0.25;      // folga do encaixe (aumente se a tampa ficar justa demais)

/* [Suporte de bateria 18650] */
sup_x = 78;        // comprimento do suporte
sup_y = 22;        // largura do suporte
sup_z = 21;        // altura do suporte com a pilha
sup_x0 = 2;        // posição X da ponta esquerda
sup_folga = 0.5;
nervura_h = 6;     // altura da nervura que segura o suporte contra a parede traseira
nervura_esp = 1.6;

/* [Placa perfurada 6x4 cm] */
pcb_x = 60;
pcb_y = 40;
pcb_x0 = 2;             // canto frontal-esquerdo da placa (X)
pcb_y0 = 3;             // canto frontal-esquerdo da placa (Y)
pcb_furo_margem = 2.0;  // distância do centro do furo de fixação à borda da placa (meça a sua!)
espacador_h = 5;
espacador_d = 6;
espacador_furo = 1.8;   // furo-piloto para parafuso M2 autoatarraxante

/* [Módulo carregador TP4056 USB-C] */
tp_y = 19;                   // centro do módulo em Y (parede direita)
tp_z = 8;                    // altura do centro do conector USB-C acima do fundo
tp_pcb = [29, 17.4];         // módulo: comprimento (X) x largura (Y)
tp_pcb_esp = 1.2;            // espessura da placa do módulo
tp_conector_h = 3.2;         // altura do receptáculo USB-C
usb_abertura = [12.6, 7.2];  // grande o bastante para a capa do plugue encostar no conector

/* [Chave ARMAR (MTS-101)] */
chave_x = 64;      // centro em X (parede frontal)
chave_z = 24;      // altura do centro acima do fundo
chave_d = 6.4;     // furo da rosca M6

/* [Botão TESTE (pulsador NF, PBS-11B)] */
botao_x = 84;      // centro em X (parede frontal)
botao_z = 24;      // altura do centro acima do fundo
botao_d = 12.2;    // furo da rosca de 12 mm

/* [LED 5 mm] */
led_x = 78;
led_y = 52;
led_d = 5.2;

/* [Buzzer SFM-27] */
buzzer_x = 25;
buzzer_y = 50;
buzzer_d = 30;     // diâmetro do corpo (confira o seu: 29–30 mm)
buzzer_h = 15;
anel_h = 4;        // altura do anel centralizador
anel_esp = 1.6;

/* [Textos gravados] */
texto = "OutageAlarm";
texto_tam = 5;
texto_x = 69;      // centro do texto da tampa (entre o buzzer e a borda direita)
texto_y = 22;
gravacao = 0.6;    // profundidade da gravação
fonte = "Liberation Sans:style=Bold";

/* [Hidden] */
$fn = 64;
eps = 0.01;
ext_x = int_x + 2 * parede;
ext_y = int_y + 2 * parede;
base_h = fundo + int_z;
raio_int = max(raio_canto - parede, 0.5);
tp_apoio_h = tp_z - tp_conector_h / 2 - tp_pcb_esp;   // altura onde o módulo TP4056 apoia
sup_y0 = int_y - sup_y - sup_folga;                   // face frontal do suporte 18650

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

// Texto gravado numa parede vertical.
//   lado = "frente" (normal -Y) | "direita" (normal +X)
//   pos  = coordenada ao longo da parede (X na frente, Y na direita)
module texto_parede(t, tam, pos, z, lado) {
    if (lado == "frente")
        translate([pos, -parede + gravacao, z]) rotate([90, 0, 0])
            linear_extrude(gravacao + 1)
                text(t, size = tam, font = fonte, halign = "center", valign = "center");
    else
        translate([int_x + parede - gravacao, pos, z]) rotate([90, 0, 90])
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
    // Nervura que segura o suporte 18650 contra a parede traseira
    translate([sup_x0 + 6, sup_y0 - nervura_esp, 0])
        cube([sup_x - 12, nervura_esp, nervura_h]);

    // Espaçadores da placa perfurada
    for (p = furos_pcb())
        translate([p[0], p[1], 0]) cylinder(d = espacador_d, h = espacador_h);

    // Berço do módulo TP4056: duas guias em "L" encostadas na parede direita.
    // O módulo apoia nos degraus pelas bordas; o meio fica livre para a solda.
    x0 = int_x - tp_pcb[0];
    for (s = [-1, 1]) {
        yg = (s < 0) ? tp_y - tp_pcb[1] / 2 - folga - 1.6
                     : tp_y + tp_pcb[1] / 2 + folga;
        translate([x0, yg, 0])
            cube([tp_pcb[0], 1.6, tp_apoio_h + tp_pcb_esp + 1.5]);
        ya = (s < 0) ? tp_y - tp_pcb[1] / 2 - folga
                     : tp_y + tp_pcb[1] / 2 + folga - 1.5;
        translate([x0, ya, 0])
            cube([tp_pcb[0], 1.5, tp_apoio_h]);
    }
}

module furos_base() {
    // Furos-piloto dos espaçadores (deixam 1 mm de fundo)
    for (p = furos_pcb())
        translate([p[0], p[1], fundo - 1])
            cylinder(d = espacador_furo, h = espacador_h + 2);

    // Abertura USB-C na parede direita
    translate([int_x - 1, tp_y, fundo + tp_z]) rotate([0, 90, 0]) rotate([0, 0, 90])
        linear_extrude(parede + 2) retangulo_centro(usb_abertura[0], usb_abertura[1], 2);

    // Furos da chave ARMAR e do botão TESTE na parede frontal
    translate([chave_x, -parede - 1, fundo + chave_z]) rotate([-90, 0, 0])
        cylinder(d = chave_d, h = parede + 2);
    translate([botao_x, -parede - 1, fundo + botao_z]) rotate([-90, 0, 0])
        cylinder(d = botao_d, h = parede + 2);

    // Entalhe na borda esquerda para abrir a tampa com a unha
    translate([-parede - 1, int_y / 2 - 8, base_h - 1.5])
        cube([parede + 2, 16, 2]);

    // Textos nas paredes
    texto_parede("ARMAR", 3.5, chave_x, fundo + chave_z - 9, "frente");
    texto_parede("TESTE", 3.5, botao_x, fundo + botao_z - 13, "frente");
    texto_parede("5V", 4, tp_y, fundo + tp_z + 8, "direita");
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
            // deixam passar as orelhas de fixação do SFM-27 (alinhe-as com X).
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
        translate([texto_x, texto_y, tampa_esp - gravacao])
            linear_extrude(gravacao + 1)
                text(texto, size = texto_tam, font = fonte, halign = "center", valign = "center");
    }
}

// -----------------------------------------------------------------------------
//  Componentes (só para visualização; não são impressos)
// -----------------------------------------------------------------------------

module componentes_base() {
    translate([0, 0, fundo]) {
        // Suporte 18650 + pilha
        color([0.12, 0.12, 0.12]) translate([sup_x0, sup_y0, 0]) difference() {
            cube([sup_x, sup_y, sup_z - 4]);
            translate([2, 1.5, 2]) cube([sup_x - 4, sup_y - 3, sup_z]);
        }
        color("Teal") translate([sup_x0 + 5.5, sup_y0 + sup_y / 2, 2 + 9.2])
            rotate([0, 90, 0]) cylinder(d = 18.4, h = 65);
        // Placa perfurada
        color("DarkGreen") translate([pcb_x0, pcb_y0, espacador_h]) cube([pcb_x, pcb_y, 1.6]);
        // Relé SRD-05VDC (19 x 15,5 x 15,3), na metade direita da placa
        color("RoyalBlue") translate([pcb_x0 + 38, pcb_y0 + 12, espacador_h + 1.6])
            cube([19, 15.5, 15.3]);
        // Diodo e resistor
        color("Black") translate([pcb_x0 + 10, pcb_y0 + 10, espacador_h + 1.6 + 1.3])
            rotate([0, 90, 0]) cylinder(d = 2.7, h = 5.2);
        color("Tan") translate([pcb_x0 + 22, pcb_y0 + 10, espacador_h + 1.6 + 1.2])
            rotate([0, 90, 0]) cylinder(d = 2.4, h = 6.3);
        // Módulo TP4056 + receptáculo USB-C
        color("MediumBlue") translate([int_x - tp_pcb[0], tp_y - tp_pcb[1] / 2, tp_apoio_h])
            cube([tp_pcb[0], tp_pcb[1], tp_pcb_esp]);
        color("Silver") translate([int_x - 7.5, tp_y - 4.5, tp_apoio_h + tp_pcb_esp])
            cube([7.5, 9, tp_conector_h]);
        // Chave MTS-101 (corpo interno + alavanca externa)
        color("Silver") translate([chave_x - 3.9, 0, chave_z - 6.6]) cube([7.8, 9.5, 13.2]);
        color("Silver") translate([chave_x, 0, chave_z]) rotate([90, 0, 0])
            cylinder(d = 6, h = parede + 8);
        color("Silver") translate([chave_x, -parede - 8, chave_z]) rotate([90, 0, 0])
            rotate([0, 20, 0]) cylinder(d1 = 3, d2 = 2.2, h = 10);
        // Botão TESTE (corpo interno + aro e capa vermelha externos)
        color("DimGray") translate([botao_x, 0, botao_z]) rotate([-90, 0, 0])
            cylinder(d = 12, h = 16);
        color("DimGray") translate([botao_x, -parede, botao_z]) rotate([90, 0, 0])
            cylinder(d = 18.4, h = 3);
        color("Red") translate([botao_x, -parede - 3, botao_z]) rotate([90, 0, 0])
            cylinder(d = 9, h = 4);
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
    translate([0, int_y, tampa_esp]) rotate([180, 0, 0]) tampa();
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
