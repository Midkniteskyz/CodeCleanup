#!/usr/bin/env python3
"""
Network Connectivity Checker - Enhanced Version
A comprehensive tool for testing network connectivity via ping and port scanning.
"""

import subprocess
import socket
import argparse
import sys
import platform
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Tuple, Optional

class NetworkChecker:
    def __init__(self, timeout: int = 3, max_workers: int = 10):
        self.timeout = timeout
        self.max_workers = max_workers
        self.os_type = platform.system().lower()
    
    def ping_host(self, host: str, count: int = 4) -> dict:
        """
        Ping a host and return structured results.
        
        Args:
            host: Hostname or IP address to ping
            count: Number of ping packets to send
            
        Returns:
            Dictionary with ping results and statistics
        """
        try:
            # Cross-platform ping command
            if self.os_type == "windows":
                cmd = ["ping", "-n", str(count), host]
            else:
                cmd = ["ping", "-c", str(count), host]
            
            start_time = time.time()
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                timeout=self.timeout * count
            )
            end_time = time.time()
            
            success = result.returncode == 0
            
            return {
                "host": host,
                "success": success,
                "output": result.stdout.strip(),
                "error": result.stderr.strip() if result.stderr else None,
                "duration": round(end_time - start_time, 2),
                "return_code": result.returncode
            }
            
        except subprocess.TimeoutExpired:
            return {
                "host": host,
                "success": False,
                "output": "",
                "error": f"Ping timed out after {self.timeout * count} seconds",
                "duration": self.timeout * count,
                "return_code": -1
            }
        except Exception as e:
            return {
                "host": host,
                "success": False,
                "output": "",
                "error": f"Ping error: {str(e)}",
                "duration": 0,
                "return_code": -1
            }
    
    def check_port(self, host: str, port: int) -> dict:
        """
        Check if a specific port is open on a host.
        
        Args:
            host: Hostname or IP address
            port: Port number to check
            
        Returns:
            Dictionary with port check results
        """
        try:
            start_time = time.time()
            with socket.create_connection((host, port), timeout=self.timeout):
                end_time = time.time()
                return {
                    "host": host,
                    "port": port,
                    "open": True,
                    "error": None,
                    "response_time": round((end_time - start_time) * 1000, 2)  # ms
                }
        except socket.timeout:
            return {
                "host": host,
                "port": port,
                "open": False,
                "error": "Connection timed out",
                "response_time": self.timeout * 1000
            }
        except ConnectionRefusedError:
            return {
                "host": host,
                "port": port,
                "open": False,
                "error": "Connection refused",
                "response_time": 0
            }
        except socket.gaierror as e:
            return {
                "host": host,
                "port": port,
                "open": False,
                "error": f"DNS resolution failed: {str(e)}",
                "response_time": 0
            }
        except Exception as e:
            return {
                "host": host,
                "port": port,
                "open": False,
                "error": str(e),
                "response_time": 0
            }
    
    def scan_ports_parallel(self, host: str, ports: List[int]) -> List[dict]:
        """
        Scan multiple ports on a host in parallel for faster execution.
        
        Args:
            host: Target hostname or IP
            ports: List of port numbers to scan
            
        Returns:
            List of port check results
        """
        results = []
        with ThreadPoolExecutor(max_workers=min(self.max_workers, len(ports))) as executor:
            future_to_port = {
                executor.submit(self.check_port, host, port): port 
                for port in ports
            }
            
            for future in as_completed(future_to_port):
                results.append(future.result())
        
        # Sort results by port number
        return sorted(results, key=lambda x: x['port'])
    
    def format_ping_results(self, ping_result: dict) -> str:
        """Format ping results for display."""
        if ping_result["success"]:
            status = "✓ REACHABLE"
            color = "\033[92m"  # Green
        else:
            status = "✗ UNREACHABLE"
            color = "\033[91m"  # Red
        
        reset = "\033[0m"
        
        output = f"{color}{status}{reset} ({ping_result['duration']}s)"
        
        if ping_result["error"]:
            output += f"\n    Error: {ping_result['error']}"
        
        return output
    
    def format_port_results(self, port_results: List[dict]) -> str:
        """Format port scan results for display."""
        if not port_results:
            return ""
        
        output = []
        open_ports = []
        closed_ports = []
        
        for result in port_results:
            if result["open"]:
                open_ports.append(f"{result['port']} ({result['response_time']}ms)")
            else:
                error_msg = f" - {result['error']}" if result['error'] else ""
                closed_ports.append(f"{result['port']}{error_msg}")
        
        if open_ports:
            output.append(f"    \033[92m✓ OPEN PORTS:\033[0m {', '.join(open_ports)}")
        
        if closed_ports:
            output.append(f"    \033[91m✗ CLOSED PORTS:\033[0m {', '.join(closed_ports)}")
        
        return "\n".join(output)

def parse_port_ranges(port_input: str) -> List[int]:
    """
    Parse port input supporting ranges (e.g., "80,443,8000-8010").
    
    Args:
        port_input: String containing ports and ranges
        
    Returns:
        List of individual port numbers
    """
    ports = []
    for part in port_input.split(','):
        part = part.strip()
        if '-' in part:
            start, end = map(int, part.split('-', 1))
            ports.extend(range(start, end + 1))
        else:
            ports.append(int(part))
    return sorted(set(ports))  # Remove duplicates and sort

def main():
    parser = argparse.ArgumentParser(
        description="Enhanced Network Connectivity Checker - Test ping and port connectivity",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --hosts google.com github.com
  %(prog)s --hosts 192.168.1.1 --ports 80 443 22
  %(prog)s --hosts example.com --port-ranges "80,443,8000-8010"
  %(prog)s --hosts server.local --ports 22 --timeout 5 --parallel
        """
    )

    parser.add_argument(
        "--hosts",
        nargs="+",
        type=str,
        help="List of hosts to check (hostnames or IP addresses)",
        required=True
    )

    parser.add_argument(
        "--ports",
        nargs="*",
        type=int,
        help="List of individual ports to check",
        default=[]
    )
    
    parser.add_argument(
        "--port-ranges",
        type=str,
        help="Port ranges to check (e.g., '80,443,8000-8010')",
        default=""
    )

    parser.add_argument(
        "--timeout",
        type=int,
        default=3,
        help="Timeout in seconds for connections (default: 3)"
    )
    
    parser.add_argument(
        "--ping-count",
        type=int,
        default=4,
        help="Number of ping packets to send (default: 4)"
    )
    
    parser.add_argument(
        "--parallel",
        action="store_true",
        help="Enable parallel port scanning for faster execution"
    )
    
    parser.add_argument(
        "--no-ping",
        action="store_true",
        help="Skip ping tests, only check ports"
    )
    
    parser.add_argument(
        "--workers",
        type=int,
        default=10,
        help="Number of parallel workers for port scanning (default: 10)"
    )

    args = parser.parse_args()

    # Combine individual ports and port ranges
    all_ports = args.ports.copy()
    if args.port_ranges:
        try:
            range_ports = parse_port_ranges(args.port_ranges)
            all_ports.extend(range_ports)
        except ValueError as e:
            print(f"Error parsing port ranges: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Remove duplicates and sort
    all_ports = sorted(set(all_ports))

    # Initialize checker
    checker = NetworkChecker(timeout=args.timeout, max_workers=args.workers)

    print(f"Network Connectivity Checker")
    print(f"{'=' * 60}")
    print(f"Timeout: {args.timeout}s | Ping Count: {args.ping_count}")
    if all_ports:
        print(f"Ports to check: {', '.join(map(str, all_ports))}")
    print(f"Parallel scanning: {'Enabled' if args.parallel else 'Disabled'}")
    print()

    # Process each host
    for i, host in enumerate(args.hosts):
        if i > 0:
            print()  # Add spacing between hosts
        
        print(f"🔍 Checking: {host}")
        print("-" * 40)
        
        # Ping test
        if not args.no_ping:
            print("📡 Ping Test:")
            ping_result = checker.ping_host(host, args.ping_count)
            print(f"    {checker.format_ping_results(ping_result)}")
        
        # Port checks
        if all_ports:
            print("🔌 Port Scan:")
            
            if args.parallel and len(all_ports) > 1:
                port_results = checker.scan_ports_parallel(host, all_ports)
            else:
                port_results = []
                for port in all_ports:
                    port_results.append(checker.check_port(host, port))
            
            formatted_results = checker.format_port_results(port_results)
            if formatted_results:
                print(formatted_results)
            else:
                print("    No port results available")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}", file=sys.stderr)
        sys.exit(1)