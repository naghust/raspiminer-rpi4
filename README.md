# RasPiMiner — RPi4

> **Fork of [jvxis/nerdminer-pizero](https://github.com/jvxis/nerdminer-pizero)**  
> Adapted for Raspberry Pi 4 (aarch64) — no LCD required, terminal dashboard included.

---

## 🇧🇷 Português

### O que é isso?

RasPiMiner é um minerador Bitcoin solo estilo NerdMiner adaptado para o **Raspberry Pi 4**.  
Ele conecta a uma pool solo via protocolo Stratum e tenta encontrar um bloco Bitcoin — como uma loteria.

> ⚠️ **Aviso:** A probabilidade de encontrar um bloco é extremamente baixa. Este projeto é educacional e experimental. Não espere lucro.

---

### ⚡ Instalação rápida

```bash
git clone https://github.com/naghust/raspiminer-rpi4.git nerdminer
cd nerdminer
bash scripts/install.sh
```

O script faz tudo automaticamente: instala dependências, compila o cpuminer com as flags corretas para o Pi 4 e prepara os diretórios. Depois é só editar o `config.ini` e rodar.

---

### Diferenças em relação ao projeto original (Pi Zero W)

| Item | Pi Zero W (original) | Pi 4 (este fork) |
|---|---|---|
| Arquitetura | ARMv6 | aarch64 (ARM Cortex-A72) |
| Flags de compilação | `-march=armv6 -mfpu=vfp` | `-march=native -mtune=native` |
| Threads padrão | 1 | 2 (configurável até 4) |
| Display LCD | Waveshare 1.3" HAT | ❌ não utilizado |
| Dashboard | Tela LCD | Terminal (painel no bash) |
| Hashrate esperado | ~0.25 MH/s | ~2–6 MH/s |
| SPI / GPIO | necessário | ❌ não necessário |

---

### Requisitos

- Raspberry Pi 4 (qualquer variante de RAM)
- Raspberry Pi OS Bookworm 64-bit (aarch64)
- Conexão com a internet
- Endereço Bitcoin (bech32, começa com `bc1`)
- Pool solo compatível com Stratum (ex: [public-pool](https://github.com/benjamin-wilson/public-pool), solo.ckpool.org)

---

### Instalação passo a passo

**1. Clone o repositório:**
```bash
cd ~
git clone https://github.com/naghust/raspiminer-rpi4.git nerdminer
cd nerdminer
```

**2. Execute o instalador:**
```bash
bash scripts/install.sh
```

**3. Configure seu minerador:**
```bash
cp config.example.ini config.ini
nano config.ini
```

Edite os campos principais:
```ini
[wallet]
address = bc1qSEU_ENDERECO_AQUI

[pool]
url = stratum+tcp://SEU_POOL:3333
worker = RPi4
password = x
suggest_difficulty = 1

[miner]
threads = 2   ; veja a seção sobre threads abaixo
```

**4. Teste:**
```bash
# Terminal 1 — inicia o minerador
bash scripts/run-cpuminer.sh

# Terminal 2 — abre o painel
bash monitor.sh
```

---

### 🧵 Sobre as threads

O Raspberry Pi 4 possui **4 núcleos** (Cortex-A72). O número de threads do minerador é configurado em `config.ini`:

```ini
[miner]
threads = 2
```

| Threads | Hashrate estimado | Impacto no sistema |
|---|---|---|
| 1 | ~1–2 MH/s | Mínimo — sistema muito responsivo |
| 2 | ~2–4 MH/s | ✅ Recomendado — bom equilíbrio |
| 3 | ~3–5 MH/s | Alto — pouco espaço para o SO |
| 4 | ~4–6 MH/s | ⚠️ Máximo — veja os riscos abaixo |

**⚠️ Riscos de usar 4 threads (todos os núcleos):**

- **Temperatura elevada:** com todos os núcleos a 100%, a temperatura pode ultrapassar 80°C facilmente, fazendo o Pi entrar em *throttle* (redução automática de frequência para se proteger). O resultado paradoxal é que o hashrate pode **cair** em vez de subir.
- **Sistema sem resposta:** o sistema operacional e outros processos concorrem pelos mesmos núcleos. Com 4 threads, o Pi pode ficar lento ou instável.
- **Degradação do hardware:** operação contínua a temperatura alta acelera o desgaste do processador ao longo do tempo.

**Recomendação:** use `threads = 2` como ponto de partida. Se a temperatura se mantiver abaixo de 70°C com dissipador e ventilação adequados, você pode tentar `threads = 3`. Monitore sempre pelo painel (`monitor.sh`).

---

### Painel do terminal

O `monitor.sh` exibe em tempo real:

- 🌡 Temperatura do Pi
- ⚡ Hashrate local e da pool
- ✅ Shares aceitas / rejeitadas
- 🏆 Melhor dificuldade (worker e pool)
- ₿ Bloco atual e dificuldade da rede
- 💰 Preço do BTC (BRL e USD)
- 🖥 CPU, RAM, frequência, voltagem e status de throttle

---

### Rodar como serviço (auto-start no boot)

```bash
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pizero-cpuminer
```

---

### Dicas

- **Temperatura:** Acima de 80°C o Pi faz throttle (reduz frequência). Monitore pelo painel.
- **Dissipador:** Altamente recomendado se usar 3 ou 4 threads.
- **Pool própria:** Se você roda sua própria public-pool, configure `stats_api` com seu IP e porta (ex: `http://SEU_IP:8081/api/client/{address}`).

---

## 🇺🇸 English

### What is this?

RasPiMiner is a NerdMiner-style Bitcoin solo lottery miner adapted for the **Raspberry Pi 4**.  
It connects to a solo pool via Stratum protocol and tries to find a Bitcoin block — like a lottery ticket.

> ⚠️ **Disclaimer:** The probability of finding a block is extremely low. This project is educational and experimental. Do not expect profit.

---

### ⚡ Quick install

```bash
git clone https://github.com/naghust/raspiminer-rpi4.git nerdminer
cd nerdminer
bash scripts/install.sh
```

The script does everything automatically: installs dependencies, compiles cpuminer with the correct flags for Pi 4, and prepares the directories. Then just edit `config.ini` and run.

---

### Differences from the original project (Pi Zero W)

| Item | Pi Zero W (original) | Pi 4 (this fork) |
|---|---|---|
| Architecture | ARMv6 | aarch64 (ARM Cortex-A72) |
| Compiler flags | `-march=armv6 -mfpu=vfp` | `-march=native -mtune=native` |
| Default threads | 1 | 2 (configurable up to 4) |
| LCD Display | Waveshare 1.3" HAT | ❌ not used |
| Dashboard | LCD screen | Terminal (bash panel) |
| Expected hashrate | ~0.25 MH/s | ~2–6 MH/s |
| SPI / GPIO | required | ❌ not required |

---

### Requirements

- Raspberry Pi 4 (any RAM variant)
- Raspberry Pi OS Bookworm 64-bit (aarch64)
- Internet connection
- Bitcoin address (bech32, starts with `bc1`)
- Stratum-compatible solo pool (e.g. [public-pool](https://github.com/benjamin-wilson/public-pool), solo.ckpool.org)

---

### Step-by-step installation

**1. Clone the repository:**
```bash
cd ~
git clone https://github.com/naghust/raspiminer-rpi4.git nerdminer
cd nerdminer
```

**2. Run the installer:**
```bash
bash scripts/install.sh
```

**3. Configure your miner:**
```bash
cp config.example.ini config.ini
nano config.ini
```

Edit the main fields:
```ini
[wallet]
address = bc1qYOUR_ADDRESS_HERE

[pool]
url = stratum+tcp://YOUR_POOL:3333
worker = RPi4
password = x
suggest_difficulty = 1

[miner]
threads = 2   ; see the threads section below
```

**4. Test:**
```bash
# Terminal 1 — start the miner
bash scripts/run-cpuminer.sh

# Terminal 2 — open the dashboard
bash monitor.sh
```

---

### 🧵 About threads

The Raspberry Pi 4 has **4 cores** (Cortex-A72). The number of miner threads is set in `config.ini`:

```ini
[miner]
threads = 2
```

| Threads | Estimated hashrate | System impact |
|---|---|---|
| 1 | ~1–2 MH/s | Minimal — very responsive system |
| 2 | ~2–4 MH/s | ✅ Recommended — good balance |
| 3 | ~3–5 MH/s | High — little headroom for the OS |
| 4 | ~4–6 MH/s | ⚠️ Maximum — see risks below |

**⚠️ Risks of using 4 threads (all cores):**

- **High temperature:** with all cores at 100%, temperature can easily exceed 80°C, causing the Pi to throttle (automatic frequency reduction to protect itself). The paradoxical result is that hashrate may actually **drop** instead of increasing.
- **Unresponsive system:** the OS and other processes compete for the same cores. With 4 threads, the Pi may become slow or unstable.
- **Hardware degradation:** continuous operation at high temperature accelerates processor wear over time.

**Recommendation:** start with `threads = 2`. If temperature stays below 70°C with adequate heatsink and ventilation, you can try `threads = 3`. Always monitor via the dashboard (`monitor.sh`).

---

### Terminal dashboard

`monitor.sh` displays in real time:

- 🌡 Pi temperature
- ⚡ Local and pool hashrate
- ✅ Accepted / rejected shares
- 🏆 Best difficulty (worker and pool)
- ₿ Current block and network difficulty
- 💰 BTC price (BRL and USD)
- 🖥 CPU, RAM, frequency, voltage and throttle status

---

### Run as a service (auto-start on boot)

```bash
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pizero-cpuminer
```

---

### Tips

- **Temperature:** Above 80°C the Pi throttles (reduces frequency). Monitor via the dashboard.
- **Heatsink:** Highly recommended when using 3 or 4 threads.
- **Own pool:** If you run your own public-pool instance, set `stats_api` with your IP and port (e.g. `http://YOUR_IP:8081/api/client/{address}`).

---

## Credits

- Original project: [jvxis/nerdminer-pizero](https://github.com/jvxis/nerdminer-pizero)
- cpuminer: [pooler/cpuminer](https://github.com/pooler/cpuminer)
- Inspired by: [BitMaker-hub/NerdMiner_v2](https://github.com/BitMaker-hub/NerdMiner_v2)

## License

MIT — see [LICENSE](LICENSE)
