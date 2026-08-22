# AIPongGB: Game Boy Assembly AI Pong

An authentic Nintendo Game Boy (DMG/CGB) Pong game written in pure SM83 assembly using the **RGBDS** (Rednex Game Boy Development System) toolchain, created as an experiment in AI-assisted low-level retro game development with **Google Antigravity** and **Gemini AI**.

---

## 🎮 Features & Technical Highlights

- **State Machine Architecture**: Clean separation between Splash Screen, In-Game Gameplay, and Game Over / Victory states.
- **Single-Player vs AI**: Smooth player paddle controls paired with a reactive AI opponent.
- **Physics & Kinematics**:
  - Sub-pixel ball movement and bounding-box collision detection.
  - Directional deflection off paddles depending on impact location.
  - Arena wall bounce physics and serve delay timers.
- **Hardware-Accurate Game Boy Graphics & Memory**:
  - Fast OAM DMA transfer routine executing out of High RAM (HRAM).
  - 2BPP tile data and background tilemap management using `rgbgfx`.
  - VBlank interrupt-driven rendering, joypad polling, and HUD updates.
  - Memory-safe WRAM variable layout and VRAM access routines.

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
