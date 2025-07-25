# 🖥️ Network Connectivity Checker v2.0

A user-friendly graphical tool for scanning and analyzing network connectivity, ping responses, open/closed ports, and optional traceroutes.

---

## 🚀 Getting Started

1. **Launch the App**
   - Run the `.exe` or execute the Python script.
   - The main window will appear with inputs and scan options.

---

## 🌐 Step 1: Enter Hosts to Scan

- **Manual Entry**  
  Enter hostnames or IP addresses in the `Hosts` field, separated by commas.  
  _Example:_  
  google.com, github.com, 8.8.8.8

- **Host File (Optional)**  
Load a `.txt` file with one host per line.  
Click `Browse` next to the Host File field to select your file.

---

## 🔌 Step 2: Define Ports

- **Individual Ports:**  
Enter ports separated by commas (e.g., `80, 443, 22`).

- **Port Ranges:**  
Define ranges like `8000-8010`. You can combine both formats.

---

## ⚙️ Step 3: Set Scan Options

- `Skip ping tests` – Only check ports.
- `Parallel scanning` – Faster scans using multiple threads.
- `Include traceroute` – Run traceroute for each host.
- `Timeout` – Time (in seconds) before each check gives up.
- `Workers` – Number of threads for parallel scans.

---

## 🔍 Step 4: Start the Scan

- Click **Start Scan** to begin.
- View real-time results in the bottom results window.
- Click **Stop Scan** to cancel scanning early.

---

## 🔎 Filtering Results (After Scan)

- Use the `Search Results` box to find specific hosts or ports.
- Enable these checkboxes to refine results:
- `Show Failed Pings Only`
- `Show Failed Ports Only`
- Click `Apply Filter` to filter or `Clear Filter` to restore full results.

---

## 📁 Exporting Results

Click **Export Results** and choose your preferred format:

- `.txt` — Readable scan report
- `.json` — Structured data
- `.csv` — Easy-to-import spreadsheet format

---

## ♻️ Additional Controls

- **Clear Results** — Wipes the output and resets search.
- **Exit App** — If scanning is in progress, you'll be prompted to confirm.

---

## 📝 Notes

- Ping results show as:
- `✓ REACHABLE` – Host responded
- `✗ UNREACHABLE` – Host unreachable or timed out
- Ports will show as either open (with response time) or closed (with error).
- Traceroute may take time, especially on unreachable hosts.

---

## 📦 Requirements (for Python Users)

To run from source:

python network_checker.py

You’ll need:
- Python 3.6+
- Standard libraries: `tkinter`, `socket`, `threading`, `subprocess`, etc.

---

## ✅ Safe, Offline Tool

This application performs only local network tests (ping, port connect, traceroute). No external API calls or telemetry are used. You are in full control of your data.

---

Enjoy the scan! 🛰️
