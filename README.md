# AIPongGB: Game Boy Assembly AI Pong

An authentic Nintendo Game Boy (DMG/CGB) Pong game written in pure SM83 assembly using the **RGBDS** (Rednex Game Boy Development System) toolchain, created as an experiment in AI-assisted low-level retro game development with **Google Antigravity** and **Gemini AI**.

---

## 🎮 Features & Technical Highlights

- **State Machine Architecture**: Clean separation between Splash Screen, In-Game Gameplay, and Game Over / Victory states.
- **Single-Player vs Tuned AI**: Responsive human paddle controls paired with a beatable AI opponent featuring a mid-court vision horizon (`X >= 76`) and an 8px deadzone for natural, human-like reaction dynamics.
- **Dynamic Physics & Kinematics**:
  - Base velocity floor (1 px/frame) ensuring the ball never moves slower than baseline.
  - Dynamic paddle momentum: moving paddles accelerate returns (+1 speed), while stationary paddle blocks dampen and slow down the ball (-1 speed).
  - Near-paddle wall ricochet boost: bouncing off walls within 20px of the paddle front grants an extra acceleration boost.
  - Multi-zone paddle deflection angles (upper, center, lower thirds).
  - Arena wall bounce reflections and serve delay timers.
- **Hardware-Accurate Game Boy Graphics & Memory**:
  - Fast OAM DMA transfer routine executing out of High RAM (HRAM).
  - 2BPP tile data and background tilemap management using `rgbgfx`.
  - VBlank interrupt-driven rendering, joypad polling, and HUD updates.
  - Memory-safe WRAM variable layout and VRAM access routines.
- **APU Sound Effects & Multi-Track Music System**:
  - **"Neon Surge" Title Soundtrack**: An energetic, medium-tempo electro punk chiptune track in A minor (128.5 BPM) featuring pulse lead riffs (Ch1), a driving 8th/16th pumping bassline (Ch2), and punchy noise percussion (Ch4: kick, snare, hi-hats).
  - **"Victory Bounce" Win Soundtrack**: An upbeat, happy skipping victory chiptune in C Major (112.5 BPM) with bouncing arpeggios, walking basslines, and celebratory snare rolls.
  - **"Death March" Lose Soundtrack**: A slow, heavy funeral dirge in C minor (53.5 BPM) with brooding, descending bass pulses and melancholic lament melodies.
  - Crisp high-pitch pulse beep on paddle deflection (Channel 1 ~880 Hz).
  - Mellow low-pitch pulse boop on wall reflections (Channel 1 ~260 Hz).
  - Harsh 7-bit LFSR noise buzzer on out-of-bounds goals (Channel 4).

---

## 📁 Project Structure

The project uses a clean modular structure with out-of-tree build artifact isolation:

```
Antigravity_GB_ASM/
├── .devcontainer/         # Ready-to-use VS Code / Antigravity Dev Container with RGBDS
├── gfx/                   # Source graphics assets
│   ├── CleanedPong.xcf    # GIMP master image project
│   └── Pong.png           # Splash screen logo asset
├── src/                   # Game Boy SM83 Assembly source & include files
│   ├── main.asm           # Reset vectors, ROM header, system init, state loop
│   ├── game.asm           # Pong physics, collision detection, AI, and scoring
│   ├── splash.asm         # Splash/title screen presentation and timing
│   ├── gameover.asm       # Game over screen, winner announcement, restart logic
│   ├── graphics.asm       # VRAM/OAM graphics copy and LCD control routines
│   ├── graphics.inc       # Tile indices, palette constants, and sprite equates
│   ├── sound.asm          # APU audio driver and sound effect routines
│   ├── sound.inc          # Sound system equates and pitch constants
│   ├── music.asm          # Chiptune music player and "Neon Surge" song tables
│   ├── music.inc          # Note frequencies, drum equates, and music declarations
│   ├── memory.asm         # Memory zeroing and OAM DMA routine loader
│   ├── memory.inc         # WRAM and HRAM variable declarations
│   └── hardware.inc       # Standard Game Boy hardware register definitions
├── build/                 # Generated build artifacts (ignored by git)
│   ├── AIPongGB.gb        # Header-fixed Game Boy ROM image
│   ├── AIPongGB.map       # Linker memory map file
│   ├── AIPongGB.sym       # Linker symbol file (for emulator debugging)
│   ├── *.o                # Assembled object files
│   └── gfx/               # Converted 2BPP graphics and tilemaps
├── Makefile               # Automated build & asset conversion pipeline
├── README.md              # Project documentation and synopsis
├── LICENSE                # Apache 2.0 License
└── .gitignore             # Git ignore configuration
```

---

## 🕹️ Controls

| Button | Action |
|---|---|
| **D-Pad Up / Down** | Move Player Paddle |
| **Start / A Button** | Advance Splash Screen / Start Match / Replay after Game Over |

---

## 🛠️ Building the ROM

### Prerequisites
- [RGBDS](https://rgbds.gbdev.io/) (v0.8.0 or newer)
  - `rgbasm`, `rgblink`, `rgbfix`, and `rgbgfx`
- `make`
- *(Optional)* VS Code / Dev Containers (preconfigured in `.devcontainer/`)

### Build Commands

```bash
# Build the final Game Boy ROM (outputs to build/AIPongGB.gb)
make

# Clean all build artifacts and compiled assets
make clean
```

---

## 🕹️ Running the Game

Open `build/AIPongGB.gb` in your favorite Game Boy emulator:
- [SameBoy](https://sameboy.github.io/)
- [BGB](https://bgb.bircd.org/)
- [mGBA](https://mgba.io/)
- [Mesen](https://www.mesen.ca/)

---

## 📜 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
