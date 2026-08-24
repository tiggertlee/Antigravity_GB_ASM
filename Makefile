# ==============================================================================
# Makefile - Build System for AIPongGB Game Boy Assembly Game
# Toolchain: RGBDS (Rednex Game Boy Development System) v0.8.0+
# ==============================================================================

# Target ROM name
ROM_NAME        := AIPongGB

# Directories
SRC_DIR         := src
GFX_DIR         := gfx
BUILD_DIR       := build
BUILD_GFX_DIR   := $(BUILD_DIR)/gfx

# Output files
ROM             := $(BUILD_DIR)/$(ROM_NAME).gb
MAP             := $(BUILD_DIR)/$(ROM_NAME).map
SYM             := $(BUILD_DIR)/$(ROM_NAME).sym

# Toolchain executables
RGBASM          := rgbasm
RGBLINK         := rgblink
RGBFIX          := rgbfix
RGBGFX          := rgbgfx

# Toolchain flags
ASFLAGS         := -v -Wall -I $(SRC_DIR) -I $(BUILD_DIR)
LDFLAGS         := -m $(MAP) -n $(SYM)
FIXFLAGS        := -v -p 0xFF -t "AIPONGGB"
GFXFLAGS        := -u

# Source assembly files and object targets
SRCS            := $(addprefix $(SRC_DIR)/, memory.asm graphics.asm main.asm studio.asm splash.asm game.asm gameover.asm sound.asm music.asm)
OBJS            := $(patsubst $(SRC_DIR)/%.asm, $(BUILD_DIR)/%.o, $(SRCS))
INCS            := $(wildcard $(SRC_DIR)/*.inc)

# Graphics assets
PNGS            := $(wildcard $(GFX_DIR)/*.png)
GFX_2BPP        := $(patsubst $(GFX_DIR)/%.png, $(BUILD_GFX_DIR)/%.2bpp, $(PNGS))
GFX_TILEMAP     := $(patsubst $(GFX_DIR)/%.png, $(BUILD_GFX_DIR)/%.tilemap, $(PNGS))
GFX_OBJS        := $(GFX_2BPP) $(GFX_TILEMAP)

# Keep intermediate graphics files from being removed automatically
.PRECIOUS: $(BUILD_GFX_DIR)/%.2bpp $(BUILD_GFX_DIR)/%.tilemap

# Default target
all: $(ROM)

# Link object files into Game Boy ROM
$(ROM): $(OBJS) | $(BUILD_DIR)
	@echo "Linking $@..."
	$(RGBLINK) $(LDFLAGS) -o $@ $(OBJS)
	@echo "Fixing ROM header with rgbfix..."
	$(RGBFIX) $(FIXFLAGS) $@
	@echo "Build successful: $@"

# Assemble each .asm source into an object file in build directory
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm $(INCS) $(GFX_OBJS) | $(BUILD_DIR)
	@echo "Assembling $<..."
	$(RGBASM) $(ASFLAGS) -o $@ $<

# Convert PNG images to 2BPP tile data and tilemap in build/gfx directory
$(BUILD_GFX_DIR)/%.2bpp $(BUILD_GFX_DIR)/%.tilemap: $(GFX_DIR)/%.png | $(BUILD_GFX_DIR)
	@echo "Converting graphics $<..."
	$(RGBGFX) $(GFXFLAGS) -o $(BUILD_GFX_DIR)/$*.2bpp -t $(BUILD_GFX_DIR)/$*.tilemap $<

# Create directories as needed
$(BUILD_DIR) $(BUILD_GFX_DIR):
	@mkdir -p $@

# Clean build artifacts
clean:
	@echo "Cleaning build directory..."
	rm -rf $(BUILD_DIR)

.PHONY: all clean
