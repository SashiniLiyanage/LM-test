import ballerina/log;
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/sql;
import ballerina/file;


isolated function getFormattedLibrary(handle name, handle Version, handle license) returns handle = @java:Method {
    name: "getFormattedLibrary",
    'class: "org.wso2.internal.apps.license.manager.LicenseTxtUtils"
} external;

isolated function getFormattedLicense(handle key, handle name, handle url) returns handle = @java:Method {
    name: "getFormattedLicense",
    'class: "org.wso2.internal.apps.license.manager.LicenseTxtUtils"
} external;

// generate license file
isolated function generateLicense(json dataset) returns error? {
    string packName = (check dataset.packName).toString();
    string packVersion = (check dataset.packVersion).toString();
    string textFile = packName + "-" + packVersion + ".txt";
    string licensePath = LICENSE_PATH + "/" + textFile;
    
    file:Error? createFileResults = file:create(licensePath);

    if !(createFileResults is file:Error) {
        log:printInfo("Created file path: " + licensePath);
    }
    
    io:ReadableByteChannel readableFieldResult = check io:openReadableFile(LICENSEHEADER_PATH);
    io:ReadableCharacterChannel sourceChannel = new (readableFieldResult, "UTF-8");
    io:WritableByteChannel writableFileResult = check io:openWritableFile(licensePath);
    io:WritableCharacterChannel destinationChannel = new (writableFileResult, "UTF-8");
    if dataset.status == 200 {
        var result = process(sourceChannel, destinationChannel);
        if result is error {
            log:printError("error occurred while processing chars ", result);
        } else {
            log:printInfo("File processing complete.");
        }
        json | error libraries = dataset.library;
        if libraries is json[] {
            string finalText = check getLibraryString(libraries);
            string licenseText = getLicenseDetails(libraries);
            _ = check destinationChannel.write(finalText, 0);
            _ = check destinationChannel.write(licenseText, 0);
        }
    } else {
        json | error blockedLicense = dataset.blocked;
        string text = "";
        if blockedLicense is json[] {
            if blockedLicense.length() > 0 {
                text = text + "-------------------------------\nLibraries with X category Licenses \n------------------------------- \n";
                foreach json library in blockedLicense {
                    text = text + (check library.libFilename).toString() + "\n";
                }
            }
        }
        _ = check destinationChannel.write(text, 0);
    }

    closeRc(sourceChannel);
    closeWc(destinationChannel);

    byte[] bytes = check io:fileReadBytes(LICENSE_PATH + "/" + textFile);
    string? savedname = saveBlob(textFile, bytes);

    error? removeLicense = file:remove(LICENSE_PATH + "/" + textFile);
    if removeLicense is error {
        log:printError("Error in deleting license file");
    }

    if savedname is string {
        _ = updatePackLicense(packName + "-" + packVersion + ".zip", savedname);
        log:printInfo("License file is saved");
        return;
    } else {
        log:printError("Failed to save license file");
        return error("Failed to save license file");
    }

}


isolated function process(io:ReadableCharacterChannel sc, io:WritableCharacterChannel dc) returns error? {
    string | io:Error result;
    string header = "";
    while (true) {
        result = sc.read(1000);
        if result is io:EofError {
            break;
        } else if result is error {
            return result;
        } else {
            header = header + result;
        }
    }
    _ = check dc.write(header, 0);
    return;
}


isolated function getLibraryString(json[] libraries) returns string|error {
    string finalText = "\n\n";
    string? formattedText = java:toString(getFormattedLibrary(java:fromString("Name"), java:fromString("Version"), java:fromString("License")));
    if formattedText is string {
        finalText = finalText + formattedText;
        finalText = finalText + "_______________________________________________________________________________" +
        "__________________________________________________________________\n";
    }
    foreach  json libraryData in libraries {
        string name = (check libraryData.libFilename).toString();
        string Type = (check libraryData.libType).toString();
        json | error licenseID = libraryData.libLicenseID;
        string license = "UNDEFINED";
        if licenseID is json {
            json[] Ids = <json[]>licenseID;
            //find license key
            license = getCombinedLicenseKey(Ids);
        }
        formattedText = java:toString(getFormattedLibrary(java:fromString(name), java:fromString(Type), java:fromString(license)));
        if formattedText is string {
            finalText = finalText + formattedText;
        }
    }
    return finalText;
}


isolated function getLicenseDetails(json[] libraries) returns (string) {
    int[] licenseIds = [];
    string[][] licenseDetails = [];
    string licenseText = "\n\nThe license types used by the above libraries and their information is given below:\n\n";
    foreach json libraryData in libraries {
        json | error licenseID = libraryData.libLicenseID;
        if licenseID is json {
            json[] Ids = <json[]>licenseID;
            foreach var id in Ids {
                if licenseIds.indexOf(<int>id) is int {

                } else {
                    licenseIds[licenseIds.length()] = <int>id;
                }
            }
        }
    }
    foreach int id in licenseIds {
        licenseDetails[<int>licenseIds.indexOf(id)] = getLicenseDto(id);
    }
    foreach string[] license in licenseDetails {
        string? formattedLicenseText = java:toString(getFormattedLicense(java:fromString(license[0]), java:fromString(license[1]), java:fromString(license[2])));
        if formattedLicenseText is string {
            licenseText = licenseText + formattedLicenseText;
        }
    }
    return licenseText;
}


isolated function updatePackLicense(string packName, string packLicense) returns boolean {

    sql:ParameterizedQuery query = `UPDATE LM_PROCESSING_PACK SET PACK_LICENSE=${packLicense} WHERE PACK_NAME=${packName}`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is sql:ExecutionResult {
        return true;
    } else { 
        log:printInfo("Error in updating license file", executionResult);
    }

    return false;
}


isolated function closeRc(io:ReadableCharacterChannel ch) {
    var cr = ch.close();
    if cr is error {
        log:printError("Error occurred while closing the channel: ", cr);
    }
}

isolated function closeWc(io:WritableCharacterChannel ch) {
    var cr = ch.close();
    if cr is error {
        log:printError("Error occurred while closing the channel: ", cr);
    }
}

isolated function getLicenseDto(int id) returns (string[]) {
    string[] licenseDto = [];
    
    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE WHERE LIC_ID=${id}`;
    stream<License, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<License> {
            foreach License row in queryResponse {
                licenseDto[0] = <string>row.LIC_KEY;
                licenseDto[1] = <string>row.LIC_NAME;
                licenseDto[2] = <string>row.LIC_URL;
            }
        return licenseDto;
    }
    return licenseDto;
}

isolated function getCombinedLicenseKey(json[] licenseIds) returns (string) {
    string combinedLicenseKey = getLicenseDto(<int>licenseIds[0])[0];
    int length = licenseIds.length() - 1;
    while length > 0 {
        combinedLicenseKey = combinedLicenseKey.concat(" + ", getLicenseDto(<int>licenseIds[length])[0]);
        length = length - 1;
    }
    return combinedLicenseKey;
}
