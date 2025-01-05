Clear-Host

# Define availability group listeners
$Listeners = @(
    "Listener01",
    "Listener02"
)

# Query to get availability replicas and their roles
$SqlCmd = "
            SELECT DISTINCT 
                replica_server_name AS ReplicaServerName, 
                is_primary_replica AS IsPrimaryReplica
            FROM [master].[sys].[availability_replicas] t1
            INNER JOIN [master].[sys].[dm_hadr_database_replica_states] t2 ON t1.group_id = t2.group_id AND t1.replica_id = t2.replica_id
        "

# Iterate through each listener
foreach ($Listener in $Listeners) {
    try {
        # Get availability replicas
        $ReplicaInstances = Invoke-Sqlcmd -ServerInstance $Listener -Database master -Query $SqlCmd -TrustServerCertificate -Verbose
        
        $PrimaryReplica    = ($ReplicaInstances | Where-Object { $_.IsPrimaryReplica -eq 1 }).ReplicaServerName
        $SecondaryReplicas = ($ReplicaInstances | Where-Object { $_.IsPrimaryReplica -eq 0 }).ReplicaServerName

        $SourceInstance = $PrimaryReplica
        $TargetInstances = $SecondaryReplicas

        # Query to get SQL logins SID
        $SqlCmd2 = "
                    SELECT sp.name, checksum(sp.sid) as [sid_checksum]
                    FROM master.sys.server_principals sp
                    WHERE sp.type_desc = 'SQL_LOGIN' -- Only SQL logins
                      AND sp.principal_id > 257      -- Exclude system logins
                      AND IS_SRVROLEMEMBER('sysadmin', sp.name) <> 1 -- Exclude sysadmin role logins
                      AND sp.is_disabled = 0 -- Exclude disabled logins                   
                    ORDER BY sp.name;
                  "

        # Get logins from the primary replica
        $PrimarySidChecksum = Invoke-Sqlcmd -ServerInstance $Listener -Database master -Query $SqlCmd2 -TrustServerCertificate -OutputAs DataTables -Verbose

        if ($PrimarySidChecksum.Rows.Count -gt 0) {
            # Iterate through each login
            for ($i = 0; $i -lt $PrimarySidChecksum.Rows.Count; $i++) {
                foreach ($TargetInstance in $TargetInstances) {
                    try {
                        # Query to get SID checksum on secondary replica
                        $SqlCmd3 = "SELECT checksum(sid) as sid_checksum FROM master.sys.server_principals WHERE name = '$($PrimarySidChecksum.Rows[$i].name)'"      
                        
                        $SecondarySidChecksum = Invoke-Sqlcmd -ServerInstance $TargetInstance -Database master -Query $SqlCmd3 -TrustServerCertificate -Verbose

                     if($SecondarySidChecksum.sid_checksum -ne $null) {

                        # Compare SID values and drop login if mismatched
                        if ($PrimarySidChecksum.Rows[$i].sid_checksum -ne $SecondarySidChecksum.sid_checksum) {
                            Write-Host "Dropping and creating Login [$($PrimarySidChecksum.Rows[$i].name)]".PadRight(40) " on $TargetInstance" 
                            
                            Copy-DbaLogin -Source $SourceInstance -Destination $TargetInstance -Login $($PrimarySidChecksum.Rows[$i].name) -Force -ExcludePermissionSync -ErrorAction Stop -Verbose
                        }

                      }

                    } catch {
                        Write-Error "Error processing login [$($PrimarySidChecksum.Rows[$i].name)] on target instance [$TargetInstance]: $_"
                        throw
                    }
                }
                
            }
        }

        # Copy logins from primary to secondary replicas
        foreach ($TargetInstance in $TargetInstances) {
            try {
                Write-Host "Copying logins to target instance : $($TargetInstance)"
                Copy-DbaLogin -Source $SourceInstance -Destination $TargetInstance -ExcludeSystemLogins -ExcludePermissionSync -ErrorAction Stop -Verbose

            } catch {
                Write-Error "Error copying logins from [$SourceInstance] to [$TargetInstance]: $_"
                throw
            }
        }

    } catch {
        Write-Error "Error processing listener [$Listener]: $_"
        throw
    }
}
