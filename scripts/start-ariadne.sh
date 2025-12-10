#!/bin/bash
# Ariadne Development Startup Script
# Kills any existing processes and starts both OpenSimulator and Ariadne4j

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARIADNE_DIR="$PROJECT_ROOT/VERSE/src/ariadne4j"
OPENSIM_DIR="$HOME/opensimulator/bin"

echo "=== Ariadne Development Environment Startup ==="
echo "Project root: $PROJECT_ROOT"
echo ""

# Kill existing processes
echo "Stopping existing processes..."
pkill -f "ariadne4j-2.0.0.jar" 2>/dev/null && echo "  Killed Ariadne4j" || echo "  Ariadne4j not running"
pkill -f "OpenSim.dll" 2>/dev/null && echo "  Killed OpenSimulator" || echo "  OpenSimulator not running"
sleep 2

# Verify MongoDB is running
echo ""
echo "Checking MongoDB..."
if systemctl is-active --quiet mongod; then
    echo "  MongoDB is running"
else
    echo "  Starting MongoDB..."
    sudo systemctl start mongod
    sleep 2
fi

# Start Ariadne4j
echo ""
echo "Starting Ariadne4j..."
cd "$ARIADNE_DIR"
nohup java -jar target/ariadne4j-2.0.0.jar > logs/ariadne-console.log 2>&1 &
ARIADNE_PID=$!
echo "  Ariadne4j started (PID: $ARIADNE_PID)"
sleep 3

# Verify Ariadne4j is running
if curl -s "http://localhost:8080/ariadne/api/node/1?sessionId=test" > /dev/null 2>&1; then
    echo "  Ariadne4j API responding ✓"
else
    echo "  Warning: Ariadne4j API not responding yet (may still be starting)"
fi

# Start OpenSimulator
echo ""
echo "Starting OpenSimulator..."
cd "$OPENSIM_DIR"
echo "$(date '+%F %T') - Starting OpenSimulator with REST console (-console=rest)" >> opensim-console.log
nohup dotnet OpenSim.dll -console=rest >> opensim-console.log 2>&1 &
OPENSIM_PID=$!
echo "  OpenSimulator started (PID: $OPENSIM_PID)"
sleep 5

# Verify OpenSimulator is running
if curl -s "http://localhost:9000/simstatus/" 2>/dev/null | grep -q "OK"; then
    echo "  OpenSimulator responding ✓"
else
    echo "  Warning: OpenSimulator not responding yet (may still be starting)"
fi

echo ""
echo "=== Startup Complete ==="
echo "Ariadne4j:    http://localhost:8080/ariadne"
echo "OpenSimulator: http://localhost:9000"
echo ""
echo "Logs:"
echo "  Ariadne4j:    $ARIADNE_DIR/logs/ariadne-console.log"
echo "  OpenSimulator: $OPENSIM_DIR/opensim-console.log"
echo ""
echo "To stop: ./scripts/stop-ariadne.sh"
