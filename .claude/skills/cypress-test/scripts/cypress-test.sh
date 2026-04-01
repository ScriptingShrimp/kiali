#!/usr/bin/env bash

# Cypress Test Runner with Full Stacktrace Capture
# Runs specific Cypress tests and captures comprehensive error information

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="$(pwd)/${TEST_OUTPUT_DIR:-test-results-$TIMESTAMP}"

# Default configuration
CYPRESS_VIDEO="${CYPRESS_VIDEO:-false}"
CYPRESS_BROWSER="${CYPRESS_BROWSER:-electron}"
CYPRESS_HEADED="${CYPRESS_HEADED:-false}"
CYPRESS_BASE_URL="${CYPRESS_BASE_URL:-http://localhost:3001}"
DEBUG_MODE=false
TEST_SPEC=""
TAGS=""
USE_SELECTED=false

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_section() {
    echo "" >&2
    echo -e "${BLUE}========================================${NC}" >&2
    echo -e "${BLUE}$1${NC}" >&2
    echo -e "${BLUE}========================================${NC}" >&2
}

show_help() {
    cat << EOF
Usage: $0 <test-spec> [options]

Run specific Cypress tests with full stacktrace and error capture.

ARGUMENTS:
  <test-spec>           Test specification (feature file, tag, or test name)
                        Examples:
                          graph/graph-side-panel.feature
                          @smoke
                          "Login functionality"

OPTIONS:
  --selected            Run only tests annotated with @selected tag
  --video               Enable video recording (default: disabled)
  --no-video            Disable video recording
  --headed              Run in headed mode (open browser)
  --headless            Run in headless mode (default)
  --browser <name>      Browser to use (chrome, firefox, edge, electron)
  --base-url <url>      Base URL for tests (default: http://localhost:3001)
  --env <vars>          Environment variables (comma-separated KEY=VALUE)
  --tag <tag>           Run tests with specific tag
  --output-dir <dir>    Output directory for results
  --debug               Enable debug mode (verbose logging)
  --config-file <file>  Custom Cypress config file
  --no-screenshots      Disable screenshots
  --help                Show this help message

EXAMPLES:
  # Run a specific feature file
  $0 graph/graph-side-panel.feature

  # Run only selected tests in a feature file
  $0 graph/graph-side-panel.feature --selected

  # Run tests with a tag
  $0 @smoke --video

  # Run in headed mode with debug output
  $0 login.feature --headed --debug

  # Run against a different environment
  $0 @core-1 --base-url https://kiali.example.com

ENVIRONMENT VARIABLES:
  CYPRESS_BASE_URL              Base URL (default: http://localhost:3001)
  CYPRESS_USERNAME              Username for authentication
  CYPRESS_PASSWD                Password for authentication
  CYPRESS_AUTH_PROVIDER         Auth provider name
  CYPRESS_VIDEO                 Enable video (true/false)
  CYPRESS_BROWSER               Browser to use
  CYPRESS_HEADED                Headed mode (true/false)
  TEST_OUTPUT_DIR               Output directory for results

EOF
    exit 0
}

# Parse arguments
parse_arguments() {
    # Parse options first to handle --selected without test spec
    while [[ $# -gt 0 ]]; do
        case $1 in
            --selected)
                USE_SELECTED=true
                shift
                ;;
            --video)
                CYPRESS_VIDEO=true
                shift
                ;;
            --no-video)
                CYPRESS_VIDEO=false
                shift
                ;;
            --headed)
                CYPRESS_HEADED=true
                shift
                ;;
            --headless)
                CYPRESS_HEADED=false
                shift
                ;;
            --browser)
                CYPRESS_BROWSER="$2"
                shift 2
                ;;
            --base-url)
                CYPRESS_BASE_URL="$2"
                shift 2
                ;;
            --env)
                CYPRESS_ENV="$2"
                shift 2
                ;;
            --tag)
                TAGS="$2"
                shift 2
                ;;
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            --config-file)
                CYPRESS_CONFIG_FILE="$2"
                shift 2
                ;;
            --no-screenshots)
                CYPRESS_SCREENSHOTS=false
                shift
                ;;
            --help)
                show_help
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                ;;
            *)
                # This is the test spec
                if [[ -z "$TEST_SPEC" ]]; then
                    TEST_SPEC="$1"
                else
                    log_error "Multiple test specifications provided: $TEST_SPEC and $1"
                    show_help
                fi
                shift
                ;;
        esac
    done

    # If --selected is used without a test spec, run all selected tests
    if [[ "$USE_SELECTED" == "true" && -z "$TEST_SPEC" ]]; then
        TEST_SPEC="@selected"
    fi

    # Validate that we have a test spec
    if [[ -z "$TEST_SPEC" ]]; then
        log_error "No test specification provided"
        show_help
    fi
}

# Check if Kiali is reachable and offer options if not
check_kiali_instance() {
    log_section "Checking Kiali Instance"

    # First, try to get Kiali URL from kubectl if CYPRESS_BASE_URL is the default
    if [[ "$CYPRESS_BASE_URL" == "http://localhost:3001" ]] && command -v kubectl &> /dev/null; then
        log_info "Checking for Kiali in cluster..."

        # Check if there's a Kiali service in istio-system namespace
        if kubectl get svc kiali -n istio-system &> /dev/null; then
            log_info "Found Kiali service in istio-system namespace"

            # Wait for LoadBalancer to have an ingress IP
            if kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' -n istio-system service/kiali --timeout=5s &> /dev/null; then
                local kiali_ip
                kiali_ip=$(kubectl get svc kiali -n istio-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

                if [[ -n "$kiali_ip" ]]; then
                    CYPRESS_BASE_URL="http://${kiali_ip}/kiali"
                    export CYPRESS_BASE_URL
                    log_success "Using Kiali from cluster at $CYPRESS_BASE_URL"
                    return 0
                fi
            fi
        fi
    fi

    # Try to reach Kiali API
    local kiali_url="$CYPRESS_BASE_URL/api/status"
    log_info "Checking Kiali at: $kiali_url"

    if curl -s --connect-timeout 3 "$kiali_url" > /dev/null 2>&1; then
        log_success "Kiali instance is reachable at $CYPRESS_BASE_URL"
        return 0
    fi

    log_warning "Cannot reach Kiali at $CYPRESS_BASE_URL"
    echo "" >&2
    echo -e "${YELLOW}Cypress tests require a running Kiali instance.${NC}" >&2
    echo "" >&2
    echo "Please select how you want to proceed:" >&2
    echo "" >&2
    echo "  1) Use KinD cluster with integration test setup" >&2
    echo "     (Recommended - creates a KinD cluster with Kiali)" >&2
    echo "" >&2
    echo "  2) Use local Kiali instance" >&2
    echo "     (Start Kiali backend with 'make run-backend')" >&2
    echo "" >&2
    echo "  3) Use custom Kiali URL" >&2
    echo "     (Specify a different URL for an existing instance)" >&2
    echo "" >&2
    echo "  4) Skip check and continue anyway" >&2
    echo "     (Tests will likely fail if Kiali is not running)" >&2
    echo "" >&2
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            log_info "Setting up KinD cluster with integration tests..."
            echo "" >&2

            # Check if kubectl is available
            if ! command -v kubectl &> /dev/null; then
                log_error "kubectl is not installed. Please install kubectl first."
                exit 1
            fi

            # Check if script exists
            if [[ ! -f "$REPO_ROOT/hack/run-integration-tests.sh" ]]; then
                log_error "Integration test script not found at $REPO_ROOT/hack/run-integration-tests.sh"
                exit 1
            fi

            # Run the integration test setup
            log_info "Running: $REPO_ROOT/hack/run-integration-tests.sh"
            log_warning "This may take several minutes..."
            echo "" >&2

            if ! "$REPO_ROOT/hack/run-integration-tests.sh"; then
                log_error "Failed to set up KinD cluster"
                exit 1
            fi

            # Get Kiali URL from the LoadBalancer service (same method as hack/run-integration-tests.sh)
            log_info "Getting Kiali URL from LoadBalancer service..."

            # Wait for LoadBalancer to have an ingress IP
            if ! kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' -n istio-system service/kiali --timeout=120s; then
                log_error "Timed out waiting for Kiali LoadBalancer to be ready"
                exit 1
            fi

            local kiali_ip
            kiali_ip=$(kubectl get svc kiali -n istio-system -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

            if [[ -z "$kiali_ip" ]]; then
                log_error "Failed to get Kiali LoadBalancer IP"
                exit 1
            fi

            CYPRESS_BASE_URL="http://${kiali_ip}/kiali"
            export CYPRESS_BASE_URL
            log_success "Kiali URL set to: $CYPRESS_BASE_URL"

            # Verify Kiali is accessible (check health endpoint)
            log_info "Waiting for Kiali server to respond to health checks..."
            local start_time=$(date +%s)
            local end_time=$((start_time + 30))
            while true; do
                if curl -k -s --fail "${CYPRESS_BASE_URL}/healthz" > /dev/null 2>&1; then
                    log_success "Kiali is now accessible"
                    return 0
                fi
                local now=$(date +%s)
                if [[ "$now" -gt "$end_time" ]]; then
                    log_error "Kiali did not become accessible after waiting"
                    exit 1
                fi
                sleep 1
            done
            ;;
        2)
            log_info "Using local Kiali instance at http://localhost:3001"
            CYPRESS_BASE_URL="http://localhost:3001"
            export CYPRESS_BASE_URL

            log_warning "Make sure Kiali backend is running with 'make run-backend'"
            read -p "Press Enter when ready to continue..."

            # Verify it's accessible now
            if ! curl -s --connect-timeout 3 "${CYPRESS_BASE_URL}/api/status" > /dev/null 2>&1; then
                log_error "Still cannot reach Kiali at $CYPRESS_BASE_URL"
                log_error "Please start Kiali backend and try again"
                exit 1
            fi

            log_success "Kiali is accessible at $CYPRESS_BASE_URL"
            ;;
        3)
            read -p "Enter the Kiali URL (e.g., http://kiali.example.com): " custom_url
            CYPRESS_BASE_URL="$custom_url"
            export CYPRESS_BASE_URL

            log_info "Testing connection to $CYPRESS_BASE_URL..."
            if ! curl -s --connect-timeout 5 "${CYPRESS_BASE_URL}/api/status" > /dev/null 2>&1; then
                log_error "Cannot reach Kiali at $CYPRESS_BASE_URL"
                read -p "Continue anyway? (y/n): " continue_choice
                if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
                    exit 1
                fi
            else
                log_success "Kiali is accessible at $CYPRESS_BASE_URL"
            fi
            ;;
        4)
            log_warning "Skipping Kiali connectivity check"
            log_warning "Tests may fail if Kiali is not running"
            ;;
        *)
            log_error "Invalid choice: $choice"
            exit 1
            ;;
    esac
}

# Validate prerequisites
validate_prerequisites() {
    log_section "Validating Prerequisites"

    # Check if we're in the right directory
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        log_error "Frontend directory not found: $FRONTEND_DIR"
        log_error "This script must be run from the Kiali repository"
        exit 1
    fi

    # Check for node
    if ! command -v node &> /dev/null; then
        log_error "node is not installed or not in PATH"
        log_error "Please install Node.js >= 24.0.0"
        exit 1
    fi

    # Check for yarn
    if ! command -v yarn &> /dev/null; then
        log_error "yarn is not installed or not in PATH"
        log_error "Please install yarn package manager"
        exit 1
    fi

    # Check for curl (needed for Kiali connectivity check)
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed or not in PATH"
        log_error "Please install curl"
        exit 1
    fi

    # Check if Cypress is installed
    if [[ ! -d "$FRONTEND_DIR/node_modules/cypress" ]]; then
        log_error "Cypress is not installed"
        log_error "Run 'cd frontend && yarn install' to install dependencies"
        exit 1
    fi

    log_success "All prerequisites validated"
}

# Setup output directory
setup_output_directory() {
    log_section "Setting Up Output Directory"

    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/screenshots"
    mkdir -p "$OUTPUT_DIR/videos"
    mkdir -p "$OUTPUT_DIR/logs"

    log_success "Output directory created: $OUTPUT_DIR"
}

# Determine test specification type and build Cypress command
build_cypress_command() {
    log_section "Building Cypress Command"

    # Use npx to run cypress directly to avoid yarn script issues
    local cypress_cmd="npx cypress run"

    # Add browser
    cypress_cmd="$cypress_cmd --browser $CYPRESS_BROWSER"

    # Add headed/headless
    if [[ "$CYPRESS_HEADED" == "true" ]]; then
        cypress_cmd="$cypress_cmd --headed"
    fi

    # Add base URL
    cypress_cmd="$cypress_cmd --config baseUrl=$CYPRESS_BASE_URL"

    # Add video configuration
    if [[ "$CYPRESS_VIDEO" == "true" ]]; then
        cypress_cmd="$cypress_cmd --config video=true,videosFolder=$OUTPUT_DIR/videos"
    else
        cypress_cmd="$cypress_cmd --config video=false"
    fi

    # Add screenshots configuration
    if [[ "${CYPRESS_SCREENSHOTS:-true}" != "false" ]]; then
        cypress_cmd="$cypress_cmd --config screenshotsFolder=$OUTPUT_DIR/screenshots"
    fi

    # Add custom config file if specified
    if [[ -n "$CYPRESS_CONFIG_FILE" ]]; then
        cypress_cmd="$cypress_cmd --config-file $CYPRESS_CONFIG_FILE"
    fi

    # Determine if test spec is a tag or file
    if [[ "$TEST_SPEC" == "@selected" ]] || [[ "$USE_SELECTED" == "true" ]]; then
        # Use @selected tag - run all feature files with selected scenarios
        cypress_cmd="$cypress_cmd -e TAGS=\"@selected\""
        log_info "Running tests with @selected tag"
    elif [[ "$TEST_SPEC" =~ ^@ ]] || [[ -n "$TAGS" ]]; then
        # It's a tag
        local tag_value="${TAGS:-$TEST_SPEC}"
        cypress_cmd="$cypress_cmd -e TAGS=\"$tag_value\""
        log_info "Running tests with tag: $tag_value"
    elif [[ -f "$FRONTEND_DIR/cypress/integration/$TEST_SPEC" ]]; then
        # It's a file path
        cypress_cmd="$cypress_cmd --spec cypress/integration/$TEST_SPEC"
        log_info "Running test file: $TEST_SPEC"
    elif [[ "$TEST_SPEC" =~ \.feature$ ]]; then
        # Looks like a feature file path
        cypress_cmd="$cypress_cmd --spec cypress/integration/**/$TEST_SPEC"
        log_info "Running feature file: $TEST_SPEC"
    else
        # Try as a tag first
        cypress_cmd="$cypress_cmd -e TAGS=\"@$TEST_SPEC\""
        log_info "Attempting to run as tag: @$TEST_SPEC"
    fi

    # Add custom environment variables
    if [[ -n "$CYPRESS_ENV" ]]; then
        cypress_cmd="$cypress_cmd -e $CYPRESS_ENV"
    fi

    # Add existing environment variables
    if [[ -n "$CYPRESS_USERNAME" ]]; then
        cypress_cmd="$cypress_cmd -e USERNAME=$CYPRESS_USERNAME"
    fi
    if [[ -n "$CYPRESS_PASSWD" ]]; then
        cypress_cmd="$cypress_cmd -e PASSWD=$CYPRESS_PASSWD"
    fi
    if [[ -n "$CYPRESS_AUTH_PROVIDER" ]]; then
        cypress_cmd="$cypress_cmd -e AUTH_PROVIDER=$CYPRESS_AUTH_PROVIDER"
    fi
    if [[ -n "$CYPRESS_ALLOW_INSECURE_KIALI_API" ]]; then
        cypress_cmd="$cypress_cmd -e ALLOW_INSECURE_KIALI_API=$CYPRESS_ALLOW_INSECURE_KIALI_API"
    fi

    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_info "Cypress command: $cypress_cmd"
    fi

    echo "$cypress_cmd"
}

# Run Cypress tests
run_tests() {
    log_section "Running Cypress Tests"

    cd "$FRONTEND_DIR"

    local cypress_cmd=$(build_cypress_command)
    local exit_code=0

    # Run Cypress and capture all output
    log_info "Executing tests..."
    log_info "Test spec: $TEST_SPEC"
    log_info "Browser: $CYPRESS_BROWSER"
    log_info "Base URL: $CYPRESS_BASE_URL"
    log_info "Video: $CYPRESS_VIDEO"

    echo ""

    # Run tests and capture output
    if [[ "$DEBUG_MODE" == "true" ]]; then
        set -x
    fi

    # Run Cypress with full output capture
    # Strip ANSI color codes to avoid eval issues
    eval "$cypress_cmd" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tee "$OUTPUT_DIR/logs/cypress-log.txt" || exit_code=$?

    if [[ "$DEBUG_MODE" == "true" ]]; then
        set +x
    fi

    cd - > /dev/null

    return $exit_code
}

# Extract stacktraces from Cypress output
extract_stacktraces() {
    log_section "Extracting Stacktraces"

    local cypress_log="$OUTPUT_DIR/logs/cypress-log.txt"
    local stacktrace_file="$OUTPUT_DIR/stacktraces.txt"

    if [[ ! -f "$cypress_log" ]]; then
        log_warning "Cypress log file not found, skipping stacktrace extraction"
        return
    fi

    # Extract error messages and stacktraces
    {
        echo "========================================="
        echo "CYPRESS TEST FAILURES - FULL STACKTRACES"
        echo "========================================="
        echo ""
        echo "Generated: $(date)"
        echo "Test Spec: $TEST_SPEC"
        echo ""

        # Look for error patterns in Cypress output
        grep -A 50 "Error:" "$cypress_log" 2>/dev/null || true
        grep -A 50 "AssertionError:" "$cypress_log" 2>/dev/null || true
        grep -A 50 "CypressError:" "$cypress_log" 2>/dev/null || true
        grep -A 30 "at Context" "$cypress_log" 2>/dev/null || true

    } > "$stacktrace_file"

    if [[ -s "$stacktrace_file" ]]; then
        log_success "Stacktraces extracted to: $stacktrace_file"
    else
        log_info "No errors found (all tests may have passed)"
    fi
}

# Generate test report
generate_report() {
    log_section "Generating Test Report"

    local report_file="$OUTPUT_DIR/test-report.txt"
    local cypress_log="$OUTPUT_DIR/logs/cypress-log.txt"

    {
        echo "========================================="
        echo "CYPRESS TEST REPORT"
        echo "========================================="
        echo ""
        echo "Generated: $(date)"
        echo "Test Spec: $TEST_SPEC"
        echo "Browser: $CYPRESS_BROWSER"
        echo "Base URL: $CYPRESS_BASE_URL"
        echo "Video Recording: $CYPRESS_VIDEO"
        echo ""
        echo "========================================="
        echo "TEST RESULTS SUMMARY"
        echo "========================================="
        echo ""

        # Extract summary from Cypress output
        if [[ -f "$cypress_log" ]]; then
            # Look for test results
            grep -E "(passing|failing|pending)" "$cypress_log" 2>/dev/null || echo "No summary found in Cypress output"
            echo ""

            # Extract spec file results
            grep -E "✓|✗|○" "$cypress_log" 2>/dev/null || true
        fi

        echo ""
        echo "========================================="
        echo "ARTIFACTS"
        echo "========================================="
        echo ""
        echo "Output Directory: $OUTPUT_DIR"
        echo "Cypress Log: $OUTPUT_DIR/logs/cypress-log.txt"
        echo "Stacktraces: $OUTPUT_DIR/stacktraces.txt"

        if [[ -d "$OUTPUT_DIR/screenshots" ]]; then
            local screenshot_count=$(find "$OUTPUT_DIR/screenshots" -type f 2>/dev/null | wc -l)
            echo "Screenshots: $screenshot_count files in $OUTPUT_DIR/screenshots/"
        fi

        if [[ -d "$OUTPUT_DIR/videos" && "$CYPRESS_VIDEO" == "true" ]]; then
            local video_count=$(find "$OUTPUT_DIR/videos" -type f 2>/dev/null | wc -l)
            echo "Videos: $video_count files in $OUTPUT_DIR/videos/"
        fi

        echo ""
        echo "========================================="
        echo "END OF REPORT"
        echo "========================================="

    } > "$report_file"

    log_success "Test report generated: $report_file"
}

# Display results summary
display_summary() {
    log_section "Test Execution Summary"

    local exit_code=$1
    local report_file="$OUTPUT_DIR/test-report.txt"

    # Display the report
    if [[ -f "$report_file" ]]; then
        cat "$report_file"
    fi

    echo ""

    if [[ $exit_code -eq 0 ]]; then
        log_success "All tests passed!"
    else
        log_error "Some tests failed (exit code: $exit_code)"
        echo ""
        log_info "Check the following for details:"
        log_info "  - Full log: $OUTPUT_DIR/logs/cypress-log.txt"
        log_info "  - Stacktraces: $OUTPUT_DIR/stacktraces.txt"
        log_info "  - Screenshots: $OUTPUT_DIR/screenshots/"
        if [[ "$CYPRESS_VIDEO" == "true" ]]; then
            log_info "  - Videos: $OUTPUT_DIR/videos/"
        fi
    fi

    echo ""
    log_info "Complete test artifacts saved to: $OUTPUT_DIR"
}

# Main execution
main() {
    parse_arguments "$@"
    validate_prerequisites
    check_kiali_instance
    setup_output_directory

    local exit_code=0
    run_tests || exit_code=$?

    extract_stacktraces
    generate_report
    display_summary $exit_code

    exit $exit_code
}

# Execute main function
main "$@"
