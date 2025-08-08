#!/bin/bash
# Script to test dotfiles installation in Docker

set -e

# Parse arguments
CI_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ci)
            CI_MODE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --ci    Run in CI mode (automated testing)"
            echo "  --help  Show this help message"
            echo ""
            echo "Interactive mode: ./docker-test.sh"
            echo "CI mode: ./docker-test.sh --ci"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "🐳 Building Docker image for testing..."
docker build -f Dockerfile -t dotfiles-test:latest .

if [[ "$CI_MODE" == "true" ]]; then
    echo ""
    echo "🚀 Running automated CI tests..."
    echo "================================"
    
    docker run --rm \
        -v "$(pwd):/home/testuser/dev/dotfiles:ro" \
        -e CI=true \
        -e DEBIAN_FRONTEND=noninteractive \
        dotfiles-test:latest \
        bash -c "
            set -e
            echo '📂 Setting up test environment...'
            cp -r /home/testuser/dev/dotfiles /tmp/dotfiles
            cd /tmp/dotfiles
            
            echo ''
            echo '⚡ Running full installation (includes language runtimes)...'
            echo '   This will install Node.js, Python, Go, and Bun'
            ./install.sh --ci
            
            echo ''
            echo '🔗 Setting up aliases...'
            ./setup-aliases.sh
            
            echo ''
            echo '🧪 Running tests...'
            export PATH=\"\$HOME/.asdf/bin:\$HOME/.asdf/shims:\$HOME/.bun/bin:\$HOME/.local/bin:\$HOME/go/bin:\$PATH\"
            ./test.sh
            
            echo ''
            echo '✅ CI tests completed!'
        "
    
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        echo ""
        echo "✅ All CI tests passed!"
    else
        echo ""
        echo "❌ CI tests failed (exit code: $EXIT_CODE)"
        exit $EXIT_CODE
    fi
else
    echo ""
    echo "🚀 Starting interactive container..."
    echo "This will drop you into a bash shell where you can test the installation."
    echo ""
    echo "To test the installation, run:"
    echo "  cd /home/testuser/dev/dotfiles"
    echo "  ./install.sh [--quick]"
    echo "  fish"
    echo "  ./test.sh [--minimal]"
    echo ""
    
    docker run -it --rm \
        -v "$(pwd):/home/testuser/dev/dotfiles:ro" \
        --name dotfiles-test-container \
        dotfiles-test:latest
fi