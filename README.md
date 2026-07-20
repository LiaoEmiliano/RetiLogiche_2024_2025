# Reti Logiche — Progetto 2024/2025

Progetto del corso **Reti Logiche** (Politecnico di Milano, A.Y. 2024/2025): implementazione in VHDL di un acceleratore hardware per il filtraggio di segnali digitali su memoria esterna.
**Valutazione:** 30/30

## Contenuto del repository

| File | Descrizione |
|------|-------------|
| [`10889441.vhd`](10889441.vhd) | Implementazione VHDL dell'entità `project_reti_logiche` |
| [`Report.pdf`](Report.pdf) | Relazione tecnica del progetto (architettura, FSM, schemi e risultati di simulazione) |

## Descrizione

Il componente legge da memoria un'intestazione di configurazione e una sequenza di campioni di ingresso, applica un filtro digitale a coefficienti fissi (3 o 5 tap, selezionabile) e scrive i risultati filtrati in una zona dedicata della memoria. L'elaborazione è guidata da una macchina a stati finiti (FSM) sincrona al fronte di salita del clock.

## Interfaccia

```vhdl
entity project_reti_logiche is
    port (
        i_clk      : in  std_logic;
        i_rst      : in  std_logic;
        i_start    : in  std_logic;
        i_add      : in  std_logic_vector(15 downto 0);
        o_done     : out std_logic;
        o_mem_addr : out std_logic_vector(15 downto 0);
        i_mem_data : in  std_logic_vector(7 downto 0);
        o_mem_data : out std_logic_vector(7 downto 0);
        o_mem_we   : out std_logic;
        o_mem_en   : out std_logic
    );
end project_reti_logiche;
```

| Segnale | Ruolo |
|---------|-------|
| `i_start` | Avvia (o mantiene) l'elaborazione |
| `i_add` | Indirizzo base in memoria del blocco dati |
| `o_done` | Alto al termine dell'elaborazione |
| `o_mem_*` / `i_mem_data` | Interfaccia verso memoria esterna (8 bit per parola) |

## Layout memoria

A partire dall'indirizzo `i_add`:

| Offset | Contenuto |
|--------|-----------|
| 0–1 | `K` — numero di campioni da produrre (16 bit) |
| 2 | `S` — byte di configurazione (`S(0)` seleziona il filtro attivo) |
| 3–9 | Coefficienti per filtro a **3 tap** (7 byte, signed) |
| 10–16 | Coefficienti per filtro a **5 tap** (7 byte, signed) |
| 17 … | Campioni di ingresso da elaborare |

I risultati vengono scritti a partire da `i_add + 17 + K`.

## Funzionamento

1. **Lettura header** — vengono caricati `K`, `S` e i due set di coefficienti.
2. **Selezione filtro** — se `S(0) = '0'` si usa il filtro a 3 tap; altrimenti quello a 5 tap.
3. **Buffer a scorrimento** — una finestra di 7 campioni (`buffer_R`) viene aggiornata ad ogni lettura.
4. **Convoluzione** — prodotto scalare tra campioni e coefficienti attivi (`active_coeff`).
5. **Normalizzazione** — shift aritmetici con arrotondamento e saturazione in `[-128, +127]`.
6. **Scrittura** — il campione filtrato viene memorizzato; il processo si ripete finché `K` raggiunge zero.

Al completamento la FSM entra nello stato `DONE` e `o_done` viene asserito.

## Architettura

L'implementazione adotta una FSM con stati `S0` … `S11` e `DONE`, separata in:

- **Processo sequenziale di stato** — transizioni tra stati
- **Processo combinatorio di controllo** — segnali di enable, contatori e mux
- **Registri dedicati** — indirizzi di lettura/scrittura, header counter, buffer, somma e normalizzazione

Per diagrammi di stato, tabelle di transizione e risultati di testbench, consultare [`Report.pdf`](Report.pdf).

## Simulazione

Il file VHDL è compatibile con simulatori standard (ModelSim, Vivado Simulator, GHDL, ecc.). Integrare `10889441.vhd` nel testbench fornito dal corso, collegando l'interfaccia memoria al modello di test appropriato.

## Relazione

La documentazione completa del progetto — specifiche, scelte progettuali, descrizione della FSM e verifica funzionale — è contenuta in:

**[`Report.pdf`](Report.pdf)**
