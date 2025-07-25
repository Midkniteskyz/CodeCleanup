## ✅ Recommended Subject Format Convention

[Severity Icon] SolarWinds [Object Type] Alert: [Alert Name] [Optional Key Info]

### 📌 Examples:

Triggered
[🚨 SolarWinds ${N=Alerting;M=Severity} ${N=Alerting;M=ObjectType} Alert Triggered] ${N=Alerting;M=AlertName}

Reset
[✅ SolarWinds ${N=Alerting;M=Severity} ${N=Alerting;M=ObjectType} Alert Reset] ${N=Alerting;M=AlertName}

## 🧠 Subject Line Elements

| Element          | Example                           | Source                                 |
| ---------------- | --------------------------------- | -------------------------------------- |
| Severity Icon    | 🚨, ⚠️, ℹ️, ✅                     | Based on `${Severity}` or `${Trigger}` |
| Source/Platform  | `SolarWinds`                      | Static or dynamic label                |
| Alert Type       | `Volume Alert`, `Node Down`       | Custom property or alert name filter   |
| Entity or Detail | `on NodeName`, `/mnt is 95% full` | `${Node.Caption}` or `${Caption}`      |

## 🎨 Suggested Severity Icons

| Severity     | Icon | Unicode | Fallback (if icons are stripped) |
| ------------ | ---- | ------- | -------------------------------- |
| Critical     | 🚨   | U+1F6A8 | `[CRITICAL]`                     |
| Warning      | ⚠️   | U+26A0  | `[WARNING]`                      |
| Info/Notice  | ℹ️   | U+2139  | `[INFO]`                         |
| Resolved     | ✅    | U+2705  | `[RECOVERED]`                    |
| Down/Failure | 🔴   | U+1F534 | `[DOWN]`                         |
| Degraded     | 🟠   | U+1F7E0 | `[DEGRADED]`                     |
| Up/Normal    | 🟢   | U+1F7E2 | `[UP]`                           |

## ✏️ Example Template for Subject Line

You can build this into the alert's **Subject field** like:

${N=Alerting;M=Severity} == "Critical" ? "🚨" : 
${N=Alerting;M=Severity} == "Warning" ? "⚠️" : 
"ℹ️"  // fallback icon

But since SolarWinds alert subject lines don’t support conditional logic in macros, you can simulate this with **dedicated alerts per severity** or insert a **custom property**.

So practically:

### Subject line in SolarWinds alert:

🚨 SolarWinds Volume Alert: ${N=SwisEntity;M=Caption} on ${N=SwisEntity;M=Node.Caption}

Or for node down:

🔴 SolarWinds Node Down: ${N=SwisEntity;M=Node.Caption} is unreachable

## 🧪 Bonus: Include the Metric in Subject

* Volume: `"Volume 94% Full"`
* CPU: `"CPU Load at 92%"`
* Memory: `"Memory Usage 84% on CoreApp01"`

Just add:

Trigger Subject
🚨 SolarWinds ${N=Alerting;M=ObjectType} Alert: ${N=SwisEntity;M=Caption} at ${N=SwisEntity;M=VolumePercentUsed;F=Percent} on ${N=SwisEntity;M=Node.Caption}

Reset Subject
✅ SolarWinds Alert Reset : ${N=SwisEntity;M=Caption} at ${N=SwisEntity;M=VolumePercentUsed;F=Percent} on ${N=SwisEntity;M=Node.Caption}

Action Naming Convention
<Alert Object Type> - <Trigger or Reset> - Email Template

