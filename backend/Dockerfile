# Do ballerina bindings to java code
FROM ballerina/ballerina:2201.3.4

USER root
RUN apk add --no-cache maven

COPY . /home/10014/backend

RUN mvn --version

WORKDIR /home/10014/backend/TraversePack

RUN mvn clean install

RUN bal bindgen -mvn TraversePack:TraversePack:1.0-SNAPSHOT java.io.FileInputStream java.util.ArrayList java.util.Arrays java.util.List java.util.Stack java.util.UUID java.util.jar.Attributes java.util.jar.Manifest java.util.zip.ZipInputStream org.apache.commons.io.FileUtils java.io.BufferedOutputStream java.io.FileOutputStream java.io.InputStream java.io.OutputStream java.io.IOException java.util.Enumeration java.util.zip.ZipEntry java.util.zip.ZipFile com.microsoft.azure.storage.CloudStorageAccount com.microsoft.azure.storage.SharedAccessAccountPolicy java.util.Date java.net.URI com.microsoft.azure.storage.blob.CloudBlob com.microsoft.azure.storage.blob.CloudBlobClient com.microsoft.azure.storage.blob.CloudBlobContainer com.microsoft.azure.storage.blob.SharedAccessBlobPolicy java.util.logging.Logger java.util.logging.Level java.util.logging.Handler java.util.logging.ConsoleHandler

WORKDIR /home/10014/backend

RUN bal build 

USER 10014

CMD [ "bal", "run", "target/bin/backend.jar" ]