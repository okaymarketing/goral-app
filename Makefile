# Goral App - Enterprise Flutter Project Makefile
# Provides convenient commands for development workflow

.PHONY: help init clean install test build deploy watch lint format analyze security performance

# Default target
help: ## Show this help message
	@echo "Goral App - Enterprise Flutter Development"
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Project initialization
init: ## Initialize the project with enterprise configuration
	@echo "🚀 Initializing Goral App Enterprise Project..."
	chmod +x init.sh
	./init.sh

# Cleanup
clean: ## Clean build artifacts and caches
	@echo "🧹 Cleaning project..."
	flutter clean
	rm -rf build/
	rm -rf .dart_tool/
	rm -rf coverage/
	rm -rf logs/
	rm -rf metrics/
	rm -rf reports/

# Dependencies
install: ## Install dependencies
	@echo "📦 Installing dependencies..."
	flutter pub get

# Development commands
dev: install ## Start development server
	@echo "🔧 Starting development server..."
	flutter run --hot

watch: install ## Start development with hot reload
	@echo "👀 Starting with hot reload..."
	flutter run --hot --verbose

# Testing commands
test: ## Run all tests
	@echo "🧪 Running tests..."
	flutter test

test-watch: ## Run tests in watch mode
	@echo "👀 Running tests in watch mode..."
	flutter test --reporter=expanded --coverage

test-coverage: ## Generate test coverage report
	@echo "📊 Generating coverage report..."
	flutter test --coverage
	@if command -v genhtml >/dev/null 2>&1; then \
		genhtml coverage/lcov.info -o coverage/html; \
		echo "Coverage report generated at coverage/html/index.html"; \
	else \
		echo "Install lcov for HTML coverage reports: brew install lcov"; \
	fi

# Code quality
lint: ## Run linter
	@echo "🔍 Running linter..."
	flutter analyze

format: ## Format code
	@echo "🎨 Formatting code..."
	dart format lib/ test/

format-check: ## Check code formatting
	@echo "🎨 Checking code formatting..."
	dart format --output=none --set-exit-if-changed lib/ test/

# Security
security: ## Run security analysis
	@echo "🔐 Running security analysis..."
	flutter analyze --no-fatal-infos
	@echo "Security scan completed"

# Performance
performance: ## Run performance benchmarks
	@echo "⚡ Running performance benchmarks..."
	@if [ -f scripts/performance-monitor.sh ]; then \
		chmod +x scripts/performance-monitor.sh; \
		./scripts/performance-monitor.sh benchmark; \
	else \
		echo "Performance monitor script not found"; \
	fi

performance-continuous: ## Start continuous performance monitoring
	@echo "⚡ Starting continuous performance monitoring..."
	@if [ -f scripts/performance-monitor.sh ]; then \
		chmod +x scripts/performance-monitor.sh; \
		./scripts/performance-monitor.sh continuous; \
	else \
		echo "Performance monitor script not found"; \
	fi

# Build commands
build: ## Build for all platforms
	@echo "🏗️ Building for all platforms..."
	flutter build web --release
	flutter build apk --release

build-web: ## Build for web
	@echo "🌐 Building for web..."
	flutter build web --release

build-android: ## Build Android APK
	@echo "🤖 Building Android APK..."
	flutter build apk --release

build-ios: ## Build iOS (macOS only)
	@echo "🍎 Building iOS..."
	flutter build ios --release

# Deployment commands
deploy-dev: ## Deploy to development environment
	@echo "🚀 Deploying to development..."
	@if [ -f scripts/deploy.sh ]; then \
		chmod +x scripts/deploy.sh; \
		./scripts/deploy.sh dev deploy; \
	else \
		echo "Deploy script not found"; \
	fi

deploy-staging: ## Deploy to staging environment
	@echo "🚀 Deploying to staging..."
	@if [ -f scripts/deploy.sh ]; then \
		chmod +x scripts/deploy.sh; \
		./scripts/deploy.sh staging deploy; \
	else \
		echo "Deploy script not found"; \
	fi

deploy-prod: ## Deploy to production environment
	@echo "🚀 Deploying to production..."
	@if [ -f scripts/deploy.sh ]; then \
		chmod +x scripts/deploy.sh; \
		./scripts/deploy.sh production deploy; \
	else \
		echo "Deploy script not found"; \
	fi

# Monitoring commands
watchdog-start: ## Start Claude Code watchdog system
	@echo "🐕 Starting Claude Code watchdog..."
	@if [ -f scripts/watchdog.sh ]; then \
		chmod +x scripts/watchdog.sh; \
		./scripts/watchdog.sh start; \
	else \
		echo "Watchdog script not found"; \
	fi

watchdog-status: ## Check watchdog status
	@echo "🐕 Checking watchdog status..."
	@if [ -f scripts/watchdog.sh ]; then \
		chmod +x scripts/watchdog.sh; \
		./scripts/watchdog.sh status; \
	else \
		echo "Watchdog script not found"; \
	fi

watchdog-stop: ## Stop watchdog system
	@echo "🐕 Stopping watchdog..."
	@if [ -f scripts/watchdog.sh ]; then \
		chmod +x scripts/watchdog.sh; \
		./scripts/watchdog.sh stop; \
	else \
		echo "Watchdog script not found"; \
	fi

# Database commands
db-migrate: ## Run database migrations
	@echo "🗄️ Running database migrations..."
	@echo "Firestore migrations would be handled here"

# Utility commands
logs: ## View application logs
	@echo "📋 Viewing logs..."
	@if [ -d logs ]; then \
		tail -f logs/*.log; \
	else \
		echo "No logs directory found"; \
	fi

status: ## Show project status
	@echo "📊 Project Status:"
	@echo "Flutter Version: $$(flutter --version | head -n1)"
	@echo "Git Branch: $$(git branch --show-current 2>/dev/null || echo 'Not a git repo')"
	@echo "Git Status: $$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') files changed"
	@if [ -f pubspec.yaml ]; then echo "Project: $$(grep '^name:' pubspec.yaml | cut -d' ' -f2)"; fi
	@echo ""
	@echo "Configuration Files:"
	@ls -la .claude-code/ 2>/dev/null | grep -v '^total' | wc -l | xargs echo "  Claude Code configs:"
	@echo ""

doctor: ## Run Flutter doctor
	@echo "🩺 Running Flutter doctor..."
	flutter doctor

# CI/CD simulation
ci: lint test build ## Run CI pipeline locally
	@echo "🔄 CI Pipeline completed successfully"

cd: performance security ## Run CD checks
	@echo "🚀 CD Pipeline checks completed"

# Setup development environment
setup-dev: ## Setup development environment
	@echo "🛠️ Setting up development environment..."
	flutter doctor
	flutter pub get
	@echo "Development environment ready!"

# Generate documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	dart doc .
	@echo "Documentation generated in doc/api/"

# Archive project
archive: clean ## Create project archive
	@echo "📦 Creating project archive..."
	tar -czf goral-app-$$(date +%Y%m%d-%H%M%S).tar.gz \
		--exclude='.git' \
		--exclude='build' \
		--exclude='.dart_tool' \
		--exclude='logs' \
		--exclude='metrics' \
		--exclude='reports' \
		.
	@echo "Archive created: goral-app-$$(date +%Y%m%d-%H%M%S).tar.gz"

# Enterprise commands
enterprise-init: init performance security ## Full enterprise initialization
	@echo "🏢 Enterprise initialization completed"

enterprise-deploy: ci cd deploy-prod ## Full enterprise deployment
	@echo "🏢 Enterprise deployment completed"

enterprise-monitor: watchdog-start performance-continuous ## Start enterprise monitoring
	@echo "🏢 Enterprise monitoring started"