#!/bin/bash
#
# Regression Testing Skill - OpenShift
#
# Automates the execution of Kiali regression tests on a remote OpenShift cluster.
# This script handles environment setup, test execution, log collection, and reporting.
#
# Usage: regression-ocp.sh [OPTIONS]
#
# Options:
#   --dry-run           Validate setup only, don't run tests
#   --test-group TAG    Cypress test group tag (default: "not @multi-cluster")
#   --with-video        Enable video recording (disabled by default for faster execution)
#   --no-stern          Disable stern logging
#   --skip-install      Skip installation, run tests only
#   --help              Show this help message
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../" && pwd)"
DRY_RUN="${DRY_RUN:-false}"
TEST_GROUP="${TEST_GROUP:-not @multi-cluster}"
CYPRESS_VIDEO="${CYPRESS_VIDEO:-false}"
CYPRESS_STERN="${CYPRESS_STERN:-true}"
SKIP_INSTALL="${SKIP_INSTALL:-false}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --test-group)
      TEST_GROUP="$2"
      shift 2
      ;;
    --with-video)
      CYPRESS_VIDEO=true
      shift
      ;;
    --no-stern)
      CYPRESS_STERN=false
      shift
      ;;
    --skip-install)
      SKIP_INSTALL=true
      shift
      ;;
    --help)
      grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}$1${NC}"
  echo -e "${GREEN}========================================${NC}"
}

# Check prerequisites
check_prerequisites() {
  log_section "Step 1: Checking Prerequisites"

  local missing_deps=()

  # Check for oc CLI
  if ! command -v oc &> /dev/null; then
    missing_deps+=("oc (OpenShift CLI)")
  fi

  # Check for yarn
  if ! command -v yarn &> /dev/null; then
    missing_deps+=("yarn (Node.js package manager)")
  fi

  # Check for node
  if ! command -v node &> /dev/null; then
    missing_deps+=("node (Node.js)")
  fi

  # Check for stern (optional, warn only)
  if [[ "${CYPRESS_STERN}" == "true" ]] && ! command -v stern &> /dev/null; then
    log_warning "stern is not installed. Stern logging will be disabled."
    CYPRESS_STERN=false
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Missing required dependencies:"
    for dep in "${missing_deps[@]}"; do
      echo "  - $dep"
    done
    exit 1
  fi

  log_success "All prerequisites met"
}

# Validate cluster access
validate_cluster_access() {
  log_section "Step 2: Validating OpenShift Cluster Access"

  if ! oc whoami &> /dev/null; then
    log_error "Not logged into an OpenShift cluster"
    echo ""
    echo "Please log in using one of:"
    echo "  oc login <cluster-url>"
    echo "  or let the installation script start CRC"
    exit 1
  fi

  local username
  username=$(oc whoami)
  log_success "Logged in as: ${username}"

  # Get cluster info
  local cluster_url
  cluster_url=$(oc whoami --show-server)
  log_info "Cluster URL: ${cluster_url}"

  # Check if user has cluster-admin (warning only)
  if ! oc auth can-i '*' '*' --all-namespaces &> /dev/null; then
    log_warning "You may not have cluster-admin privileges. Some operations might fail."
  fi
}

# Install components
install_components() {
  if [[ "${SKIP_INSTALL}" == "true" ]]; then
    log_section "Step 3: Skipping Installation (--skip-install)"
    return
  fi

  log_section "Step 3: Installing Istio, Kiali, and OSSMC"

  local install_script="${REPO_ROOT}/hack/install-kiali-ossmc-openshift.sh"

  if [[ ! -f "${install_script}" ]]; then
    log_error "Installation script not found: ${install_script}"
    exit 1
  fi

  log_info "Running: ${install_script}"

  if ! bash "${install_script}"; then
    log_error "Installation failed"
    echo ""
    echo "Check the operator logs:"
    echo "  oc logs -n openshift-operators -l app.kubernetes.io/name=kiali-operator --tail=100"
    exit 1
  fi

  log_success "Installation complete"
}

# Configure test environment
configure_test_environment() {
  log_section "Step 4: Configuring Test Environment"

  # Get Kiali URL
  export CYPRESS_BASE_URL
  CYPRESS_BASE_URL=$(oc get route -n istio-system -l app.kubernetes.io/name=kiali -o jsonpath='https://{..spec.host}/' 2>/dev/null)

  if [[ -z "${CYPRESS_BASE_URL}" ]]; then
    log_error "Could not find Kiali route in istio-system namespace"
    echo ""
    echo "Check if Kiali is deployed:"
    echo "  oc get route -n istio-system"
    exit 1
  fi

  log_info "Kiali URL: ${CYPRESS_BASE_URL}"

  # Set authentication variables (use environment or defaults)
  export CYPRESS_USERNAME="${CYPRESS_USERNAME:-kubeadmin}"
  export CYPRESS_AUTH_PROVIDER="${CYPRESS_AUTH_PROVIDER:-kube:admin}"

  # Prompt for password if not set
  if [[ -z "${CYPRESS_PASSWD}" ]]; then
    log_info "OpenShift password required for user: ${CYPRESS_USERNAME}"
    echo -n "Password: "
    read -s CYPRESS_PASSWD
    echo ""
    export CYPRESS_PASSWD
  fi

  # Set test configuration
  export TEST_GROUP
  export CYPRESS_VIDEO
  export CYPRESS_STERN
  export CYPRESS_ALLOW_INSECURE_KIALI_API="${CYPRESS_ALLOW_INSECURE_KIALI_API:-true}"

  log_success "Environment configured"
  log_info "Test group: ${TEST_GROUP}"
  log_info "Video recording: ${CYPRESS_VIDEO}"
  log_info "Stern logging: ${CYPRESS_STERN}"
}

# Run tests
run_tests() {
  if [[ "${DRY_RUN}" == "true" ]]; then
    log_section "Step 5: Dry Run - Tests Skipped"
    log_success "Dry run complete. Use without --dry-run to execute tests."
    return 0
  fi

  log_section "Step 5: Executing Cypress Tests"

  cd "${REPO_ROOT}/frontend"

  log_info "Running: yarn cypress:run:test-group:junit"
  log_info "This may take 10-30 minutes depending on the test group..."

  # Run tests and capture exit code
  local test_exit_code=0
  if ! yarn cypress:run:test-group:junit; then
    test_exit_code=$?
    log_warning "Tests completed with failures (exit code: ${test_exit_code})"
  else
    log_success "All tests passed!"
  fi

  cd "${REPO_ROOT}"

  return ${test_exit_code}
}

# Collect logs
collect_logs() {
  local test_failed=$1

  if [[ ${test_failed} -eq 0 ]]; then
    log_section "Step 6: Test Results - All Passed"
    return
  fi

  log_section "Step 6: Collecting Logs (Tests Failed)"

  local log_dir="${REPO_ROOT}/regression-logs-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${log_dir}"

  log_info "Collecting logs to: ${log_dir}"

  # Kiali logs
  if oc get pods -n istio-system -l app.kubernetes.io/name=kiali &> /dev/null; then
    log_info "Collecting Kiali logs..."
    oc logs -n istio-system -l app.kubernetes.io/name=kiali --tail=1000 > "${log_dir}/kiali-logs.txt" 2>&1 || true
  fi

  # OSSMC logs
  if oc get pods -n ossmconsole -l app.kubernetes.io/name=ossmconsole &> /dev/null; then
    log_info "Collecting OSSMC logs..."
    oc logs -n ossmconsole -l app.kubernetes.io/name=ossmconsole --tail=1000 > "${log_dir}/ossmc-logs.txt" 2>&1 || true
  fi

  # Istio logs
  if oc get pods -n istio-system -l app=istiod &> /dev/null; then
    log_info "Collecting Istio logs..."
    oc logs -n istio-system -l app=istiod --tail=1000 > "${log_dir}/istiod-logs.txt" 2>&1 || true
  fi

  # Copy Cypress artifacts
  if [[ -d "${REPO_ROOT}/frontend/cypress/screenshots" ]]; then
    log_info "Copying Cypress screenshots..."
    cp -r "${REPO_ROOT}/frontend/cypress/screenshots" "${log_dir}/" 2>&1 || true
  fi

  if [[ -d "${REPO_ROOT}/frontend/cypress/videos" ]] && [[ "${CYPRESS_VIDEO}" == "true" ]]; then
    log_info "Copying Cypress videos..."
    cp -r "${REPO_ROOT}/frontend/cypress/videos" "${log_dir}/" 2>&1 || true
  fi

  # Get environment info
  log_info "Collecting environment information..."
  {
    echo "OpenShift Version:"
    oc version
    echo ""
    echo "Istio Version:"
    oc get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].spec.containers[0].image}' || echo "N/A"
    echo ""
    echo "Kiali Version:"
    oc get kiali -n istio-system kiali -o jsonpath='{.spec.version}' 2>/dev/null || \
      oc get pods -n istio-system -l app.kubernetes.io/name=kiali -o jsonpath='{.items[0].spec.containers[0].image}' || echo "N/A"
    echo ""
  } > "${log_dir}/environment-info.txt" 2>&1

  log_success "Logs collected in: ${log_dir}"

  export REGRESSION_LOG_DIR="${log_dir}"
}

# Generate summary
generate_summary() {
  local test_exit_code=$1

  log_section "Regression Test Summary"

  # Parse test results from Cypress output
  local results_file="${REPO_ROOT}/frontend/cypress/results"

  echo "Test Group: ${TEST_GROUP}"
  echo "Exit Code: ${test_exit_code}"

  if [[ ${test_exit_code} -eq 0 ]]; then
    echo -e "${GREEN}Status: PASSED${NC}"
  else
    echo -e "${RED}Status: FAILED${NC}"
  fi

  echo ""
  echo "Environment:"
  if [[ -f "${REGRESSION_LOG_DIR}/environment-info.txt" ]]; then
    cat "${REGRESSION_LOG_DIR}/environment-info.txt"
  else
    echo "  OpenShift: $(oc version --client | head -n1)"
    echo "  Kiali URL: ${CYPRESS_BASE_URL}"
  fi

  echo ""
  if [[ ${test_exit_code} -ne 0 ]]; then
    echo "Collected Artifacts:"
    echo "  - Logs directory: ${REGRESSION_LOG_DIR}"
    if [[ -d "${REGRESSION_LOG_DIR}/screenshots" ]]; then
      local screenshot_count
      screenshot_count=$(find "${REGRESSION_LOG_DIR}/screenshots" -type f 2>/dev/null | wc -l)
      echo "  - Screenshots: ${screenshot_count} files"
    fi
    if [[ -d "${REGRESSION_LOG_DIR}/videos" ]]; then
      local video_count
      video_count=$(find "${REGRESSION_LOG_DIR}/videos" -type f 2>/dev/null | wc -l)
      echo "  - Videos: ${video_count} files"
    fi
    echo ""
    echo "Next Steps:"
    echo "  1. Review screenshots in: ${REGRESSION_LOG_DIR}/screenshots/"
    echo "  2. Review logs in: ${REGRESSION_LOG_DIR}/"
    echo "  3. Create a GitHub issue with the failure details"
    echo ""
    echo "To create an issue:"
    echo "  gh issue create --title \"Regression Test Failure - $(date +%Y-%m-%d)\" --body-file <(cat regression-report.md)"
  else
    echo "All tests passed! No regressions detected."
  fi

  echo ""
  log_section "Complete"
}

# Main execution
main() {
  log_section "OpenShift Regression Testing"

  check_prerequisites
  validate_cluster_access
  install_components
  configure_test_environment

  local test_exit_code=0
  run_tests || test_exit_code=$?

  collect_logs ${test_exit_code}
  generate_summary ${test_exit_code}

  exit ${test_exit_code}
}

# Run main function
main "$@"
