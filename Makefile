DEVICE ?= fr955
KEY ?= $(HOME)/.config/garmin/developer_key.der
OUTPUT := build/$(DEVICE).prg

.PHONY: build simulate clean
build:
	mkdir -p build
	monkeyc -f monkey.jungle -d $(DEVICE) -o "$(OUTPUT)" -y "$(KEY)" -w

# Start the simulator automatically if it is not already running.
simulate: build
	bash scripts/simulate "$(CURDIR)/$(OUTPUT)" "$(DEVICE)"

clean:
	rm -rf build
