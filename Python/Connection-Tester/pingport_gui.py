#!/usr/bin/env python3
"""
Network Connectivity Checker - GUI Version
A user-friendly graphical interface for network connectivity testing.
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import subprocess
import socket
import threading
import time
import platform
import json
import csv
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Any
import os
import sys

class NetworkCheckerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Network Connectivity Checker v2.0")
        self.root.geometry("900x700")
        self.root.minsize(800, 600)
        
        # Configure style
        self.setup_styles()
        
        # Variables
        self.is_scanning = False
        self.scan_thread = None
        self.results = []
        self.os_type = platform.system().lower()
        
        # Create GUI
        self.create_widgets()
        
        # Bind events
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
    
    def setup_styles(self):
        """Configure ttk styles for better appearance."""
        style = ttk.Style()
        
        # Configure styles
        style.configure('Title.TLabel', font=('Arial', 12, 'bold'))
        style.configure('Header.TLabel', font=('Arial', 10, 'bold'))
        style.configure('Success.TLabel', foreground='green')
        style.configure('Error.TLabel', foreground='red')
        style.configure('Big.TButton', font=('Arial', 10, 'bold'))
    
    def create_widgets(self):
        """Create and layout all GUI widgets."""
        
        # Main container with padding
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(7, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text="Network Connectivity Checker", style='Title.TLabel')
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        # Hosts input section
        hosts_frame = ttk.LabelFrame(main_frame, text="Target Hosts", padding="10")
        hosts_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        hosts_frame.columnconfigure(1, weight=1)
        
        # Manual host entry
        ttk.Label(hosts_frame, text="Hosts:").grid(row=0, column=0, sticky=tk.W, padx=(0, 5))
        self.hosts_entry = ttk.Entry(hosts_frame, width=50)
        self.hosts_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 10))
        self.hosts_entry.insert(0, "google.com, github.com, 8.8.8.8")
        
        # Host file selection
        ttk.Label(hosts_frame, text="Host File:").grid(row=1, column=0, sticky=tk.W, padx=(0, 5), pady=(10, 0))
        self.host_file_var = tk.StringVar()
        self.host_file_entry = ttk.Entry(hosts_frame, textvariable=self.host_file_var, width=40)
        self.host_file_entry.grid(row=1, column=1, sticky=(tk.W, tk.E), padx=(0, 10), pady=(10, 0))
        
        ttk.Button(hosts_frame, text="Browse", command=self.browse_host_file).grid(row=1, column=2, pady=(10, 0))
        
        # Port configuration section
        ports_frame = ttk.LabelFrame(main_frame, text="Port Configuration", padding="10")
        ports_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        ports_frame.columnconfigure(1, weight=1)
        
        # Port entry
        ttk.Label(ports_frame, text="Ports:").grid(row=0, column=0, sticky=tk.W, padx=(0, 5))
        self.ports_entry = ttk.Entry(ports_frame, width=30)
        self.ports_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 10))
        self.ports_entry.insert(0, "80, 443, 22")
        
        # Port ranges
        ttk.Label(ports_frame, text="Port Ranges:").grid(row=1, column=0, sticky=tk.W, padx=(0, 5), pady=(10, 0))
        self.port_ranges_entry = ttk.Entry(ports_frame, width=30)
        self.port_ranges_entry.grid(row=1, column=1, sticky=(tk.W, tk.E), padx=(0, 10), pady=(10, 0))
        self.port_ranges_entry.insert(0, "8000-8010")
        
        # Options section
        options_frame = ttk.LabelFrame(main_frame, text="Scan Options", padding="10")
        options_frame.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Checkboxes
        self.skip_ping_var = tk.BooleanVar()
        self.parallel_var = tk.BooleanVar(value=True)

        ttk.Checkbutton(options_frame, text="Skip ping tests", variable=self.skip_ping_var).grid(row=0, column=0, sticky=tk.W, padx=(0, 20))
        ttk.Checkbutton(options_frame, text="Parallel scanning", variable=self.parallel_var).grid(row=0, column=1, sticky=tk.W)
        self.traceroute_var = tk.BooleanVar()
        ttk.Checkbutton(options_frame, text="Include traceroute", variable=self.traceroute_var).grid(row=0, column=2, sticky=tk.W, padx=(20, 0))
        
        # Timeout and workers
        ttk.Label(options_frame, text="Timeout (s):").grid(row=1, column=0, sticky=tk.W, pady=(10, 0))
        self.timeout_var = tk.StringVar(value="3")
        timeout_spinbox = ttk.Spinbox(options_frame, from_=1, to=30, width=5, textvariable=self.timeout_var)
        timeout_spinbox.grid(row=1, column=1, sticky=tk.W, padx=(10, 0), pady=(10, 0))
        
        ttk.Label(options_frame, text="Workers:").grid(row=1, column=2, sticky=tk.W, padx=(20, 0), pady=(10, 0))
        self.workers_var = tk.StringVar(value="10")
        workers_spinbox = ttk.Spinbox(options_frame, from_=1, to=100, width=5, textvariable=self.workers_var)
        workers_spinbox.grid(row=1, column=3, sticky=tk.W, padx=(10, 0), pady=(10, 0))
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=4, column=0, columnspan=3, pady=(0, 10))
        
        self.scan_button = ttk.Button(button_frame, text="Start Scan", command=self.start_scan, style='Big.TButton')
        self.scan_button.grid(row=0, column=0, padx=(0, 10))
        
        self.stop_button = ttk.Button(button_frame, text="Stop Scan", command=self.stop_scan, state='disabled')
        self.stop_button.grid(row=0, column=1, padx=(0, 10))
        
        self.clear_button = ttk.Button(button_frame, text="Clear Results", command=self.clear_results)
        self.clear_button.grid(row=0, column=2, padx=(0, 10))
        
        self.export_button = ttk.Button(button_frame, text="Export Results", command=self.export_results)
        self.export_button.grid(row=0, column=3)
        
        # Progress bar
        self.progress_var = tk.StringVar(value="Ready")
        progress_frame = ttk.Frame(main_frame)
        progress_frame.grid(row=5, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        progress_frame.columnconfigure(1, weight=1)
        
        ttk.Label(progress_frame, text="Status:").grid(row=0, column=0, sticky=tk.W)
        self.progress_label = ttk.Label(progress_frame, textvariable=self.progress_var)
        self.progress_label.grid(row=0, column=1, sticky=tk.W, padx=(10, 0))
        
        self.progress_bar = ttk.Progressbar(progress_frame, mode='indeterminate')
        self.progress_bar.grid(row=1, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=(5, 0))

        # Search bar
        search_frame = ttk.Frame(main_frame)
        search_frame.grid(row=6, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))

        ttk.Label(search_frame, text="Search Results:").grid(row=0, column=0, padx=(0, 5))
        self.search_var = tk.StringVar()
        search_entry = ttk.Entry(search_frame, textvariable=self.search_var, width=40)
        search_entry.grid(row=0, column=1, sticky=(tk.W, tk.E))
        search_frame.columnconfigure(1, weight=1)

        self.search_button = ttk.Button(search_frame, text="Apply Filter", command=self.apply_filter, state='disabled')
        self.search_button.grid(row=0, column=2, padx=(5, 0))

        self.clear_filter_button = ttk.Button(search_frame, text="Clear Filter", command=self.clear_filter, state='disabled')
        self.clear_filter_button.grid(row=0, column=3, padx=(5, 0))

        # Additional Filters
        self.show_failed_ping_var = tk.BooleanVar()
        self.show_failed_ports_var = tk.BooleanVar()

        ttk.Checkbutton(search_frame, text="Show Failed Pings Only", variable=self.show_failed_ping_var).grid(row=1, column=1, sticky=tk.W, pady=(5, 0))
        ttk.Checkbutton(search_frame, text="Show Failed Ports Only", variable=self.show_failed_ports_var).grid(row=1, column=2, sticky=tk.W, pady=(5, 0))

        # Results display
        results_frame = ttk.LabelFrame(main_frame, text="Scan Results", padding="10")
        results_frame.grid(row=7, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S))
        results_frame.columnconfigure(0, weight=1)
        results_frame.rowconfigure(0, weight=1)
        
        # Results text area with scrollbar
        self.results_text = scrolledtext.ScrolledText(results_frame, wrap=tk.WORD, font=('Consolas', 9))
        self.results_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure text tags for colored output
        self.results_text.tag_configure("success", foreground="green")
        self.results_text.tag_configure("error", foreground="red")
        self.results_text.tag_configure("header", font=('Consolas', 9, 'bold'))
        self.results_text.tag_configure("info", foreground="blue")

        # For restoring original content
        self.full_results_text = ""

    
    def browse_host_file(self):
        """Open file dialog to select host file."""
        filename = filedialog.askopenfilename(
            title="Select Host File",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        if filename:
            self.host_file_var.set(filename)
    
    def parse_hosts(self):
        """Parse hosts from manual entry and file."""
        hosts = []
        
        # Parse manual entry
        manual_hosts = self.hosts_entry.get().strip()
        if manual_hosts:
            for host in manual_hosts.split(','):
                host = host.strip()
                if host:
                    hosts.append(host)
        
        # Parse host file
        host_file = self.host_file_var.get().strip()
        if host_file and os.path.exists(host_file):
            try:
                with open(host_file, 'r', encoding='utf-8') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#'):
                            # Handle inline comments
                            if '#' in line:
                                line = line.split('#')[0].strip()
                            if line:
                                hosts.append(line)
            except Exception as e:
                messagebox.showerror("Error", f"Failed to read host file: {e}")
        
        # Remove duplicates while preserving order
        seen = set()
        unique_hosts = []
        for host in hosts:
            if host not in seen:
                seen.add(host)
                unique_hosts.append(host)
        
        return unique_hosts
    
    def parse_ports(self):
        """Parse ports from entry fields."""
        ports = []
        
        # Parse individual ports
        ports_text = self.ports_entry.get().strip()
        if ports_text:
            for port in ports_text.split(','):
                try:
                    ports.append(int(port.strip()))
                except ValueError:
                    pass
        
        # Parse port ranges
        ranges_text = self.port_ranges_entry.get().strip()
        if ranges_text:
            for part in ranges_text.split(','):
                part = part.strip()
                if '-' in part:
                    try:
                        start, end = map(int, part.split('-', 1))
                        ports.extend(range(start, end + 1))
                    except ValueError:
                        pass
                else:
                    try:
                        ports.append(int(part))
                    except ValueError:
                        pass
        
        return sorted(set(ports))
    
    def ping_host(self, host, count=4):
        """Ping a host and return results."""
        try:
            timeout = int(self.timeout_var.get())
            if self.os_type == "windows":
                cmd = ["ping", "-n", str(count), host]
            else:
                cmd = ["ping", "-c", str(count), host]
            
            start_time = time.time()
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout * count)
            end_time = time.time()
            
            return {
                "host": host,
                "success": result.returncode == 0,
                "duration": round(end_time - start_time, 2),
                "output": result.stdout.strip() if result.returncode == 0 else result.stderr.strip()
            }
        except Exception as e:
            return {
                "host": host,
                "success": False,
                "duration": 0,
                "output": str(e)
            }
    
    def check_port(self, host, port):
        """Check if a port is open on a host."""
        try:
            timeout = int(self.timeout_var.get())
            start_time = time.time()
            with socket.create_connection((host, port), timeout=timeout):
                end_time = time.time()
                return {
                    "host": host,
                    "port": port,
                    "open": True,
                    "response_time": round((end_time - start_time) * 1000, 2),
                    "error": None
                }
        except Exception as e:
            return {
                "host": host,
                "port": port,
                "open": False,
                "response_time": 0,
                "error": str(e)
            }
    
    def scan_host(self, host, ports):
        """Scan a single host for ping and ports."""
        result = {
            "host": host,
            "timestamp": datetime.now().isoformat(),
            "ping": None,
            "ports": []
        }
        
        # Update progress
        self.root.after(0, lambda: self.progress_var.set(f"Scanning {host}..."))
        
        # Ping test
        if not self.skip_ping_var.get():
            result["ping"] = self.ping_host(host)
        
        # Port checks
        if ports:
            if self.parallel_var.get():
                # Parallel port scanning
                workers = min(int(self.workers_var.get()), len(ports))
                with ThreadPoolExecutor(max_workers=workers) as executor:
                    future_to_port = {executor.submit(self.check_port, host, port): port for port in ports}
                    for future in as_completed(future_to_port):
                        if not self.is_scanning:  # Check if scan was cancelled
                            break
                        result["ports"].append(future.result())
            else:
                # Sequential port scanning
                for port in ports:
                    if not self.is_scanning:  # Check if scan was cancelled
                        break
                    result["ports"].append(self.check_port(host, port))

        # Traceroute if selected
        if self.traceroute_var.get():
            result["traceroute"] = self.traceroute_host(host)

        # Sort ports by number
        result["ports"].sort(key=lambda x: x["port"])
        
        return result
    
    def display_result(self, result):
        """Display scan result in the text widget."""
        host = result["host"]
        
        # Host header
        self.results_text.insert(tk.END, f"\n{'='*60}\n", "header")
        self.full_results_text += f"\n{'='*60}\n"

        self.results_text.insert(tk.END, f"🔍 Host: {host}\n", "header")
        self.full_results_text += f"🔍 Host: {host}\n"

        self.results_text.insert(tk.END, f"Time: {result['timestamp']}\n", "info")
        self.full_results_text += f"Time: {result['timestamp']}\n"

        self.results_text.insert(tk.END, "-" * 40 + "\n")
        self.full_results_text += "-" * 40 + "\n"

        
        # Ping results
        if result["ping"]:
            ping = result["ping"]
            if ping["success"]:
                self.full_results_text += f"Ping: ✓ REACHABLE ({ping['duration']}s)\n"
            else:
                self.full_results_text += f"Ping: ✗ UNREACHABLE ({ping['output']})\n"

        
        # Port results
        if result["ports"]:
            open_ports = [p for p in result["ports"] if p["open"]]
            closed_ports = [p for p in result["ports"] if not p["open"]]
            
            if open_ports:
                port_list = ", ".join([f"{p['port']} ({p['response_time']}ms)" for p in open_ports])
                open_line = f"Open Ports: {port_list}"
                self.results_text.insert(tk.END, f"{open_line}\n", "success")
                self.full_results_text += f"{open_line}\n"  # <-- Add this

            
            if closed_ports:
                port_list = ", ".join([f"{p['port']} ({p['error']})" for p in closed_ports])
                closed_line = f"Closed Ports: {port_list}"
                self.results_text.insert(tk.END, f"{closed_line}\n", "error")
                self.full_results_text += f"{closed_line}\n"

        
        # Traceroute output
        if "traceroute" in result:
            traceroute_output = result["traceroute"]["output"]
            self.results_text.insert(tk.END, "\nTraceroute:\n", "info")
            self.results_text.insert(tk.END, traceroute_output + "\n", "info" if result["traceroute"]["success"] else "error")
            self.full_results_text += f"Traceroute:\n{traceroute_output}\n"


        # Auto-scroll to bottom
        self.results_text.see(tk.END)
    
    def scan_worker(self, hosts, ports):
        """Worker function for scanning hosts."""
        try:
            total_hosts = len(hosts)
            
            for i, host in enumerate(hosts):
                if not self.is_scanning:
                    break
                
                # Update progress
                progress_text = f"Scanning {i+1}/{total_hosts}: {host}"
                self.root.after(0, lambda t=progress_text: self.progress_var.set(t))
                
                # Scan host
                result = self.scan_host(host, ports)
                self.results.append(result)
                
                # Display result
                self.root.after(0, lambda r=result: self.display_result(r))
            
            # Scan completed
            if self.is_scanning:
                self.root.after(0, lambda: self.progress_var.set(f"Scan completed - {len(hosts)} hosts processed"))
            else:
                self.root.after(0, lambda: self.progress_var.set("Scan cancelled"))
                
        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Scan Error", f"An error occurred during scanning: {e}"))
        
        finally:
            # Re-enable controls
            self.root.after(0, self.scan_finished)
    
    def start_scan(self):
        """Start the network scan."""
        hosts = self.parse_hosts()
        ports = self.parse_ports()
        
        if not hosts:
            messagebox.showwarning("No Hosts", "Please specify at least one host to scan.")
            return
        
        # Clear previous results
        self.results.clear()
        
        # Update UI
        self.is_scanning = True
        self.scan_button.config(state='disabled')
        self.stop_button.config(state='normal')
        self.progress_bar.start()
        self.progress_var.set("Starting scan...")

        self.search_button.config(state='normal')
        self.clear_filter_button.config(state='normal')
        
        # Add scan info to results
        self.results_text.insert(tk.END, f"\n🚀 Network Scan Started - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n", "header")
        self.results_text.insert(tk.END, f"Hosts: {len(hosts)} | Ports: {len(ports)}\n", "info")
        self.results_text.insert(tk.END, f"Options: Parallel={self.parallel_var.get()}, Skip Ping={self.skip_ping_var.get()}\n", "info")
        
        # Start scan in separate thread
        self.scan_thread = threading.Thread(target=self.scan_worker, args=(hosts, ports), daemon=True)
        self.scan_thread.start()
    
    def stop_scan(self):
        """Stop the current scan."""
        self.is_scanning = False
        self.progress_var.set("Stopping scan...")
    
    def scan_finished(self):
        """Called when scan is finished or stopped."""
        self.is_scanning = False
        self.scan_button.config(state='normal')
        self.stop_button.config(state='disabled')
        self.progress_bar.stop()
    
    def clear_results(self):
        """Clear the results display and data."""
        self.results_text.delete(1.0, tk.END)
        self.results.clear()
        self.full_results_text = ""  # <-- This line ensures no leftover filters are applied
        self.progress_var.set("Results cleared")
        self.search_button.config(state='disabled')
        self.clear_filter_button.config(state='disabled')

    
    def export_results(self):
        """Export scan results to file."""
        if not self.results:
            messagebox.showwarning("No Results", "No scan results to export.")
            return
        
        # Ask user for export format
        export_window = tk.Toplevel(self.root)
        export_window.title("Export Results")
        export_window.geometry("300x200")
        export_window.transient(self.root)
        export_window.grab_set()
        
        ttk.Label(export_window, text="Select export format:", font=('Arial', 10, 'bold')).pack(pady=10)
        
        format_var = tk.StringVar(value="txt")
        
        ttk.Radiobutton(export_window, text="Text Report (.txt)", variable=format_var, value="txt").pack(anchor=tk.W, padx=20)
        ttk.Radiobutton(export_window, text="JSON Data (.json)", variable=format_var, value="json").pack(anchor=tk.W, padx=20)
        ttk.Radiobutton(export_window, text="CSV Summary (.csv)", variable=format_var, value="csv").pack(anchor=tk.W, padx=20)
        
        button_frame = ttk.Frame(export_window)
        button_frame.pack(pady=20)
        
        def do_export():
            export_window.destroy()
            self.export_to_file(format_var.get())
        
        ttk.Button(button_frame, text="Export", command=do_export).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(button_frame, text="Cancel", command=export_window.destroy).pack(side=tk.LEFT)
    
    def export_to_file(self, format_type):
        """Export results to specified format."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        
        if format_type == "txt":
            filename = filedialog.asksaveasfilename(
                defaultextension=".txt",
                initialfile=f"network_scan_{timestamp}.txt",
                filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
            )
            if filename:
                self.export_text_report(filename)
        
        elif format_type == "json":
            filename = filedialog.asksaveasfilename(
                defaultextension=".json",
                initialfile=f"network_scan_{timestamp}.json",
                filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
            )
            if filename:
                self.export_json_data(filename)
        
        elif format_type == "csv":
            filename = filedialog.asksaveasfilename(
                defaultextension=".csv",
                initialfile=f"network_scan_{timestamp}.csv",
                filetypes=[("CSV files", "*.csv"), ("All files", "*.*")]
            )
            if filename:
                self.export_csv_summary(filename)
    
    def export_text_report(self, filename):
        """Export results as formatted text report."""
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                f.write("Network Connectivity Checker - Scan Report\n")
                f.write("=" * 50 + "\n")
                f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"Total Hosts Scanned: {len(self.results)}\n\n")
                
                for result in self.results:
                    f.write(f"Host: {result['host']}\n")
                    f.write(f"Timestamp: {result['timestamp']}\n")
                    f.write("-" * 30 + "\n")
                    
                    if result['ping']:
                        ping = result['ping']
                        status = "REACHABLE" if ping['success'] else "UNREACHABLE"
                        f.write(f"Ping: {status} ({ping['duration']}s)\n")
                    
                    if result['ports']:
                        open_ports = [p for p in result['ports'] if p['open']]
                        closed_ports = [p for p in result['ports'] if not p['open']]
                        
                        if open_ports:
                            port_list = ", ".join([f"{p['port']}({p['response_time']}ms)" for p in open_ports])
                            f.write(f"Open Ports: {port_list}\n")
                        
                        if closed_ports:
                            port_list = ", ".join([str(p['port']) for p in closed_ports])
                            f.write(f"Closed Ports: {port_list}\n")
                    
                    f.write("\n")
            
            messagebox.showinfo("Export Success", f"Report exported to:\n{filename}")
            
        except Exception as e:
            messagebox.showerror("Export Error", f"Failed to export report: {e}")
    
    def export_json_data(self, filename):
        """Export results as JSON data."""
        try:
            export_data = {
                "scan_info": {
                    "timestamp": datetime.now().isoformat(),
                    "total_hosts": len(self.results),
                    "version": "2.0"
                },
                "results": self.results
            }
            
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(export_data, f, indent=2, ensure_ascii=False)
            
            messagebox.showinfo("Export Success", f"JSON data exported to:\n{filename}")
            
        except Exception as e:
            messagebox.showerror("Export Error", f"Failed to export JSON: {e}")
    
    def export_csv_summary(self, filename):
        """Export results as CSV summary."""
        try:
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                
                # Header
                writer.writerow(['Host', 'Timestamp', 'Ping_Status', 'Ping_Duration', 'Open_Ports', 'Closed_Ports', 'Total_Ports'])
                
                # Data rows
                for result in self.results:
                    host = result['host']
                    timestamp = result['timestamp']
                    
                    # Ping info
                    if result['ping']:
                        ping_status = 'REACHABLE' if result['ping']['success'] else 'UNREACHABLE'
                        ping_duration = result['ping']['duration']
                    else:
                        ping_status = 'SKIPPED'
                        ping_duration = 0
                    
                    # Port info
                    if result['ports']:
                        open_ports = [str(p['port']) for p in result['ports'] if p['open']]
                        closed_ports = [str(p['port']) for p in result['ports'] if not p['open']]
                        open_ports_str = ','.join(open_ports)
                        closed_ports_str = ','.join(closed_ports)
                        total_ports = len(result['ports'])
                    else:
                        open_ports_str = ''
                        closed_ports_str = ''
                        total_ports = 0
                    
                    writer.writerow([host, timestamp, ping_status, ping_duration, 
                                   open_ports_str, closed_ports_str, total_ports])
            
            messagebox.showinfo("Export Success", f"CSV summary exported to:\n{filename}")
            
        except Exception as e:
            messagebox.showerror("Export Error", f"Failed to export CSV: {e}")
    
    def on_closing(self):
        """Handle application closing."""
        if self.is_scanning:
            if messagebox.askokcancel("Quit", "A scan is in progress. Do you want to quit anyway?"):
                self.is_scanning = False
                self.root.destroy()
        else:
            self.root.destroy()

    def traceroute_host(self, host):
        """Run traceroute or tracert on the host."""
        try:
            if self.os_type == "windows":
                cmd = f"tracert {host}"
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30, shell=True)
            else:
                cmd = ["traceroute", host]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

            output = (result.stdout or "") + ("\n" + result.stderr if result.stderr else "")
            return {
                "success": "Trace complete" in output or result.returncode == 0,
                "output": output.strip()
            }
        except Exception as e:
            return {
                "success": False,
                "output": str(e)
            }
        
    def apply_filter(self):
        """Filter the displayed results based on search input and checkboxes."""
        search_term = self.search_var.get().strip().lower()
        show_failed_ping_only = self.show_failed_ping_var.get()
        show_failed_ports_only = self.show_failed_ports_var.get()

        filtered_lines = []
        host_block = []

        for line in self.full_results_text.splitlines():
            if line.startswith("=" * 60):  # Start of a new host section
                if host_block:
                    # Evaluate the previous block before starting a new one
                    block_text = "\n".join(host_block).lower()
                    include = True

                    if search_term and search_term not in block_text:
                        include = False

                    # Ping check logic
                    if show_failed_ping_only:
                        if "ping:" not in block_text:
                            include = False  # No ping line = skipped = exclude
                        elif "ping: ✓ reachable" in block_text:
                            include = False  # Success = exclude

                    # Port check logic
                    if show_failed_ports_only:
                        if "closed ports:" not in block_text:
                            include = False  # No closed ports = exclude

                    if include:
                        filtered_lines.extend(host_block)

                host_block = [line]  # start a new host block
            else:
                host_block.append(line)

        # Handle the last host block
        if host_block:
            block_text = "\n".join(host_block).lower()
            include = True

            if search_term and search_term not in block_text:
                include = False

            if show_failed_ping_only:
                if "ping:" not in block_text:
                    include = False
                elif "ping: ✓ reachable" in block_text:
                    include = False

            if show_failed_ports_only:
                if "closed ports:" not in block_text:
                    include = False

            if include:
                filtered_lines.extend(host_block)

        # Display
        self.results_text.delete("1.0", tk.END)
        self.results_text.insert(tk.END, "\n".join(filtered_lines))


    def clear_filter(self):
        """Clear the search filter and restore full results."""
        self.results_text.delete("1.0", tk.END)
        self.results_text.insert(tk.END, self.full_results_text)
        self.search_var.set("")




def main():
    """Main function to run the GUI application."""
    root = tk.Tk()
    app = NetworkCheckerGUI(root)
    
    # Center window on screen
    root.update_idletasks()
    x = (root.winfo_screenwidth() // 2) - (root.winfo_width() // 2)
    y = (root.winfo_screenheight() // 2) - (root.winfo_height() // 2)
    root.geometry(f"+{x}+{y}")
    
    root.mainloop()

if __name__ == "__main__":
    main()