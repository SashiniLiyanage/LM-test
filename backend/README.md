**License Manager**

It contains a module : license_manager

Before running the modules create a file named config.toml in the root directory and add the following 
and provide the values:

DB_URL = ""  
DB_USERNAME = ""  
DB_PASSWORD = ""  

GMAIL_RECIPIENT= ""
GMAIL_SENDER= ""
GMAIL_PASSWORD= ""

DESTINATION_PATH = "/tmp/storage/processingPacks"
LICENSEHEADER_PATH = "./storage/resources/LicenseHeader"

ACCESS_KEY_OR_SAS = ""
ACCOUNT_NAME = ""

Navigate to the TraversePack directory and issue the following commands:  
`mvn clean install` 

`bal bindgen -mvn TraversePack:TraversePack:1.0-SNAPSHOT java.io.FileInputStream java.util.ArrayList java.util.Arrays java.util.List java.util.Stack java.util.UUID java.util.jar.Attributes java.util.jar.Manifest java.util.zip.ZipInputStream org.apache.commons.io.FileUtils java.io.BufferedOutputStream java.io.FileOutputStream java.io.InputStream java.io.OutputStream java.io.IOException java.util.Enumeration java.util.zip.ZipEntry java.util.zip.ZipFile com.microsoft.azure.storage.CloudStorageAccount com.microsoft.azure.storage.SharedAccessAccountPolicy java.util.Date java.net.URI com.microsoft.azure.storage.blob.CloudBlob com.microsoft.azure.storage.blob.CloudBlobClient com.microsoft.azure.storage.blob.CloudBlobContainer com.microsoft.azure.storage.blob.SharedAccessBlobPolicy` 

To run the module, navigate to the root directory of ballerina project and issue the following command:  
`bal build`    

Change the Docker image to 
`bal run target/bin/backend.jar`