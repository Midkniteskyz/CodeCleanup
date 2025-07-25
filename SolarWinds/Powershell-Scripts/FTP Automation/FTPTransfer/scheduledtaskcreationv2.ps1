function Import-FTPTask{
    
    Register-ScheduledTask -xml `
                '<?xml version="1.0" encoding="UTF-16"?>
                <Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
                <RegistrationInfo>
                    <Date>2023-08-10T11:40:59.223005</Date>
                    <Author></Author>
                    <Description>Start the FTP Transfer script task</Description>
                    <URI>\FTPTask</URI>
                </RegistrationInfo>
                <Principals>
                    <Principal id="Author">
                    <LogonType>InteractiveToken</LogonType>
                    <RunLevel>HighestAvailable</RunLevel>
                    </Principal>
                </Principals>
                <Settings>
                    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
                    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
                    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
                    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
                    <RestartOnFailure>
                    <Count>3</Count>
                    <Interval>PT1M</Interval>
                    </RestartOnFailure>
                    <IdleSettings>
                    <StopOnIdleEnd>true</StopOnIdleEnd>
                    <RestartOnIdle>false</RestartOnIdle>
                    </IdleSettings>
                    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
                </Settings>
                <Triggers>
                    <BootTrigger />
                    <CalendarTrigger>
                    <StartBoundary>2023-08-10T11:13:52</StartBoundary>
                    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
                    <Repetition>
                        <Interval>PT5M</Interval>
                    </Repetition>
                    <ScheduleByDay>
                        <DaysInterval>1</DaysInterval>
                    </ScheduleByDay>
                    </CalendarTrigger>
                </Triggers>
                <Actions Context="Author">
                    <Exec>
                    <Command>C:\FTP\Scripts\Main.ps1</Command>
                    <Arguments>-executionpolicy bypass</Arguments>
                    </Exec>
                </Actions>
                </Task>' `
                -TaskName "FTPTransfer"
                }