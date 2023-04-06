package org.wso2.internal.apps.license.manager;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Stack;
import java.util.UUID;
import java.util.jar.Attributes;
import java.util.jar.Manifest;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import com.microsoft.azure.storage.CloudStorageAccount;
import com.microsoft.azure.storage.SharedAccessAccountPolicy;
import com.microsoft.azure.storage.blob.CloudBlob;
import com.microsoft.azure.storage.blob.CloudBlobClient;
import com.microsoft.azure.storage.blob.CloudBlobContainer;
import com.microsoft.azure.storage.blob.SharedAccessBlobPolicy;

public class TraversePack {

    public static String getName(String product) {
        try{
            String name = new File(product).getName();
            String extractedName = getDefaultName(name);
            for (int i = 0; i < name.length(); i++) {
                if ((name.charAt(i) == '-' | name.charAt(i) == '_') && (Character.isDigit(name.charAt(i + 1)) |
                        name.charAt(i + 1) == 'S')) {
                    return name.substring(0, i);
                }
            }
            return extractedName;
        }catch(Exception e){
                return "";
        }
    }

    public static String getVersion(String product) {
        try{
            String name = new File(product).getName();
            String extractedVersion = "1.0.0";

            name = name.replace(".jar", "");
            name = name.replace(".mar", "");
            name = name.replace(".zip", "");

            for (int i = 0; i < name.length(); i++) {
                if ((name.charAt(i) == '-' | name.charAt(i) == '_') && (Character.isDigit(name.charAt(i + 1)) |
                        name.charAt(i + 1) == 'S')) {
                    return name.substring(i + 1, name.length());
                }
            }
            return extractedVersion;
        }catch(Exception e){
            return "";
        }
    }
    /**
     * Creates a json string for the pack.
     * @param path : path to the pack.
     */
    public static String getJsonString(String path, String sourcePath, String destinationPath, String fileName) {
        String extractedFilePath = destinationPath + File.separator + path;
        String source = sourcePath + File.separator + path + ".zip";
        try{
            String jsonString = "";
            String packName = getName(fileName.replace(".zip",""));
            String packVersion = getVersion(fileName.replace(".zip",""));
            jsonString += "{\"packName\":\"" + packName + "\",\"packVersion\":\"" + packVersion + "\",\"library\":";

            File destination = new File(extractedFilePath);
            destination.mkdir();
            
            path = destination.getAbsolutePath() + File.separator + fileName.replace(".zip","");

            LicenseManagerUtils.unzip(source, path);
           
            // delete the source zip file after extracting it
            LicenseManagerUtils.deleteFolder(source);

            // path = destination.getAbsolutePath() + File.separator + fileName.replace(".zip","");

            String uuid = UUID.randomUUID().toString();
            String tempFolderToHoldJars = new File(path).getParent() + File.separator + uuid;
            String jsonlibrary = getjsonLiraryString(path, tempFolderToHoldJars);

            // delete the extracted file after getting json string
            LicenseManagerUtils.deleteFolder(extractedFilePath);

            jsonString += jsonlibrary + "}";
            return jsonString;

        }catch(Exception e){
            // delete the source zip file after extracting it
            LicenseManagerUtils.deleteFolder(source);
            // delete the extracted file after getting json string
            LicenseManagerUtils.deleteFolder(extractedFilePath);

            e.printStackTrace();
            return "Exception";
        }
    }
    /**
     * Creates jsonLibraryString for the pack.
     * @param path : path to the pack.
     * @throws Exception
     */
    public static String getjsonLiraryString(String path, String tempFolderToHoldJars) throws Exception {
        try{
            System.out.println("Generating library license string");
            String jsonlibrary = "[";
            List<File> jarsInBundle = new ArrayList<>();
            List<File> jarFilesInPack = findDirectJars(path);
            new File(tempFolderToHoldJars).mkdir();
            Stack<File> zipStack = new Stack<>();
            zipStack.addAll(jarFilesInPack);
            jarFilesInPack.clear();
            tempFolderToHoldJars = tempFolderToHoldJars + File.separator;
            while (!zipStack.empty()) {
                File fileToBeExtracted = zipStack.pop();
                File extractTo;
                // Get information from the Manifest file.
                Manifest manifest = null;
                try {
                    manifest = new java.util.jar.JarFile(fileToBeExtracted).getManifest();
                } catch (IOException e) {
                    //do nothing
                }
                String name = getName(fileToBeExtracted.getName());
                String version = getVersion(fileToBeExtracted.getName());
                String license="[]";
                String type = "jar";
                String groupID = null;
                String artifactID = getName(fileToBeExtracted.getName());

                if (manifest != null) {
                    license = getLicenseUrl(manifest);
                    type =  getType(manifest, fileToBeExtracted,jarsInBundle);
                    groupID = getGroupID(manifest);
                }

                if (!(jsonlibrary.contains(name+"_"+version+".jar") || jsonlibrary.contains(name+"-"+version+".jar") ||
                        jsonlibrary.contains(name+"_"+version+".mar") || jsonlibrary.contains(name+"-"+version+".mar"))) {
                    jsonlibrary += "{\"libName\":\"" + name + "\"," +
                            "\"libVersion\":\"" + version + "\"," +
                            "\"libFilename\":\"" + fileToBeExtracted.getName() + "\"," +
                            "\"libType\":\"" + type + "\"," +
                            "\"libLicense\":" + license +"},";
                }
                if (checkInnerJars(fileToBeExtracted.getAbsolutePath())) {
                    extractTo = new File(tempFolderToHoldJars + fileToBeExtracted.getName());
                    extractTo.mkdir();
                    LicenseManagerUtils.unzip(fileToBeExtracted.getAbsolutePath(), extractTo.getAbsolutePath());
                    List<File> listOfInnerFiles = Arrays.asList(extractTo
                            .listFiles(file -> (file.getName().endsWith(".jar") || file.getName().endsWith(".mar"))));
                    jarsInBundle.addAll(listOfInnerFiles);
                    zipStack.addAll(listOfInnerFiles);
                }
            }

            if(jsonlibrary.length()== 1){
                jsonlibrary = "[]";
            }else{
                jsonlibrary = jsonlibrary.substring(0, jsonlibrary.length() - 1) + "]";
            }
            
            System.out.println("Library license string is generated");
            return jsonlibrary;
            
        }catch(Exception e){
            System.out.println(e.getMessage());
            throw(e);
        }
    }
    /**
     * Returns license url if it has
     * @param manifest Manifest of the jar file
     * @return licenseurl/null
     */
    private static String getLicenseUrl(Manifest manifest) {

        Attributes map = manifest.getMainAttributes();
        String LicenseManifest = map.getValue("Bundle-License");
        if (LicenseManifest != null) {
            if (LicenseManifest.contains("link")) {
                LicenseManifest = LicenseManifest.substring(0, LicenseManifest.indexOf(";"));
            }
            String[] licenseList = LicenseManifest.split(", ");
            String license = "[";
            for (String url : licenseList) {
                url = url.replaceAll("^\"|\"$", "");
                license = license + "\"" + url + "\",";
            }
            license = license.substring(0,license.length()-1) + "]";
            return license;
        }
        return "[]";
    }

    private static String getGroupID(Manifest manifest) {
        Attributes map = manifest.getMainAttributes();
        String groupID = map.getValue("Implementation-Vendor-Id");
        if (groupID != null) {
            return groupID;
        }
        return "NULL";
    }

    /**
     * Returns the type of the jarFile by evaluating the Manifest file.
     * @param man     Manifest of the jarFile
     * @param jarFile jarFile for which the type is needed
     * @return type of the jarFile
     */
    private static String getType(Manifest man, File jarFile,List<File> jarsInBundle) {

        Attributes map = man.getMainAttributes();
        String name = map.getValue("Bundle-Name");
        if ((name != null && name.startsWith("org.wso2"))
                || (jarFile.getName().startsWith("org.wso2"))
                || getVersion(jarFile.getName()).contains("wso2")) {
            return "bundle";
        } else {
            boolean exist=false;
            for (File jar:jarsInBundle){
                if(jarFile.getName().equals(jar.getName())){
                    exist = true;
                }
            }
            if(exist){
                return "jarinbundle";
            } else {
                return ((getIsBundle(man)) ? "bundle" : "jar");
            }
        }
    }

    /**
     * Returns whether a given jar is a bundle or not
     * @param manifest Manifest of the jar file
     * @return true/false
     */
    private static boolean getIsBundle(Manifest manifest) {

        Attributes map = manifest.getMainAttributes();
        String bundleManifest = map.getValue("Bundle-ManifestVersion");

        return bundleManifest != null;
    }

    /**
     * Checks whether a jar file contains other jar files inside it.
     * @param filePath absolute path to the jar
     * @return true/false
     */
    private static boolean checkInnerJars(String filePath){

        boolean containsJars = false;

        try (ZipInputStream zip = new ZipInputStream(new FileInputStream(filePath))) {
            for (ZipEntry entry = zip.getNextEntry(); entry != null; entry = zip.getNextEntry()) {
                if (entry.getName().endsWith(".jar") || entry.getName().endsWith(".mar")) {
                    containsJars = true;
                    break;
                }
            }
        } catch (IOException e) {
            //do nothing
        }
        return containsJars;
    }

    private static String getDefaultName(String filename) {

        if (filename.endsWith(".jar") || filename.endsWith(".mar") || filename.endsWith(".zip")) {
            filename = filename.replace(".jar", "");
            filename = filename.replace(".mar", "");
            filename = filename.replace(".zip", "");
        }
        return filename;
    }

    public static List<File> findDirectJars(String path) {

        List<File> files = new ArrayList<>();
        Stack<File> directories = new Stack<>();
        directories.add(new File(path));
        while (!directories.empty()) {
            File next = directories.pop();
            directories.addAll(Arrays.asList(next.listFiles(File::isDirectory)));
            files.addAll(Arrays.asList(next.listFiles(
                    file -> file.getName().endsWith(".jar") || file.getName().endsWith(".mar"))));
        }
        return files;
    }

    public static String getSubString(String word) throws StringIndexOutOfBoundsException{
        String string = word;
        try {
            string = word.substring(word.indexOf(":"),word.lastIndexOf("."));
        } catch (StringIndexOutOfBoundsException e){
            return string;
        }
        return string;
    }

    /**
     * generate sas token to upload a pack to azure storage.
     * @param accountName azure storage account name
     * @param accountkey azure storage account key
     * @return sas token
     */
    public static String generateSas(String accountName, String accountKey){
        try {
            String connectionString = String.format("DefaultEndpointsProtocol=https;AccountName=%s;AccountKey=%s;", accountName, accountKey);
            CloudStorageAccount account = CloudStorageAccount.parse(connectionString);
    
            SharedAccessAccountPolicy policy = new SharedAccessAccountPolicy();
            policy.setServiceFromString("btqf");
            policy.setResourceTypeFromString("sco");
            policy.setPermissionsFromString("rwdl"); // Set the permissions you want for the SAS token
            policy.setSharedAccessStartTime(new Date(System.currentTimeMillis() - 10000)); // Set the start time for the SAS token
            policy.setSharedAccessExpiryTime(new Date(System.currentTimeMillis() + 3600000)); // Set the expiry time for the SAS token
            String sasToken = account.generateSharedAccessSignature(policy);
            return sasToken;
             
        } catch (Exception e) {
            e.printStackTrace();
            return "";
        }
          
    }

    /**
     * generate url to download a pack from azure storage.
     * @param accountName azure storage account name
     * @param accountkey azure storage account key
     * @param blobName file to be downloaded
     * @param conatinerName azure conatiner name
     * @return sas token
     */
    public static String gnerateDownloadLink(String accountName, String accountKey, String blobName, String containerName){

        try{

            String connectionString = String.format("DefaultEndpointsProtocol=https;AccountName=%s;AccountKey=%s;", accountName, accountKey);
            CloudStorageAccount account = CloudStorageAccount.parse(connectionString);
            
            CloudBlobClient blobClient = account.createCloudBlobClient();

            CloudBlobContainer container = blobClient.getContainerReference(containerName);
            CloudBlob blob = container.getBlockBlobReference(blobName);

            // Create a shared access policy with read permission and a validity of 1 hour from now
            SharedAccessBlobPolicy policy = new SharedAccessBlobPolicy();
            policy.setPermissionsFromString("r");
            policy.setSharedAccessStartTime(new Date(System.currentTimeMillis() - 10000)); // Set the start time for the SAS token
            policy.setSharedAccessExpiryTime(new Date(System.currentTimeMillis() + 3600000)); // Set the expiry time for the SAS token

            // Generate the shared access signature (SAS) token for the blob
            String sasToken = blob.generateSharedAccessSignature(policy, null);

            // Construct the downloadable link by appending the SAS token to the blob URL
            URI blobUri = blob.getUri();
            String downloadableLink = blobUri.toString() + "?" + sasToken;

            return downloadableLink;

        }catch(Exception e){
            e.printStackTrace();
            return "";
        }
    }
}
