# OutageAlarm

Alarme sonoro de **falta de energia elétrica**. Quando a energia da tomada cai, um buzzer alimentado por bateria dispara na hora.

> **Status:** v1, versão simples. Não tem microcontrolador nem firmware: são só um relé, uma bateria e um buzzer.

![Montagem da caixa](docs/img/montagem.png)

## Como funciona

![Esquemático](hardware/eletronica/esquematico.svg)

Um carregador USB comum, ligado na tomada, mantém energizada a bobina de um relé de 5 V. O buzzer é alimentado por uma bateria de 9 V **através do contato NF (normalmente fechado) do relé**:

| Situação         | Relé K1       | Contato NF | Buzzer       |
|------------------|---------------|------------|--------------|
| Energia presente | energizado    | aberto     | silêncio     |
| Falta de energia | desenergizado | fechado    | **toca**     |

Princípios do projeto:

- **Falha segura.** Qualquer falha do lado da rede dispara o alarme: queda de energia, disjuntor desarmado, carregador queimado ou cabo solto.
- **A bateria não gasta nada em espera.** Com energia presente, o circuito da bateria fica aberto. Ela só fornece corrente enquanto o alarme toca, então dura praticamente o prazo de validade (anos).
- **Sem 127/220 V na placa.** A tensão da rede fica dentro do carregador USB certificado. Você só manuseia 5 V e 9 V.

## Lista de materiais (v1)

| Qtd | Ref  | Componente                                         | Observação |
|----:|------|----------------------------------------------------|------------|
| 1   | K1   | Relé 5 V SPDT: SRD-05VDC-SL-C                      | bobina ≈ 70 Ω, consome ≈ 72 mA |
| 1   | D1   | Diodo 1N4007 (ou 1N4148)                           | diodo de roda-livre da bobina |
| 1   | R1   | Resistor 1 kΩ, 1/4 W                               | limita a corrente do LED |
| 1   | LED1 | LED verde 5 mm                                     | indica "REDE OK" |
| 1   | BZ1  | Buzzer ativo SFM-27, 3–24 V                        | ≈ 95 dB, < 20 mA |
| 1   | SW1  | Chave alavanca MTS-101 (liga/desliga)              | arma e desarma o alarme |
| 1   | BT1  | Bateria 9 V alcalina + clip                        |  |
| 1   | J1   | Plaquinha USB-C fêmea 6 pinos **com resistores de 5,1 kΩ no CC** | sem esses resistores, carregadores USB-C não liberam os 5 V |
| 1   | —    | Placa perfurada 4 × 6 cm                           |  |
| 4   | —    | Parafuso M2 × 6 mm autoatarraxante                 | fixa a placa na caixa |
| 1   | —    | Carregador USB 5 V (qualquer, ≥ 0,5 A) + cabo      | **ligue direto na tomada, nunca num nobreak** |
| —   | —    | Fios, solda, cola quente, fita dupla-face de espuma |  |

## Estrutura do repositório

```
OutageAlarm/
├── README.md
├── CLAUDE.md                       # contexto para o Claude Code
├── docs/
│   ├── eletronica.md               # circuito, cálculos, ligações, testes
│   ├── mecanica.md                 # caixa, impressão 3D, montagem
│   └── img/                        # imagens renderizadas da caixa
├── hardware/
│   ├── eletronica/
│   │   └── esquematico.svg
│   └── mecanica/
│       ├── caixa.scad              # caixa paramétrica (OpenSCAD), fonte da verdade
│       └── stl/                    # STLs prontos para fatiar
└── .github/workflows/
    └── render-caixa.yml            # gera STLs e imagens quando o .scad muda
```

## Montagem rápida

1. Imprima `hardware/mecanica/stl/caixa_base.stl` e `caixa_tampa.stl` em PLA ou PETG, sem suporte. Detalhes em [docs/mecanica.md](docs/mecanica.md).
2. Monte o circuito na placa perfurada seguindo a tabela de ligações em [docs/eletronica.md](docs/eletronica.md).
3. Coloque tudo na caixa: a placa vai nos espaçadores, o USB-C no berço traseiro e a chave na frente. O buzzer e o LED vão na tampa. A bateria fica presa com fita dupla-face.
4. Faça o teste abaixo e feche a tampa.

## Teste

1. Com a chave **ARMAR** desligada, ligue o carregador. O LED **REDE** acende e o relé dá um clique.
2. Ligue a chave **ARMAR**. Não deve haver som.
3. Tire o carregador da tomada. O buzzer deve tocar em menos de 1 segundo.
4. Recoloque o carregador. O buzzer para.

Repita o teste uma vez por mês. Troque a bateria uma vez por ano, ou antes se o som enfraquecer.

## Limitações da v1

- Avisa só no local, com som. Não envia notificação.
- Detecta a falta de energia apenas no circuito (disjuntor) da tomada onde o carregador está ligado.
- Toca até a energia voltar ou até a chave ARMAR ser desligada.
- Uma bateria 9 V alcalina mantém o buzzer tocando por cerca de 24 a 36 horas.
- Também dispara se o carregador ou o cabo falharem. Isso é intencional (falha segura).

## Próximas versões

- **v2:** ESP32 com bateria Li-ion recarregável (TP4056) e notificação por Wi-Fi (Telegram, push ou e-mail), com registro do horário em que a energia caiu e voltou. Botão para silenciar sem desarmar e bipe curto quando a energia volta.
- **v3:** PCB própria. Opcionalmente, detecção direta da rede com isolamento adequado.

## Segurança

- Use um carregador USB de marca e certificado (selo do Inmetro). Ele é a única parte ligada à rede elétrica.
- Não abra o carregador e não ligue nada deste projeto direto em 127/220 V.
- Se a casa tem nobreak, ligue o carregador numa tomada **fora** do nobreak. Senão o alarme não percebe a queda.

## Licença

[MIT](LICENSE)
