package org.wso2.internal.apps.license.manager;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Stack;
import java.util.UUID;
import java.util.jar.Attributes;
import java.util.jar.Manifest;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.logging.ConsoleHandler;
import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

public class TraversePack {

    private static final Logger LOGGER = Logger.getLogger("TraversePack");

    static {
        Handler consoleHandler = new ConsoleHandler();
        consoleHandler.setLevel(Level.ALL);
        LOGGER.addHandler(consoleHandler);
        LOGGER.setLevel(Level.ALL);
        LOGGER.setUseParentHandlers(false);
    }

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
                LOGGER.warning("Error getting name: " + product + " error: " + e.getMessage());
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
            LOGGER.warning("Error getting version: " + product + " error: " + e.getMessage());
            return "";
        }
    }
    /**
     * Creates a json string for the pack.
     * @param randomName : random pack name.
     */
    public static String getJsonString(String randomName, String sourcePath, String destinationPath, String fileName) {
        String extractedFilePath = destinationPath + File.separator + randomName;
        String source = sourcePath + File.separator + randomName + ".zip";
        try{
            String jsonString = "";
            String packName = getName(fileName.replace(".zip",""));
            String packVersion = getVersion(fileName.replace(".zip",""));
            jsonString += "{\"packName\":\"" + packName + "\",\"packVersion\":\"" + packVersion + "\",\"library\":";

            File destination = new File(extractedFilePath);
            destination.mkdir();
            
            String unzipPath = destination.getAbsolutePath() + File.separator + fileName.replace(".zip","");

            LicenseManagerUtils.unzip(source, unzipPath);

            String uuid = UUID.randomUUID().toString();
            String tempFolderToHoldJars = new File(unzipPath).getParent() + File.separator + uuid;
            String jsonlibrary = getjsonLiraryString(unzipPath, tempFolderToHoldJars);

            // delete the source zip file and extracted files after getting json string
            LicenseManagerUtils.deleteFolder(source);
            LicenseManagerUtils.deleteFolder(extractedFilePath);

            jsonString += jsonlibrary + "}";
            return jsonString;

        }catch(Exception e){

            LicenseManagerUtils.deleteFolder(source);
            LicenseManagerUtils.deleteFolder(extractedFilePath);

            LOGGER.severe(e.getMessage());
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
            LOGGER.info("Generating library license string");
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
                    LOGGER.warning("Error in getting manifest : " + e.getMessage());
                }
                String name = getName(fileToBeExtracted.getName());
                String version = getVersion(fileToBeExtracted.getName());
                String license = "[]";
                String type = "jar";
                String groupID = null;

                if (manifest != null) {
                    license = getLicenseUrl(manifest);
                    type =  getType(manifest, fileToBeExtracted,jarsInBundle);
                    groupID = getGroupID(manifest);
                }

                if (!(jsonlibrary.contains("libFilename\":\"" + name + "_" + version + ".jar") 
                    || jsonlibrary.contains("libFilename\":\"" + name + "-" + version + ".jar") 
                    || jsonlibrary.contains("libFilename\":\"" + name + "_" + version + ".mar") 
                    || jsonlibrary.contains("libFilename\":\"" + name + "-" + version + ".mar"))) {

                    jsonlibrary += "{\"libName\":\"" + name + "\"," +
                        "\"libVersion\":\"" + version + "\"," +
                        "\"libFilename\":\"" + fileToBeExtracted.getName() + "\"," +
                        "\"libType\":\"" + type + "\"," +
                        "\"libLicense\":" + license + "},";
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

            if(jsonlibrary.length() == 1){
                jsonlibrary = "[]";
            }else{
                jsonlibrary = jsonlibrary.substring(0, jsonlibrary.length() - 1) + "]";
            }
            
            LOGGER.info("Library license string is generated");
            return jsonlibrary;
            
        }catch(Exception e){
            LOGGER.severe("Error in getjsonLiraryString: " + e.getMessage());
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
            license = license.substring(0, license.length()-1) + "]";
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
            boolean exist = false;
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
            LOGGER.warning("Error in checkInnerJars: " + filePath + " Error:" + e.getMessage());
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

}
