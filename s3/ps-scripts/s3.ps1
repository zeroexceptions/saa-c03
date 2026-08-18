$BucketName = Read-Host "Enter bucket name"

if ([string]::IsNullOrWhiteSpace($BucketName)) {
    Write-Host "Error: please provide a bucket name." -ForegroundColor Red
    exit 1
}

New-S3Bucket -BucketName $BucketName
