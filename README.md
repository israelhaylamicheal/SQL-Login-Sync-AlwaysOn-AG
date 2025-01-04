# SQL-Login-Sync-AlwaysOn-AG
This PowerShell script helps the synchronization of SQL Server logins across replicas in a SQL Server Always On Availability Group (AG) setup. 
It identifies the primary and secondary replicas associated with specified AG Listeners, retrieves logins from the primary replica, and ensures their replication on the secondary replicas to maintain consistent logins with teh correct permissions throughout the AG environment.

Requirements:
dbatools Module: Ensure the dbatools PowerShell module is installed for leveraging functions such as Copy-DbaLogin command.
SqlServer Module: Ensure the SqlServer PowerShell module is installed to execute Invoke-SqlCmd command.
SQL Server Permissions: Adequate permissions are required to query login information and replicate logins between instances.
SQL Server Instances: Verify that the specified AG Listeners are reachable and configured with appropriate permissions for login synchronization.

This ensures seamless login consistency across all replicas, aiding in maintaining a robust and fault-tolerant AG environment.
