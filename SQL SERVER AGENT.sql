
--To see the SQL SERVER AGENT to the particular user
--First map msdb database to the User

--Run the follwing script by the user having admin privilage
use msdb
EXECUTE sp_addrolemember
@rolename = 'SQLAgentOperatorRole',
@membername = 'eremitdbw'

EXECUTE sp_addrolemember
@rolename = 'SQLAgentUserRole',
@membername = 'eremitdbw'

EXECUTE sp_addrolemember
@rolename = 'SQLAgentReaderRole',
@membername = 'eremitdbw'


--To execute the job by the User

GRANT EXECUTE ON sp_send_dbmail TO eremitdbw
