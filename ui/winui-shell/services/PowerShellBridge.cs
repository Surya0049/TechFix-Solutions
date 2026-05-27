using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Management.Automation;
using System.Threading.Tasks;

namespace TechFixRecoveryAI.Services
{
    public class PowerShellBridge
    {
        public async Task<List<string>> ExecuteScriptAsync(string scriptPath)
        {
            return await Task.Run(() =>
            {
                var output = new List<string>();

                try
                {
                    using (PowerShell ps = PowerShell.Create())
                    {
                        ps.AddScript($@"
                            Set-ExecutionPolicy Bypass -Scope Process -Force;
                            & '{scriptPath}'
                        ");

                        var results = ps.Invoke();

                        foreach (var result in results)
                        {
                            output.Add(result.ToString());
                        }

                        if (ps.Streams.Error.Count > 0)
                        {
                            foreach (var error in ps.Streams.Error)
                            {
                                output.Add($"ERROR: {error}");
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    output.Add($"EXCEPTION: {ex.Message}");
                }

                return output;
            });
        }

        public async Task<List<string>> RunDiagnosticsScan()
        {
            string script = @"X:\TechFix\diagnostics\windows-scan\detect-windows-installations.ps1";

            Debug.WriteLine("Running diagnostics scan...");

            return await ExecuteScriptAsync(script);
        }

        public async Task<List<string>> RunOfflineRepair()
        {
            string script = @"X:\TechFix\repair-engine\offline-repair\offline-repair-engine.ps1";

            Debug.WriteLine("Executing offline repair engine...");

            return await ExecuteScriptAsync(script);
        }

        public async Task<List<string>> RunRollbackEngine()
        {
            string script = @"X:\TechFix\rollback\rollback-engine\rollback-engine.ps1";

            Debug.WriteLine("Executing rollback engine...");

            return await ExecuteScriptAsync(script);
        }

        public async Task<List<string>> RunAIDiagnostics()
        {
            return await Task.Run(() =>
            {
                var output = new List<string>();

                try
                {
                    ProcessStartInfo processInfo = new ProcessStartInfo
                    {
                        FileName = "python",
                        Arguments = @"X:\TechFix\ai-core\diagnostics-ai\diagnostics-ai-engine.py",
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        UseShellExecute = false,
                        CreateNoWindow = true
                    };

                    using (Process process = Process.Start(processInfo))
                    {
                        while (!process.StandardOutput.EndOfStream)
                        {
                            output.Add(process.StandardOutput.ReadLine());
                        }

                        while (!process.StandardError.EndOfStream)
                        {
                            output.Add("ERROR: " + process.StandardError.ReadLine());
                        }

                        process.WaitForExit();
                    }
                }
                catch (Exception ex)
                {
                    output.Add($"EXCEPTION: {ex.Message}");
                }

                return output;
            });
        }
    }
}
