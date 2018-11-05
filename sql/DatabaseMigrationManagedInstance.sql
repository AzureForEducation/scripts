-- ADDING SHARED ACCESS SIGNATURE

CREATE CREDENTIAL [your-blob-address-including-container]
WITH IDENTITY = 'SHARED ACCESS SIGNATURE', 
SECRET = 'your-shared-access-string-with-no-?-at-the-begining'

-- RESTORING BD_EMEC DATABASE

RESTORE FILELISTONLY FROM URL = 'https://{your-storage-account-name}.blob.core.windows.net/{your-container}/{your-bak-file}'

RESTORE DATABASE [your-db-name-1] FROM URL = 'https://{your-storage-account-name}.blob.core.windows.net/{your-container}/{your-bak-file}' 

-- RESTORING BD_SIMULADOCUSTO DATABASE

RESTORE FILELISTONLY FROM URL = 'https://{your-storage-account-name}.blob.core.windows.net/{your-container}/{your-bak-file}'

RESTORE DATABASE [your-db-name-2] FROM URL = 'https://{your-storage-account-name}.blob.core.windows.net/{your-container}/{your-bak-file}'

-- RESTORING BD_SGC DATABASE

RESTORE FILELISTONLY FROM URL = 'https://{your-storage-account-name}.blob.core.windows.net/{your-container}/{your-bak-file}'

RESTORE DATABASE [your-db-name-3] FROM URL = 'https://{your-storage-account-name}.blob.core.windows.net/{your-container}/{your-bak-file}'