VENV := ./venv
PYTHON := $(VENV)/bin/python3
AIDER := $(VENV)/bin/aider
MODEL_FILE := $(VENV)/.shai-model
ALIAS_FILE := $(VENV)/.shai-alias
SHAI_DIR := $(CURDIR)

all: help

install: install-ollama install-model install-aider install-alias
	@echo ""
	@echo "✓ shai installed. Run 'source ~/.bashrc' or open a new terminal."
	@echo "  Then: cd /your/project && shai"

install-ollama:
	@command -v ollama >/dev/null 2>&1 && echo "✓ Ollama already installed" && exit 0; \
	echo ""; \
	echo "── Ollama Installation ──"; \
	bash -c 'read -p "Install Ollama? [Y/n] " ans; \
	if [ "$$ans" = "n" ] || [ "$$ans" = "N" ]; then echo "Aborted. Install manually."; exit 1; fi'; \
	curl -fsSL https://ollama.com/install.sh | sh; \
	sudo systemctl start ollama; \
	echo "✓ Ollama installed and running"

install-model:
	@echo ""; \
	echo "── Hardware Detection ──"; \
	echo ""; \
	bash -c '\
	GPU_NAME="none"; \
	GPU_MEM=0; \
	RAM_GB=$$(free -g | awk "/^Mem:/{print \$$2}"); \
	if command -v nvidia-smi >/dev/null 2>&1; then \
	  GPU_NAME=$$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1); \
	  GPU_MEM=$$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1); \
	fi; \
	echo "  RAM:  $${RAM_GB}GB"; \
	if [ "$$GPU_NAME" != "none" ]; then \
	  echo "  GPU:  $$GPU_NAME ($${GPU_MEM}MB VRAM)"; \
	else \
	  echo "  GPU:  none detected (CPU inference)"; \
	fi; \
	echo ""; \
	RECOMMENDED=1; \
	if [ "$$GPU_MEM" -ge 24000 ] 2>/dev/null; then \
	  RECOMMENDED=3; \
	elif [ "$$GPU_MEM" -ge 12000 ] 2>/dev/null; then \
	  RECOMMENDED=2; \
	elif [ "$$GPU_MEM" -ge 8000 ] 2>/dev/null; then \
	  RECOMMENDED=1; \
	elif [ "$$RAM_GB" -ge 32 ] 2>/dev/null; then \
	  RECOMMENDED=2; \
	else \
	  RECOMMENDED=1; \
	fi; \
	echo "── Model Selection ──"; \
	echo ""; \
	echo "  1) qwen2.5-coder:7b       ~5GB RAM   Fast, good for most tasks"; \
	echo "  2) qwen2.5-coder:14b      ~12GB RAM  Better reasoning"; \
	echo "  3) qwen2.5-coder:32b      ~24GB RAM  Best quality, needs GPU/32GB+"; \
	echo "  4) deepseek-coder-v2:16b  ~12GB RAM  Strong alternative"; \
	echo "  5) codellama:13b          ~10GB RAM  Well-tested"; \
	echo ""; \
	echo "  ★ Recommended for your hardware: $$RECOMMENDED"; \
	echo ""; \
	read -p "Pick model [$$RECOMMENDED]: " choice; \
	choice=$${choice:-$$RECOMMENDED}; \
	case "$$choice" in \
	  2) MODEL="qwen2.5-coder:14b";; \
	  3) MODEL="qwen2.5-coder:32b";; \
	  4) MODEL="deepseek-coder-v2:16b";; \
	  5) MODEL="codellama:13b";; \
	  *) MODEL="qwen2.5-coder:7b";; \
	esac; \
	echo ""; \
	echo "Pulling $$MODEL ..."; \
	ollama pull $$MODEL; \
	mkdir -p $(VENV); \
	echo "$$MODEL" > $(MODEL_FILE); \
	echo "✓ Model $$MODEL ready"'

install-aider:
	@if [ -f "$(AIDER)" ]; then echo "✓ Aider already installed"; exit 0; fi; \
	echo ""; \
	echo "── Installing Aider ──"; \
	python3 -m venv $(VENV); \
	$(PYTHON) -m pip install --quiet aider-chat; \
	echo "✓ Aider installed"

install-alias:
	@echo ""
	@echo "── Alias Setup ──"
	@MODEL=$$(cat $(MODEL_FILE) 2>/dev/null || echo "qwen2.5-coder:7b"); \
	SHAI_BIN="$(SHAI_DIR)/venv/bin/aider"; \
	export MODEL SHAI_BIN; \
	bash -c '\
	read -p "Alias name [shai]: " name; \
	name=$${name:-shai}; \
	ALIAS_LINE="alias $$name=\"$$SHAI_BIN --model $$MODEL\""; \
	if grep -q "alias $$name=" ~/.bashrc 2>/dev/null; then \
	  sed -i "s|alias $$name=.*|$$ALIAS_LINE|" ~/.bashrc; \
	  echo "Updated existing alias"; \
	else \
	  echo "" >> ~/.bashrc; \
	  echo "# shai - Self-Hosted AI" >> ~/.bashrc; \
	  echo "$$ALIAS_LINE" >> ~/.bashrc; \
	fi; \
	echo "$$name" > $(ALIAS_FILE); \
	echo "✓ Alias $$name added to ~/.bashrc. Run source ~/.bashrc to activate."'

run: check
	@MODEL=$$(cat $(MODEL_FILE) 2>/dev/null || echo "qwen2.5-coder:7b"); \
	$(AIDER) --model $$MODEL

check:
	@command -v ollama >/dev/null 2>&1 || { echo "✗ Ollama not found. Run: make install"; exit 1; }
	@curl -s http://localhost:11434 >/dev/null 2>&1 || { echo "✗ Ollama not running. Run: sudo systemctl start ollama"; exit 1; }
	@[ -f "$(AIDER)" ] || { echo "✗ Aider not installed. Run: make install"; exit 1; }
	@echo "✓ Ready"

uninstall:
	@echo "Removing venv..."
	@rm -rf $(VENV)
	@if [ -f "$(ALIAS_FILE)" ]; then \
	  NAME=$$(cat $(ALIAS_FILE)); \
	  sed -i "/# shai - Self-Hosted AI/d" ~/.bashrc; \
	  sed -i "/alias $$NAME=/d" ~/.bashrc; \
	  echo "✓ Removed alias"; \
	fi
	@echo "✓ shai uninstalled. Ollama untouched."

distclean: uninstall

help:
	@echo ""
	@echo "shai — Self-Hosted AI"
	@echo ""
	@echo "  make install    One-time setup (ollama + model + aider + alias)"
	@echo "  make run        Launch in current directory"
	@echo "  make check      Verify ready"
	@echo "  make uninstall  Remove venv + alias"
	@echo ""
