using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using TechFixRecoveryAI.Workflow;

namespace TechFixRecoveryAI.ViewModels
{
    public class DashboardViewModel : INotifyPropertyChanged
    {
        private readonly RecoveryWorkflowManager _workflowManager;

        private string _systemStatus;
        private string _workflowState;
        private int _repairProgress;
        private bool _isRecoveryRunning;

        public event PropertyChangedEventHandler PropertyChanged;

        public ObservableCollection<string> LiveLogs { get; set; }

        public string SystemStatus
        {
            get => _systemStatus;
            set
            {
                _systemStatus = value;
                OnPropertyChanged();
            }
        }

        public string WorkflowState
        {
            get => _workflowState;
            set
            {
                _workflowState = value;
                OnPropertyChanged();
            }
        }

        public int RepairProgress
        {
            get => _repairProgress;
            set
            {
                _repairProgress = value;
                OnPropertyChanged();
            }
        }

        public bool IsRecoveryRunning
        {
            get => _isRecoveryRunning;
            set
            {
                _isRecoveryRunning = value;
                OnPropertyChanged();
            }
        }

        public DashboardViewModel()
        {
            LiveLogs = new ObservableCollection<string>();

            _workflowManager = new RecoveryWorkflowManager();

            _workflowManager.OnWorkflowLog += HandleWorkflowLog;
            _workflowManager.OnProgressChanged += HandleProgressChanged;
            _workflowManager.OnWorkflowStateChanged += HandleWorkflowStateChanged;

            InitializeDashboard();
        }

        private void InitializeDashboard()
        {
            SystemStatus = "Recovery Environment Ready";
            WorkflowState = "Idle";
            RepairProgress = 0;
        }

        public async Task StartRecoveryWorkflow()
        {
            if (IsRecoveryRunning)
                return;

            IsRecoveryRunning = true;

            WorkflowState = "Starting Intelligent Recovery Workflow";

            LiveLogs.Clear();

            await _workflowManager.StartFullRecoveryWorkflow();

            IsRecoveryRunning = false;
        }

        private void HandleWorkflowLog(string message)
        {
            LiveLogs.Add(message);
        }

        private void HandleProgressChanged(int progress)
        {
            RepairProgress = progress;
        }

        private void HandleWorkflowStateChanged(string state)
        {
            WorkflowState = state;
        }

        private void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
