@call PubConfig.cmd

@set opts=-AWSAccessKeyId %AWSAccessKeyId% -AWSSecretAccessKey %AWSSecretAccessKey% -SyncDirection upload -BucketName download.livereload.com -UploadHeaders x-amz-acl:public-read -DeleteS3ItemsWhereNotInLocalList false -UseSSL false -TransferThreads 5 -MultipartThreads 1

"%~dp0tools\S3Sync\S3Sync.exe" -LocalFolderPath "bin\Debug\app.publish\\" -S3FolderKeyName "windows-stage/" %opts%
