# RasPiMiner — RPi4

> **Fork of [jvxis/nerdminer-pizero](https://github.com/jvxis/nerdminer-pizero)**  
> Adapted for Raspberry Pi 4 (aarch64) — no LCD required, terminal dashboard included.

---

## 🇧🇷 Português

### O que é isso?

RasPiMiner é um minerador Bitcoin solo estilo NerdMiner adaptado para o **Raspberry Pi 4**.  
Ele conecta a uma pool solo (como a [public-pool](https://github.com/benjamin-wilson/public-pool)) via protocolo Stratum e tenta encontrar um bloco Bitcoin — como uma loteria.

> ⚠️ **Aviso:** A probabilidade de encontrar um bloco é extremamente baixa. Este projeto é educacional e experimental. Não espere lucro.

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

### Requisitos

- Raspberry Pi 4 (qualquer variante de RAM)
- Raspberry Pi OS Bookworm 64-bit (aarch64)
- Conexão com a internet
- Endereço Bitcoin (bech32, começa com `bc1`)
- Pool solo compatível com Stratum (ex: [public-pool](https://github.com/benjamin-wilson/public-pool), solo.ckpool.org)

### Instalação passo a passo

**1. Clone o repositório:**
```bash
cd ~
git clone https://github.com/naghust/raspiminer-rpi4.git nerdminer
cd nerdminer
```

**2. Instale as dependências:**
```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential automake autoconf pkg-config git \
    libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev \
    python3-pil python3-numpy python3-requests
```

**3. Compile o cpuminer para aarch64:**
```bash
git clone https://github.com/pooler/cpuminer.git .build/cpuminer
cd .build/cpuminer
git checkout -q 5f02105940edb61144c09a7eb960bba04a10d5b7
git apply ~/nerdminer/patches/0001-cpuminer-suggest-difficulty.patch
./autogen.sh
./configure CFLAGS="-O3 -march=native -mtune=native"
make -j2
sudo make install
cd ~/nerdminer
```

**4. Prepare os diretórios:**
```bash
sudo mkdir -p /var/log/pizero-miner
sudo chown $USER /var/log/pizero-miner
cp config.example.ini config.ini
```

**5. Configure seu minerador:**
```bash
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
threads = 2   ; use até 4 no Pi 4
```

**6. Teste:**
```bash
# Terminal 1 — inicia o minerador
bash scripts/run-cpuminer.sh

# Terminal 2 — abre o painel
bash monitor.sh
```

### Painel do terminal

O `monitor.sh` exibe em tempo real:

- 🌡 Temperatura do Pi
- ⚡ Hashrate local e da pool
- ✅ Shares aceitas / rejeitadas
- 🏆 Melhor dificuldade (worker e pool)
- ₿ Bloco atual e dificuldade da rede
- 💰 Preço do BTC (BRL e USD)
- 🖥 CPU, RAM, frequência, voltagem e status de throttle

### Rodar como serviço (auto-start no boot)

```bash
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pizero-cpuminer
```

### Dicas

- **Threads:** Use `threads = 2` para não sobrecarregar. Com 4 threads o Pi 4 aquece mais — use dissipador.
- **Temperatura:** Acima de 80°C o Pi faz throttle (reduz frequência). Monitore pelo painel.
- **Pool própria:** Se você roda sua própria public-pool, configure `stats_api` com seu IP e porta 8081.

---

## 🇺🇸 English

### What is this?

RasPiMiner is a NerdMiner-style Bitcoin solo lottery miner adapted for the **Raspberry Pi 4**.  
It connects to a solo pool via Stratum protocol and tries to find a Bitcoin block — like a lottery ticket.

> ⚠️ **Disclaimer:** The probability of finding a block is extremely low. This project is educational and experimental. Do not expect profit.

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

### Requirements

- Raspberry Pi 4 (any RAM variant)
- Raspberry Pi OS Bookworm 64-bit (aarch64)
- Internet connection
- Bitcoin address (bech32, starts with `bc1`)
- Stratum-compatible solo pool (e.g. [public-pool](https://github.com/benjamin-wilson/public-pool), solo.ckpool.org)

### Step-by-step installation

**1. Clone the repository:**
```bash
cd ~
git clone https://github.com/naghust/raspiminer-rpi4.git nerdminer
cd nerdminer
```

**2. Install dependencies:**
```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential automake autoconf pkg-config git \
    libcurl4-openssl-dev libjansson-dev libssl-dev libgmp-dev \
    python3-pil python3-numpy python3-requests
```

**3. Build cpuminer for aarch64:**
```bash
git clone https://github.com/pooler/cpuminer.git .build/cpuminer
cd .build/cpuminer
git checkout -q 5f02105940edb61144c09a7eb960bba04a10d5b7
git apply ~/nerdminer/patches/0001-cpuminer-suggest-difficulty.patch
./autogen.sh
./configure CFLAGS="-O3 -march=native -mtune=native"
make -j2
sudo make install
cd ~/nerdminer
```

**4. Prepare directories:**
```bash
sudo mkdir -p /var/log/pizero-miner
sudo chown $USER /var/log/pizero-miner
cp config.example.ini config.ini
```

**5. Configure your miner:**
```bash
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
threads = 2   ; use up to 4 on Pi 4
```

**6. Test:**
```bash
# Terminal 1 — start the miner
bash scripts/run-cpuminer.sh

# Terminal 2 — open the dashboard
bash monitor.sh
```

### Terminal dashboard

`monitor.sh` displays in real time:

- 🌡 Pi temperature
- ⚡ Local and pool hashrate
- ✅ Accepted / rejected shares
- 🏆 Best difficulty (worker and pool)
- ₿ Current block and network difficulty
- 💰 BTC price (BRL and USD)
- 🖥 CPU, RAM, frequency, voltage and throttle status

### Run as a service (auto-start on boot)

```bash
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now pizero-cpuminer
```

### Tips

- **Threads:** Use `threads = 2` to avoid overloading. With 4 threads the Pi 4 runs hotter — use a heatsink.
- **Temperature:** Above 80°C the Pi throttles (reduces frequency). Monitor via the dashboard.
- **Own pool:** If you run your own public-pool instance, set `stats_api` with your IP and port 8081.

---

## Credits

- Original project: [jvxis/nerdminer-pizero](https://github.com/jvxis/nerdminer-pizero)
- cpuminer: [pooler/cpuminer](https://github.com/pooler/cpuminer)
- Inspired by: [BitMaker-hub/NerdMiner_v2](https://github.com/BitMaker-hub/NerdMiner_v2)

## License

MIT — see [LICENSE](LICENSE)
