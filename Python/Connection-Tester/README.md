# Network Connectivity Checker - Usage Instructions

## Overview
The Network Connectivity Checker is a comprehensive tool for testing network connectivity through ping tests and port scanning. It can check multiple hosts simultaneously and supports various scanning modes for different use cases.

## Basic Usage

### Simple Ping Test
Check if hosts are reachable:
```bash
python pingport_cli.py --hosts google.com github.com
```

### Ping with Port Checking
Test connectivity and check specific ports:
```bash
python pingport_cli.py --hosts example.com --ports 80 443
```

### Multiple Hosts and Ports
Check multiple hosts against multiple ports:
```bash
python pingport_cli.py --hosts server1.com server2.com --ports 22 80 443 3389
```

## Advanced Usage Examples

### Port Range Scanning
Scan a range of ports efficiently:
```bash
# Scan ports 8000-8010 plus some common ports
python pingport_cli.py --hosts myserver.com --port-ranges "80,443,8000-8010"

# Scan a large range of ports
python pingport_cli.py --hosts target.com --port-ranges "1-1000"

# Combine individual ports with ranges
python pingport_cli.py --hosts server.com --ports 22 3389 --port-ranges "80,443,8000-8005"
```

### Performance Optimizations
Enable parallel scanning for faster results:
```bash
# Enable parallel port scanning
python pingport_cli.py --hosts server.com --port-ranges "1-100" --parallel

# Increase worker threads for even faster scanning
python pingport_cli.py --hosts server.com --port-ranges "1-1000" --parallel --workers 50
```

### Timeout and Timing Options
Customize timeouts for different network conditions:
```bash
# Increase timeout for slow networks
python pingport_cli.py --hosts remote-server.com --ports 80 --timeout 10

# Reduce ping count for faster results
python pingport_cli.py --hosts fast-server.com --ping-count 2

# Skip ping tests entirely (port scanning only)
python pingport_cli.py --hosts server.com --ports 80 443 --no-ping
```

## Real-World Scenarios

### Web Server Health Check
Check if web servers are responding:
```bash
python pingport_cli.py --hosts www.mysite.com api.mysite.com --ports 80 443
```

### Database Connectivity Test
Test database server connectivity:
```bash
python pingport_cli.py --hosts db.company.com --ports 3306 5432 1433 --timeout 5
```

### Network Troubleshooting
Comprehensive network diagnostic:
```bash
python pingport_cli.py --hosts router.local server.local --ports 22 80 443 3389 --parallel --timeout 3
```

### Security Port Scan
Check for open ports on a target system:
```bash
python pingport_cli.py --hosts target-host.com --port-ranges "1-1000" --parallel --workers 20 --no-ping
```

### Remote Desktop Connection Test
Check RDP connectivity:
```bash
python pingport_cli.py --hosts workstation1.domain.com workstation2.domain.com --ports 3389
```

### VPN Endpoint Testing
Test VPN server connectivity:
```bash
python pingport_cli.py --hosts vpn.company.com --ports 1194 443 500 4500
```

## Network-Specific Examples

### Internal Network Scan
Check internal servers:
```bash
python pingport_cli.py --hosts 192.168.1.1 192.168.1.10 192.168.1.20 --ports 22 80 443
```

### Cloud Service Monitoring
Monitor cloud service endpoints:
```bash
python pingport_cli.py --hosts api.amazonaws.com storage.googleapis.com --ports 80 443 --timeout 5
```

### IoT Device Connectivity
Check IoT devices on your network:
```bash
python pingport_cli.py --hosts 192.168.1.100 192.168.1.101 --ports 80 8080 --ping-count 2
```

## Troubleshooting Network Issues

### Slow Network Diagnosis
For networks with high latency:
```bash
python pingport_cli.py --hosts remote-site.com --ports 80 443 --timeout 15 --ping-count 10
```

### Firewall Testing
Test if specific ports are blocked:
```bash
python pingport_cli.py --hosts external-server.com --port-ranges "80,443,8080,8443" --no-ping
```

### Load Balancer Health Check
Check multiple backend servers:
```bash
python pingport_cli.py --hosts backend1.com backend2.com backend3.com --ports 80 443 --parallel
```

## Output Interpretation

### Understanding Results
- **✓ REACHABLE**: Host responds to ping
- **✗ UNREACHABLE**: Host doesn't respond to ping
- **✓ OPEN PORTS**: TCP connection successful
- **✗ CLOSED PORTS**: Connection failed with reason

### Common Error Messages
- **Connection refused**: Port is closed or service not running
- **Connection timed out**: Port filtered by firewall or service unresponsive
- **DNS resolution failed**: Invalid hostname or DNS issues

## Best Practices

### Efficient Scanning
```bash
# For quick checks, use fewer pings
python pingport_cli.py --hosts server.com --ports 80 --ping-count 1

# For thorough testing, increase timeout and pings
python pingport_cli.py --hosts unreliable-server.com --ports 80 --timeout 10 --ping-count 10
```

### Batch Operations
Create a script for regular monitoring:
```bash
#!/bin/bash
# Daily server health check
python pingport_cli.py --hosts server1.com server2.com --ports 80 443 22 --parallel > daily_check.log
```

### Performance Considerations
- Use `--parallel` for scanning many ports
- Increase `--workers` for faster parallel execution
- Use `--no-ping` when only port status matters
- Set appropriate `--timeout` values based on network conditions

## Integration Examples

### Automated Monitoring
```bash
# Check every 5 minutes and log results
while true; do
    python pingport_cli.py --hosts critical-server.com --ports 80 443 >> monitoring.log
    sleep 300
done
```

### CI/CD Pipeline Integration
```bash
# Pre-deployment connectivity check
python pingport_cli.py --hosts staging-server.com --ports 80 443 8080
if [ $? -eq 0 ]; then
    echo "Deployment can proceed"
else
    echo "Connectivity issues detected"
    exit 1
fi
```

## Command Reference

| Option | Description | Example |
|--------|-------------|---------|
| `--hosts` | Target hosts (required) | `--hosts server.com 192.168.1.1` |
| `--ports` | Individual ports | `--ports 80 443 22` |
| `--port-ranges` | Port ranges | `--port-ranges "80,443,8000-8010"` |
| `--timeout` | Connection timeout | `--timeout 5` |
| `--ping-count` | Ping packet count | `--ping-count 2` |
| `--parallel` | Enable parallel scanning | `--parallel` |
| `--workers` | Parallel worker count | `--workers 20` |
| `--no-ping` | Skip ping tests | `--no-ping` |