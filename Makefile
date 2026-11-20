APP := build/Lisdex.app
INSTALL_DIR := $(HOME)/Applications

.PHONY: build test coverage format lint app run install icons screenshots clean

# Quit a running instance and wait until it has fully exited (open fails otherwise).
QUIT_APP := pkill -x Lisdex; while pgrep -x Lisdex >/dev/null; do sleep 0.1; done; sleep 0.5; true
# LaunchServices can briefly report the old instance (-600); retry once.
OPEN_APP = open "$(1)" || (sleep 1 && open "$(1)")
SWIFT_PATHS := Package.swift Sources Tests scripts

build: ## Debug build
	swift build

test: ## Run unit tests
	swift test

coverage: ## Run tests with coverage
	swift test --enable-code-coverage

lint: ## Check formatting
	swift format lint --strict --configuration .swift-format --recursive $(SWIFT_PATHS)

format: ## Fix formatting
	swift format --in-place --configuration .swift-format --recursive $(SWIFT_PATHS)

app: ## Build the .app bundle
	./scripts/build-app.sh

run: app ## Build and launch the app
	@$(QUIT_APP)
	$(call OPEN_APP,$(APP))

install: app ## Copy the app to ~/Applications and launch it
	@$(QUIT_APP)
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/Lisdex.app"
	cp -R "$(APP)" "$(INSTALL_DIR)/"
	$(call OPEN_APP,$(INSTALL_DIR)/Lisdex.app)

icons: ## Regenerate icon exports from the SVG sources
	./scripts/export-icons.sh

screenshots: app ## Capture README screenshots into assets/screenshots/
	./scripts/screenshots.sh

clean:
	rm -rf .build build
