# Python

Python is a polished procedural 3D Snake arcade project for Godot 4.x. It uses runtime-generated meshes, materials, particles, lighting, UI, and procedural audio, so there are no paid or external asset dependencies.

## Run On Fedora

Install Godot:

```bash
sudo dnf install godot
```

Run from the project root:

```bash
godot .
```

## Controls

- Move: `WASD` or arrow keys
- Pause: `Esc`
- Restart: `R`

## Architecture

- `GameManager`: game state, score, spawning, collision rules, high-score persistence
- `SnakeController`: procedural segmented snake, movement, growth, body path sampling, effect visuals
- `CameraController`: angled top-down camera, smooth follow, speed zoom, shake
- `ArenaBuilder`: procedural reflective arena, neon grid, rails, lighting, post-processing
- `UIManager`: HUD, score, high score, active power-up display, state overlay
- `AudioManager`: generated WAV tones and ambient loop
- `EffectsManager`: particle bursts, shock rings, impact lights

## Export

1. Install Godot 4 export templates from the Godot editor: `Editor > Manage Export Templates`.
2. Open the project with `godot .`.
3. Use `Project > Export`.
4. Add a Linux/X11 preset.
5. Export to a build folder outside the repository, for example `../builds/neon-serpent-linux`.

The project targets Godot 4.x Forward+/Vulkan and is designed around a 60 FPS gameplay update.
