# shai

**S**elf-**H**osted **AI**. Local Aider + Ollama wrapper. No cloud, no npm, no telemetry.

## Install

    git clone <repo-url> shai
    cd shai
    make install

Interactive wizard handles:
1. Ollama installation (skips if present)
2. Hardware detection (GPU VRAM + RAM) with automatic model recommendation
3. Aider venv creation (lives in ./venv)
4. Alias creation in ~/.bashrc

The wizard detects your hardware and suggests the best model for your setup. You can accept the recommendation or override it.

Then:

    source ~/.bashrc
    cd /your/project
    shai

## Model Options

| # | Model                   | RAM    | Notes                          |
|---|-------------------------|--------|--------------------------------|
| 1 | qwen2.5-coder:7b        | ~5GB   | Fast, good for most tasks      |
| 2 | qwen2.5-coder:14b       | ~12GB  | Better reasoning               |
| 3 | qwen2.5-coder:32b       | ~24GB  | Best quality, needs GPU/32GB+  |
| 4 | deepseek-coder-v2:16b   | ~12GB  | Strong alternative             |
| 5 | codellama:13b           | ~10GB  | Well-tested                    |

Hardware recommendations:
- GPU ≥24GB VRAM → model 3
- GPU 12-24GB VRAM → model 2
- GPU 8-12GB VRAM → model 1
- No GPU, RAM ≥32GB → model 2
- No GPU, RAM <32GB → model 1

## Targets

| Target            | Description                                      |
|-------------------|--------------------------------------------------|
| make install      | One-time interactive setup wizard                |
| make run          | Launch in current directory                      |
| make check        | Verify ollama + aider ready                      |
| make uninstall    | Remove venv + alias (keeps ollama)               |

## Notes

- Always run from your project directory so shai sees your git repo
- Venv lives at ./venv inside this directory — fully self-contained
- Delete this directory = full uninstall (plus make uninstall cleans bashrc)
- Model choice stored in ./venv/.shai-model — rerun make install-model to switch
