package org.wso2.internal.apps.license.manager;

public class LicenseTxtUtils {

    public static String getFormattedLibrary(String name, String type, String license) {
        String finalLibraryText = String.format("%-100s%-15s%-20s\n", name, type, license);
        return finalLibraryText;
    }
    public static String getFormattedLicense(String key, String name, String url) {
        String finalLicenseText = String.format("%-15s%s\n%-15s%s\n", key, name, "", url);
        return finalLicenseText;
    }
}
