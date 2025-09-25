#!/bin/bash

# Deployment Script for Goral App
# Handles multi-environment deployment with validation

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DEPLOY_LOG="logs/deploy.log"
ENV="${1:-dev}"
BUILD_DIR="build"

# Valid environments
VALID_ENVS=("dev" "staging" "production")

# Ensure logs directory exists
mkdir -p logs

log() {
    echo -e "${GREEN}[DEPLOY]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$DEPLOY_LOG"
}

step() {
    echo -e "${BLUE}[DEPLOY]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$DEPLOY_LOG"
}

warn() {
    echo -e "${YELLOW}[DEPLOY]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$DEPLOY_LOG"
}

error() {
    echo -e "${RED}[DEPLOY]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$DEPLOY_LOG"
    exit 1
}

# Validate environment
validate_environment() {
    if [[ ! " ${VALID_ENVS[@]} " =~ " $ENV " ]]; then
        error "Invalid environment: $ENV. Valid options: ${VALID_ENVS[*]}"
    fi
    log "Deploying to environment: $ENV"
}

# Pre-deployment checks
pre_deployment_checks() {
    step "Running pre-deployment checks..."

    # Check if Flutter is available
    if ! command -v flutter &> /dev/null; then
        error "Flutter not found. Please install Flutter first."
    fi

    # Check if project is ready
    if [ ! -f "pubspec.yaml" ]; then
        error "Not a Flutter project. Run init.sh first."
    fi

    # Run tests
    log "Running tests..."
    if ! flutter test --reporter=json > test_results.json 2>/dev/null; then
        error "Tests failed. Deployment aborted."
    fi

    # Check test coverage
    flutter test --coverage > /dev/null 2>&1 || true
    if [ -f "coverage/lcov.info" ]; then
        # Simple coverage check (in a real scenario, use lcov)
        local test_files=$(find test -name "*.dart" | wc -l)
        if [ "$test_files" -lt 5 ]; then
            warn "Low test coverage. Consider adding more tests."
        fi
    fi

    # Security check
    log "Running security checks..."
    if ! flutter analyze --no-fatal-infos; then
        error "Flutter analyze found issues. Please fix them before deployment."
    fi

    # Performance benchmark
    log "Running performance benchmark..."
    if [ -f "scripts/performance-monitor.sh" ]; then
        if ! ./scripts/performance-monitor.sh benchmark; then
            warn "Performance benchmarks failed. Deployment will continue with warnings."
        fi
    fi

    log "Pre-deployment checks completed ✓"
}

# Build application
build_application() {
    step "Building application for $ENV environment..."

    # Set environment variables
    export ENV="$ENV"

    case "$ENV" in
        "dev")
            export FIREBASE_PROJECT="goral-app-dev"
            ;;
        "staging")
            export FIREBASE_PROJECT="goral-app-staging"
            ;;
        "production")
            export FIREBASE_PROJECT="goral-app-prod"
            ;;
    esac

    # Clean previous builds
    flutter clean
    flutter pub get

    # Build for web
    log "Building web application..."
    flutter build web --dart-define=ENV="$ENV"

    # Build for Android (if production)
    if [ "$ENV" = "production" ]; then
        log "Building Android APK..."
        flutter build apk --release --dart-define=ENV="$ENV"
    fi

    log "Build completed ✓"
}

# Deploy to Firebase
deploy_to_firebase() {
    step "Deploying to Firebase ($ENV)..."

    if ! command -v firebase &> /dev/null; then
        error "Firebase CLI not found. Please install: npm install -g firebase-tools"
    fi

    # Use correct Firebase project
    case "$ENV" in
        "dev")
            firebase use goral-app-dev
            ;;
        "staging")
            firebase use goral-app-staging
            ;;
        "production")
            firebase use goral-app-prod
            ;;
    esac

    # Deploy hosting
    log "Deploying to Firebase Hosting..."
    firebase deploy --only hosting

    # Deploy functions (if they exist)
    if [ -d "functions" ]; then
        log "Deploying Cloud Functions..."
        firebase deploy --only functions
    fi

    # Deploy Firestore rules
    if [ -f "firestore.rules" ]; then
        log "Deploying Firestore rules..."
        firebase deploy --only firestore:rules
    fi

    log "Firebase deployment completed ✓"
}

# Post-deployment verification
post_deployment_verification() {
    step "Running post-deployment verification..."

    local base_url=""
    case "$ENV" in
        "dev")
            base_url="https://goral-app-dev.web.app"
            ;;
        "staging")
            base_url="https://goral-app-staging.web.app"
            ;;
        "production")
            base_url="https://goral-app-prod.web.app"
            ;;
    esac

    # Health check
    log "Checking deployment health..."
    if command -v curl &> /dev/null; then
        if curl -s -o /dev/null -w "%{http_code}" "$base_url" | grep -q "200"; then
            log "Health check passed ✓"
        else
            warn "Health check failed. Manual verification required."
        fi
    else
        log "curl not available. Skipping automated health check."
    fi

    log "Deployment URL: $base_url"
}

# Generate deployment report
generate_deployment_report() {
    step "Generating deployment report..."

    local report_file="reports/deployment_$(date +%Y%m%d_%H%M%S).md"
    mkdir -p reports

    cat > "$report_file" << EOF
# Deployment Report - $(date)

## Environment
- Target: $ENV
- Timestamp: $(date)
- Git Commit: $(git rev-parse HEAD 2>/dev/null || echo "N/A")

## Build Information
- Flutter Version: $(flutter --version | head -n1 | cut -d' ' -f2)
- Build Status: ✅ Success

## Test Results
- Tests Executed: $(grep -c '"type":"test"' test_results.json 2>/dev/null || echo "N/A")
- Test Status: $([ -f test_results.json ] && echo "✅ Passed" || echo "❌ Failed")

## Performance Benchmarks
$([ -f "metrics/launch_time.txt" ] && echo "- Launch Time: $(cat metrics/launch_time.txt)ms")
$([ -f "metrics/memory_usage.txt" ] && echo "- Memory Usage: $(cat metrics/memory_usage.txt)MB")
$([ -f "metrics/api_response.txt" ] && echo "- API Response: $(cat metrics/api_response.txt)ms")

## Deployment URLs
- Web App: https://goral-app-$ENV.web.app
- Firebase Console: https://console.firebase.google.com/project/goral-app-$ENV

## Next Steps
- Monitor application performance
- Review logs for any issues
- Run smoke tests on deployed application

EOF

    log "Deployment report generated: $report_file"
}

# Rollback function
rollback_deployment() {
    warn "Initiating rollback procedure..."

    if command -v firebase &> /dev/null; then
        log "Rolling back Firebase hosting..."
        firebase hosting:clone goral-app-$ENV:$(date -d '1 hour ago' +%Y%m%d%H%M%S) goral-app-$ENV:live
    fi

    log "Rollback completed. Please verify the application."
}

# Main deployment function
main_deployment() {
    log "Starting deployment process for $ENV environment..."

    validate_environment
    pre_deployment_checks
    build_application
    deploy_to_firebase
    post_deployment_verification
    generate_deployment_report

    log ""
    log "🎉 Deployment completed successfully!"
    log "Environment: $ENV"
    log "URL: https://goral-app-$ENV.web.app"
    log ""
}

# Parse command line arguments
case "${2:-deploy}" in
    deploy)
        main_deployment
        ;;
    rollback)
        rollback_deployment
        ;;
    check)
        pre_deployment_checks
        ;;
    build)
        build_application
        ;;
    *)
        echo "Usage: $0 <environment> {deploy|rollback|check|build}"
        echo "Environments: ${VALID_ENVS[*]}"
        exit 1
        ;;
esac