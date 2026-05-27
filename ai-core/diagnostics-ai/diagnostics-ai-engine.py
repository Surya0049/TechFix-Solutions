import json
import os
import re
from datetime import datetime

LOG_ROOT = r"X:\\TechFix\\logs"
OUTPUT_FILE = os.path.join(LOG_ROOT, "ai-diagnostics-report.json")

REPAIR_DATABASE = {
    "CBS corruption": {
        "severity": "HIGH",
        "repair": "Run DISM RestoreHealth and offline SFC",
        "confidence": 0.92
    },
    "BCD corruption": {
        "severity": "CRITICAL",
        "repair": "Run bootrec and rebuild BCD",
        "confidence": 0.96
    },
    "Driver failure": {
        "severity": "MEDIUM",
        "repair": "Rollback problematic driver",
        "confidence": 0.81
    },
    "Windows Update corruption": {
        "severity": "HIGH",
        "repair": "Reset update components and DISM repair",
        "confidence": 0.87
    }
}

class DiagnosticsAI:

    def __init__(self):
        self.results = []

    def analyze_log(self, log_content):

        findings = []

        patterns = {
            "CBS corruption": r"corrupt|CBS",
            "BCD corruption": r"BCD|bootrec|winload",
            "Driver failure": r"driver|nvlddmkm|iastor",
            "Windows Update corruption": r"0x800f|update"
        }

        for issue, pattern in patterns.items():
            if re.search(pattern, log_content, re.IGNORECASE):
                findings.append(issue)

        return findings

    def generate_recommendations(self, findings):

        recommendations = []

        for finding in findings:
            if finding in REPAIR_DATABASE:
                entry = REPAIR_DATABASE[finding]

                recommendations.append({
                    "issue": finding,
                    "severity": entry["severity"],
                    "recommended_repair": entry["repair"],
                    "confidence": entry["confidence"]
                })

        return recommendations

    def scan_logs(self):

        if not os.path.exists(LOG_ROOT):
            os.makedirs(LOG_ROOT)

        for root, dirs, files in os.walk(LOG_ROOT):
            for file in files:
                if file.endswith(".log") or file.endswith(".txt"):
                    path = os.path.join(root, file)

                    try:
                        with open(path, "r", errors="ignore") as f:
                            content = f.read()

                        findings = self.analyze_log(content)
                        recommendations = self.generate_recommendations(findings)

                        self.results.append({
                            "file": path,
                            "findings": findings,
                            "recommendations": recommendations
                        })

                    except Exception as e:
                        self.results.append({
                            "file": path,
                            "error": str(e)
                        })

    def export_report(self):

        report = {
            "generated": datetime.utcnow().isoformat(),
            "engine": "TechFix Diagnostics AI",
            "results": self.results
        }

        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=4)

        print("AI diagnostics report generated:")
        print(OUTPUT_FILE)

if __name__ == "__main__":

    print("=======================================")
    print(" TechFix Diagnostics AI Engine")
    print("=======================================")

    engine = DiagnosticsAI()
    engine.scan_logs()
    engine.export_report()

    print("=======================================")
    print(" AI Diagnostics Completed")
    print("=======================================")
