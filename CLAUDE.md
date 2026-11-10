# CLAUDE.md

Guia para o Claude Code trabalhar neste repositório.

## O projeto

OutageAlarm é um alarme sonoro de falta de energia elétrica. Um carregador USB na tomada alimenta um módulo TP4056, que mantém uma bateria 18650 carregada, e energiza um relé. Quando a energia cai, o contato NF do relé fecha e o buzzer toca, alimentado pela bateria. Um botão TESTE simula a queda.

Repositório público: https://github.com/icefoxj/OutageAlarm (branch `main`).

## Fase atual: v1 (simples)

- Circuito sem microcontrolador e sem firmware:
  - detecção: U1 IN+ → SW2 (TESTE, pulsador NF) → bobina de K1 → U1 IN−; LED1 + R1 ligados direto nos 5 V, antes do SW2;
  - alarme: U1 OUT+ → SW1 (ARMAR) → K1 COM → K1 NF → BZ1 → U1 OUT−;
  - bateria: BT1 18650 em U1 B+/B−.
- Caixa impressa em 3D, modelada em OpenSCAD.
- Ainda não existe código de software. Quando existir (v2, ESP32), ele vai em `firmware/`.

## Princípios de projeto

Não quebre estes princípios sem discutir com o usuário antes:

1. **Falha segura:** falta de 5 V = alarme tocando. Toda mudança precisa preservar isso.
2. **Bateria sempre pronta:** o USB mantém a bateria carregada. Em espera, nada além da proteção do U1 consome da bateria (µA).
3. **Teste de ponta a ponta:** o botão TESTE precisa simular a queda real (cortar a bobina), não só ligar o buzzer.
4. **Nenhuma ligação direta à rede 127/220 V.** A rede só entra pelo carregador USB certificado. Se uma versão futura precisar medir a rede diretamente, isso exige isolamento (optoacoplador ou transformador), fusível e uma revisão explícita. Aponte os riscos ao usuário.
5. **Bateria Li-ion só através da proteção.** Cargas ligam em OUT+/OUT− do U1, nunca em B+/B−.
6. **Componentes fáceis de achar no Brasil** (lojas de eletrônica, Mercado Livre, AliExpress).
7. **Simplicidade antes de recursos.** Recursos novos entram como v2 ou v3, não na v1.

## Estrutura

```
README.md                         visão geral, BOM, teste, roadmap
docs/eletronica.md                circuito detalhado, cálculos, tabela de ligações, diagnóstico
docs/mecanica.md                  caixa, parâmetros, impressão, montagem
docs/img/                         PNGs renderizados da caixa (gerados pelo CI)
hardware/eletronica/esquematico.svg   esquemático (SVG feito à mão)
hardware/mecanica/caixa.scad      caixa paramétrica: fonte da verdade da mecânica
hardware/mecanica/stl/            STLs gerados a partir do caixa.scad
.github/workflows/render-caixa.yml    CI que renderiza STLs e PNGs
```

## Convenções

- **Idioma:** documentação, comentários e nomes no código em português do Brasil.
- **Unidades:** mm, V, mA, Ω. No texto use vírgula decimal (5,1 kΩ); no código, ponto.
- **Designadores:** U1, BT1, K1, D1, R1, LED1, BZ1, SW1 (ARMAR), SW2 (TESTE). Use os mesmos no esquemático, nas BOMs e na tabela de ligações.
- **Contatos:** NF (normalmente fechado) e NA (normalmente aberto), nunca NC/NO no texto.
- **Commits:** mensagens em português, no imperativo ("Adiciona…", "Corrige…").

## Mantenha tudo em sincronia

Ao mudar um componente, um valor ou uma ligação, atualize todos estes:

- `hardware/eletronica/esquematico.svg`
- BOM e tabela de ligações em `docs/eletronica.md`
- BOM e tabela de funcionamento em `README.md`
- se mudar alguma dimensão: parâmetros em `hardware/mecanica/caixa.scad` e as tabelas de `docs/mecanica.md`

## Mecânica (OpenSCAD)

- `caixa.scad` é a fonte da verdade. Os STLs em `stl/` e os PNGs em `docs/img/` são gerados a partir dele e não devem ser editados à mão.
- A origem e os eixos estão descritos no cabeçalho do arquivo: origem no canto interno frontal-esquerdo, sobre o fundo.
- Parâmetros ficam em seções do Customizer (`/* [Seção] */`). Valores derivados ficam em `/* [Hidden] */`.
- A tampa é modelada na posição de uso (z = 0 é a face de baixo da placa) e só é virada para impressão no `parte == "tampa"`.
- Gerar STL localmente (se o OpenSCAD estiver instalado):
  ```
  cd hardware/mecanica
  openscad -o stl/caixa_base.stl  -D "parte=\"base\""  caixa.scad
  openscad -o stl/caixa_tampa.stl -D "parte=\"tampa\"" caixa.scad
  ```
- Sem OpenSCAD local (é o caso na máquina do usuário): dê push e baixe o artefato do CI com `gh run download <id> --name caixa-render --dir <pasta>`. Depois copie `stl/*.stl` para `hardware/mecanica/stl/` e `img/*.png` para `docs/img/`, e confira os PNGs antes de commitar.
- O CI roda com `--hardwarnings`: qualquer aviso do OpenSCAD falha o build.
- No preview (PNGs), gravações finas podem aparecer com artefatos. Na dúvida, confira o STL (bounding box, vértices) em vez da imagem.
- Folgas críticas que precisam ser conferidas a cada mudança de layout:
  - fundo do buzzer (z = int_z − buzzer_h = 23) acima do topo do suporte 18650 (sup_z = 21)
  - corpos da chave e do botão (z até ≈ 30,6) abaixo da aba da tampa (começa em int_z − aba_h = 34)
  - anel do buzzer afastado da aba da tampa (anel vai até y ≈ 66,9; a aba começa em y = 68,15)
  - guias do TP4056 (x ≥ 67) sem invadir a placa perfurada (x ≤ 62) e seus espaçadores (x ≤ 63)
  - relé na metade direita da placa (y ≤ 30,5), fora da área sob o buzzer (y ≥ 33)
  - nervura do suporte (y = 45,9) atrás dos espaçadores da placa (y ≤ 44)

## Esquemático

- SVG desenhado à mão, numa grade de 10 px. Classes: `u` = fios dos 5 V do USB (laranja), `b` = fios da bateria (azul), `w` = traços de símbolos, `wf` = símbolos preenchidos.
- Para conferir o desenho: `msedge --headless=new --user-data-dir=<pasta temporária> --screenshot=out.png --window-size=1100,730 file:///<caminho>/esquematico.svg` (o PNG pode levar alguns segundos para aparecer).
- Quando o circuito crescer (v2), migre para KiCad em `hardware/eletronica/kicad/`.
