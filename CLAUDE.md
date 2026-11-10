# CLAUDE.md

Guia para o Claude Code trabalhar neste repositório.

## O projeto

OutageAlarm é um alarme sonoro de falta de energia elétrica. Um carregador USB na tomada mantém um relé energizado; quando a energia cai, o contato NF do relé fecha e um buzzer alimentado por bateria toca.

Repositório público: https://github.com/icefoxj/OutageAlarm (branch `main`).

## Fase atual: v1 (simples)

- Circuito sem microcontrolador e sem firmware: carregador USB 5 V → bobina de K1; BT1 9 V → SW1 → K1 COM → K1 NF → BZ1.
- Caixa impressa em 3D, modelada em OpenSCAD.
- Ainda não existe código de software. Quando existir (v2, ESP32), ele vai em `firmware/`.

## Princípios de projeto

Não quebre estes princípios sem discutir com o usuário antes:

1. **Falha segura:** falta de 5 V = alarme tocando. Toda mudança precisa preservar isso.
2. **Consumo zero da bateria em espera** na v1: com energia presente, o circuito da bateria fica aberto.
3. **Nenhuma ligação direta à rede 127/220 V.** A rede só entra pelo carregador USB certificado. Se uma versão futura precisar medir a rede diretamente, isso exige isolamento (optoacoplador ou transformador), fusível e uma revisão explícita. Aponte os riscos ao usuário.
4. **Componentes fáceis de achar no Brasil** (lojas de eletrônica, Mercado Livre, AliExpress).
5. **Simplicidade antes de recursos.** Recursos novos entram como v2 ou v3, não na v1.

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
- **Designadores:** K1, D1, R1, LED1, BZ1, SW1, BT1, J1. Use os mesmos no esquemático, nas BOMs e na tabela de ligações.
- **Contatos de relé:** NF (normalmente fechado) e NA (normalmente aberto), nunca NC/NO no texto.
- **Commits:** mensagens em português, no imperativo ("Adiciona…", "Corrige…").

## Mantenha tudo em sincronia

Ao mudar um componente, um valor ou uma ligação, atualize todos estes:

- `hardware/eletronica/esquematico.svg`
- BOM e tabela de ligações em `docs/eletronica.md`
- BOM em `README.md`
- se mudar alguma dimensão: parâmetros em `hardware/mecanica/caixa.scad` e a tabela de `docs/mecanica.md`

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
- Sem OpenSCAD local: dê push e baixe o artefato do CI com `gh run download --name caixa-render --dir <pasta>`. Depois copie `stl/*.stl` para `hardware/mecanica/stl/` e `img/*.png` para `docs/img/`.
- Depois de mudar o `.scad`, commite os STLs e PNGs regenerados.
- Folgas críticas que precisam ser conferidas a cada mudança de layout:
  - fundo do buzzer (z = int_z − buzzer_h = 21) acima do topo da bateria (17,5)
  - corpo da chave (z até ≈ 30,6) abaixo da aba da tampa (começa em int_z − aba_h = 32)
  - anel do buzzer afastado da aba da tampa (anel começa em x ≈ 3,2; a aba vai até x = 1,85)
  - guias do USB-C sem invadir a placa perfurada (x ≤ 47,35 contra a placa em x = 48)
  - relé na metade de trás da placa, porque o corpo da chave invade os ~18 mm da frente

## Esquemático

- SVG desenhado à mão, numa grade de 10 px. Fios usam a classe `w`, símbolos preenchidos usam `wf`.
- Para conferir o desenho: `msedge --headless=new --screenshot=out.png --window-size=1000,570 file:///<caminho>/esquematico.svg`.
- Quando o circuito crescer (v2), migre para KiCad em `hardware/eletronica/kicad/`.
