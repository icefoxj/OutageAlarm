# Eletrônica — OutageAlarm v1

![Esquemático](../hardware/eletronica/esquematico.svg)

## Princípio

O circuito tem dois lados que **não se tocam eletricamente**. Eles são ligados só pelo relé K1:

- **Lado 5 V:** o carregador USB alimenta a bobina de K1 e o LED REDE. Este lado só tem energia enquanto há energia na tomada.
- **Lado alarme:** a bateria de 9 V alimenta o buzzer passando pela chave ARMAR (SW1) e pelo contato **NF** de K1.

Com energia, a bobina puxa o contato e o NF abre: o buzzer fica mudo e a bateria não fornece corrente nenhuma. Quando a energia cai, a bobina solta, o NF fecha e o buzzer toca.

Esse arranjo é **falha segura**: qualquer interrupção do lado 5 V dispara o alarme, seja queda de energia, disjuntor, carregador queimado ou cabo solto.

## Lista de materiais

| Qtd | Ref  | Componente | Especificação | Observação |
|----:|------|------------|---------------|------------|
| 1 | K1   | Relé SRD-05VDC-SL-C | bobina 5 V / 0,36 W (≈ 70 Ω), contato SPDT 10 A | qualquer relé 5 V com contato NF serve |
| 1 | D1   | Diodo 1N4007 | 1 A, 1000 V | 1N4148 também serve |
| 1 | R1   | Resistor | 1 kΩ, 1/4 W | 470 Ω se quiser o LED mais forte |
| 1 | LED1 | LED verde | 5 mm | tem uma aba na base que trava na tampa |
| 1 | BZ1  | Buzzer ativo SFM-27 | 3–24 V, < 20 mA, ≈ 95 dB | **ativo** (oscilador interno) e **polarizado** |
| 1 | SW1  | Chave alavanca MTS-101 | SPST liga/desliga, furo M6 | |
| 1 | BT1  | Bateria 9 V alcalina (6LR61) + clip | ≈ 500 mAh | |
| 1 | J1   | Plaquinha USB-C fêmea 6 pinos | VBUS, GND, CC1, CC2 | precisa ter **5,1 kΩ do CC para o GND** |
| 1 | —    | Placa perfurada | 4 × 6 cm | |
| 1 | —    | Carregador USB 5 V | ≥ 0,5 A | certificado, ligado direto na tomada |

> **Por que o buzzer tem que ser de 3–24 V?** Os buzzers ativos pequenos de 12 mm costumam ser de 5 V e podem queimar com 9 V. O SFM-27 aceita de 3 a 24 V e é bem mais alto, ótimo para um alarme.

> **Por que os resistores de 5,1 kΩ no CC?** Um carregador USB-C só libera os 5 V depois que detecta um aparelho conectado, e ele faz isso por meio desses resistores. Muitas plaquinhas "Type-C 6P" já vêm com eles. Se a sua não tiver, solde um resistor de 5,1 kΩ do CC1 para o GND e outro do CC2 para o GND. Com cabo USB-A → USB-C os 5 V sempre chegam, mesmo sem os resistores.

## Cálculos

| Item | Conta | Resultado |
|------|-------|-----------|
| Corrente da bobina de K1 | 0,36 W ÷ 5 V | ≈ 72 mA |
| Corrente do LED (verde, Vf ≈ 2,1 V) | (5 − 2,1) V ÷ 1 kΩ | ≈ 2,9 mA |
| Consumo total do carregador | 72 + 3 mA | ≈ 75 mA (≈ 0,4 W) |
| Consumo da bateria em espera | circuito aberto | **0 mA** |
| Corrente do buzzer tocando em 9 V | datasheet do SFM-27 | 10–20 mA |
| Autonomia tocando | ≈ 500 mAh ÷ 15 mA | ≈ 24–36 h |

**Tempo de resposta.** Quando a energia cai, os capacitores do carregador seguram a saída por alguns milissegundos (às vezes um pouco mais) e alimentam a bobina enquanto descarregam. O relé solta quando a tensão fica abaixo de ≈ 1–2 V. Na prática o alarme dispara em menos de 1 segundo. O efeito colateral é bom: piscadas muito curtas da rede (menos de ~0,1 s) costumam ser ignoradas.

**Função do D1.** Ao desligar, a bobina gera um pico de tensão reversa. D1 absorve esse pico e protege a saída do carregador. Ele será obrigatório na v2, quando um transistor ou microcontrolador acionar a bobina. O diodo atrasa a soltura do relé em poucos milissegundos, o que é irrelevante aqui.

## Tabela de ligações

| Rede | Pontos ligados |
|------|----------------|
| `+5V`  | J1 VBUS · K1 bobina (um pino) · D1 catodo (lado da faixa) · R1 (um terminal) |
| `0V`   | J1 GND · K1 bobina (outro pino) · D1 anodo · LED1 catodo (perna curta, lado chanfrado) |
| `LED`  | R1 (outro terminal) · LED1 anodo (perna longa) |
| `BAT+` | BT1 + (fio vermelho do clip) · SW1 (um terminal) |
| `ARM`  | SW1 (outro terminal) · K1 COM |
| `BZ+`  | K1 NF · BZ1 + (fio vermelho) |
| `BAT−` | BT1 − (fio preto do clip) · BZ1 − (fio preto) |
| —      | K1 NA: **sem ligação** |
| —      | J1 CC1, CC2, D+, D−: sem ligação externa |

As redes `+5V`/`0V` e `BAT+`/`BAT−` **não podem se encostar**. São circuitos separados.

### Identificando os pinos do relé

O SRD-05VDC tem 5 pinos. Para identificar cada um com o multímetro na escala de continuidade ou de resistência:

1. **Bobina:** os dois pinos que medem ≈ 70 Ω entre si.
2. **COM:** o pino isolado numa das pontas, normalmente entre os dois pinos da bobina.
3. **NF:** o pino que mostra continuidade com o COM com o relé **desligado**.
4. **NA:** o pino que só fecha com o COM quando você aplica 5 V na bobina.

## Montagem na placa perfurada

- Coloque o **relé na metade de trás** da placa (a mais longe da chave ARMAR). O corpo da chave entra cerca de 18 mm na caixa e passa por cima da parte da frente da placa. Na faixa da frente, só use peças com menos de 11 mm de altura (diodo, resistor, ilhas de fios).
- D1, R1 e as ilhas de fios ficam na placa. O LED e o buzzer ficam na tampa.
- Fios que saem da placa:

  | Para | Fios | Comprimento sugerido |
  |------|------|----------------------|
  | J1 (USB-C) | 2 (VBUS, GND) | 8 cm |
  | SW1 (chave) | 2 | 10 cm |
  | LED1 (tampa) | 2 | 15 cm, com folga para abrir a tampa |
  | BZ1 (tampa) | 2 (os fios do próprio buzzer) | 15 cm |
  | BT1 (clip) | 2 | o próprio clip |

- Isole as emendas com termo-retrátil. Uma gota de cola quente nos fios evita que eles quebrem com o abre-e-fecha da tampa.

## Teste na bancada (antes de fechar a caixa)

1. **Sem bateria**, ligue o USB. O LED acende e o relé dá um clique. Meça ≈ 5 V entre `+5V` e `0V`.
2. Com o multímetro em continuidade, confira que **não há** continuidade entre `0V` e `BAT−`. Os lados devem estar isolados.
3. Com o USB ligado, meça COM–NF: deve estar **aberto**. Tire o USB: COM–NF deve **fechar**.
4. Coloque a bateria e ligue SW1. Com USB, silêncio. Sem USB, o buzzer toca.

## Diagnóstico

| Sintoma | Causa provável | O que fazer |
|---------|----------------|-------------|
| LED não acende | Plaquinha USB-C sem os resistores de 5,1 kΩ; LED invertido; R1 aberto | Teste com cabo USB-A → C; inverta o LED; meça R1 |
| LED acende, mas o relé não clica | Bobina mal soldada; pinos do relé trocados | Meça ≈ 70 Ω nos pinos da bobina e ≈ 5 V sobre eles |
| Buzzer toca **com** energia e para **sem** energia | Buzzer ligado no NA em vez do NF | Mude o fio do NA para o NF |
| Buzzer toca o tempo todo | Relé não está energizando | Veja as duas linhas acima |
| Buzzer não toca na falta de energia | SW1 desligada; bateria fraca; buzzer invertido (ele é polarizado) | Ligue SW1; meça a bateria (> 7 V); confira o + do buzzer |
| Som fraco | Bateria fraca | Troque a bateria |
| Alarme não toca numa queda real | Carregador ligado num nobreak ou estabilizador com bateria | Ligue o carregador direto na tomada da parede |

## Alternativas

- **Módulo relé de 1 canal (5 V):** funciona se tiver os bornes COM/NF/NA. Ligue VCC e GND no 5 V e prenda o IN no nível que aciona o relé (depende do módulo: alguns acionam em nível alto, outros em nível baixo). O relé avulso é mais simples e mais previsível.
- **Relé de sinal** (ex.: Omron G5V-1, contatos dourados): consome menos (≈ 30 mA) e tem contato mais confiável para correntes muito baixas. Exige ajustar o layout.
- **Pilhas em vez de bateria 9 V:** 3 a 4 pilhas AA (4,5–6 V) com o mesmo SFM-27 dão mais autonomia, mas precisam de um suporte de pilhas e de uma caixa maior.
