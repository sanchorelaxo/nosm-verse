#!/bin/bash
# Ariadne Development Stop Script
# Stops OpenSimulator and Ariadne4j processes

echo "=== Stopping Ariadne Development Environment ==="

# Stop Ariadne4j
if pkill -f "ariadne4j-2.0.0.jar" 2>/dev/null; then
    echo "  Ariadne4j stopped ✓"
else
    echo "  Ariadne4j was not running"
fi

# Stop OpenSimulator
if pkill -f "OpenSim.dll" 2>/dev/null; then
    echo "  OpenSimulator stopped ✓"
else
    echo "  OpenSimulator was not running"
fi

echo ""
echo "=== Shutdown Complete ==="
