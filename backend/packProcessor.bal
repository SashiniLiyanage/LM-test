import ballerinax/azure_storage_service.blobs as azure_blobs;
import ballerina/jballerina.java;
import ballerina/io;
import ballerina/log;
import ballerina/sql;

isolated function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;

isolated  function getJsonString(handle product, handle sourcepath, handle destinationpath, handle fileName)
    returns handle = @java:Method {
    name: "getJsonString",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

isolated function getSubString(handle word) returns handle = @java:Method {
    name: "getSubString",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

isolated function getRandompackName() returns string {
    string? random = java:toString(createRandomUUID());
    if random is string {
        return random;
    }
    return "000";
}

// process the uploaded packs
isolated function processPack(string packName, string randomName) returns boolean {
    json|error data;

    _ = updateStatus(packName, "Extracting the pack", PROCESSING_STATE);
    log:printInfo("Extracting the pack");

    var jsonVar = getJsonString(java:fromString(randomName), java:fromString(FILE_PATH),
        java:fromString(PROCESSING_PATH), java:fromString(packName));

    string jsonString = java:toString(jsonVar) ?: "";

    data = getDataJson(randomName, packName, jsonString);
    _ = updateStatus(packName, "Pack is extracted", PROCESSING_STATE);
    log:printInfo("Pack is extracted");

    if data is error {
        _ = updateStatus(packName, "Failed in Traversing Pack", FAILED_STATE);
        log:printError("Failed in Traversing Pack", data);

    } else if data.status == 200 {
        _ = updateStatus(packName, "Updating database", PROCESSING_STATE);
        log:printInfo("Updating database");
        
        json|error updated = updateDatabase(data);
        _ = updateStatus(packName, "Database is updated", PROCESSING_STATE);
        log:printInfo("Database is updated");

        if (updated is json && updated.status == 200) {

            _ = updateStatus(packName, "Generating License file", PROCESSING_STATE);
            log:printInfo("Generating License file");

            error? response = generateLicense(data);

            if response is error {
                _ = updateStatus(packName, "License Generation Failed", FAILED_STATE);
                log:printError("License Generation Failed", response);
            } else {
                _ = updateStatus(packName, "License File Generated", SUCCESS_STATE);
                log:printInfo("License File Generated");
            }

        } else {
            _ = updateStatus(packName, "Database Updation Failed", FAILED_STATE);
            log:printInfo("Database Updation Failed");
        }
        
    } else {
        json|error withoutLicense = data.empty;
        json|error blockedLicense = data.blocked;
            
        if (withoutLicense is json[] && blockedLicense is json[] 
            && (withoutLicense.length() > 0 || blockedLicense.length() > 0)) {
                                
            error? saved = savePackData(packName, jsonString);

            if saved is error {
                _ = updateStatus(packName, "Failed in Traversing Pack", FAILED_STATE);
                log:printInfo("Failed in saving temporary pack data");
            } else {
                _ = updateStatus(packName, "Libraries without Licenses or with X category licenses", BLOCKED_STATE);
                log:printInfo("Libraries without Licenses or with X category licenses");
            }

        } else {
            _ = updateStatus(packName, "Failed in Traversing Pack", FAILED_STATE);
            log:printInfo("Failed in Traversing Pack");
        }
    }

    return true;
}

// Regenerate the license file after updating libraries without licenses
isolated function regenerateLicenseFile(string packName) returns boolean {
    
    TemporaryPack[]|error libraries = getTemporaryPackData(packName);

    string _name = java:toString(getName(java:fromString(packName))) ?: "";
    string _version = java:toString(getVersion(java:fromString(packName))) ?: "";

    string jsonString = "{\"packName\":\"" + _name + "\",\"packVersion\":\"" + _version + "\",\"library\":";
    string jsonlibrary = "[";

    if libraries is error {
        _ = updateStatus(packName, "Failed in Traversing Pack", FAILED_STATE);
        log:printInfo("Failed in getting temporary pack data");
        return false;
    } else {
        foreach TemporaryPack library in libraries {
            jsonlibrary += "{\"libName\":\"" + library.LIB_NAME + "\","
            + "\"libVersion\":\"" + library.LIB_VERSION + "\"," 
            + "\"libFilename\":\"" + library.LIB_FILENAME + "\","
            + "\"libType\":\"" + library.LIB_TYPE + "\"," 
            + "\"libLicense\":" + library.LIB_LICENSE +"},";
        }
    }

    if jsonlibrary.length() == 1 {
        jsonlibrary = "[]";
    } else {
        jsonlibrary = jsonlibrary.substring(0, jsonlibrary.length() - 1) + "]";
    }            

    jsonString += jsonlibrary + "}";

    string randomName = getPackRandomName(packName);
    json|error data = getDataJson(randomName, packName, jsonString);

    _ = updateStatus(packName, "Pack is extracted", PROCESSING_STATE);
    log:printInfo("Pack is extracted");

    if data is error {
        _ = updateStatus(packName, "Failed in Traversing Pack", FAILED_STATE);
        log:printError("Failed in Traversing Pack", data);

    }else if data.status == 200 {
        _ = updateStatus(packName, "Updating database", PROCESSING_STATE);
        log:printInfo("Updating database");
        
        json|error updated = updateDatabase(data);
        _ = updateStatus(packName, "Database is updated", PROCESSING_STATE);
        log:printInfo("Database is updated");

        if (updated is json && updated.status == 200) {

            _ = updateStatus(packName, "Generating License file", PROCESSING_STATE);
            log:printInfo("Generating License file");

            error? response = generateLicense(data);

            if response is error {
                _ = updateStatus(packName, "License Generation Failed", FAILED_STATE);
                log:printError("License Generation Failed", response);
            } else {
                _ = updateStatus(packName, "License File Generated", SUCCESS_STATE);
                log:printInfo("License File Generated");
            }

        } else {
            _ = updateStatus(packName, "Database Updation Failed", FAILED_STATE);
            log:printInfo("Database Updation Failed");
        }
        
    } else {
        _ = updateStatus(packName, "Failed in Traversing Pack", FAILED_STATE);
        log:printInfo("Failed in regenerating license file");  
    }

    return true;
}

// check if a container exists in azure storage
isolated function checkContainer(string containerName) returns error?{
    boolean exists = false;

    azure_blobs:ListContainerResult result = check blobClient->listContainers();
    azure_blobs:Container[] containers = result.containerList;

    foreach azure_blobs:Container item in containers {
        if item.Name === containerName {
            exists = true;
        }
    }

    if !exists {
        _ = check managementClient->createContainer(containerName);
    }

    return;
}

// Get json data from extracted pack
isolated function getDataJson(string randomName, string packName, string jsonString) returns json|error {

    json jsonEmpty = {};
    
    if jsonString === "Exception" {
        error err = error("Error happended in getJsonString");
        return err;
    } else {
        io:StringReader stringReader = new (jsonString, encoding = "UTF-8");
        json|error Json = stringReader.readJson();
        if Json is json {
            jsonEmpty = check UpdateLicenseID(Json);
        } else {
            log:printError("Error in converting to json", Json);
        }
    }

    return checkLicense(jsonEmpty);
}

// update license ids for libraries
isolated function UpdateLicenseID(json DataJson) returns json|error {
    string productName = (check DataJson.packName).toString();
    string productVersion = (check DataJson.packVersion).toString();
    json|error libraries = DataJson.library;
    json[] newLibrary = [];
    int index = 0;

    if libraries is json[] {
        foreach  json libraryData in libraries {
            json|error lib_license = libraryData.libLicense;
            string lib_name = (check libraryData.libName).toString();
            string lib_version = (check libraryData.libVersion).toString();
            string lib_filename = (check libraryData.libFilename).toString();
            string lib_type = (check libraryData.libType).toString();

            json[] ids = [];
            if lib_license is json[] {
                ids = getLicenseID(lib_name, lib_version, lib_license);
            }
            json libObject = {
                libName: lib_name,
                libVersion: lib_version,
                libFilename: lib_filename,
                libType: lib_type,
                libLicenseID: ids
            };
            newLibrary[index] = libObject;
            index = index + 1;
        }
    } else {
        log:printError("Error: libraries in not a json array ");
    }
    json finalDataJson = {status: 200, packName: productName, packVersion: productVersion, library: newLibrary};
    return finalDataJson;
}

// Get license ids for a library
isolated function getLicenseID(string libName, string libVersion, json[] libUrl) returns json[] {
    json[] licenseID = getLicenseIdbyDB(libName, libVersion);
    int id;
    if licenseID.length() === 0 {
        foreach json url in libUrl {
            id = getLicenseIdbyUrl(url.toString());
            if id === 0 {
                string? license = java:toString(getSubString(java:fromString(url.toString())));
                if license is string {
                    id = getLicenseIdbyUrl(license);
                    if id !== 0 {
                        licenseID.push(id);
                    }
                } else {
                    log:printError("Error: License is not in string format ", license);
                }
            } else {
                licenseID.push(id);
            }
        }
        return licenseID;
    } else {
        return licenseID;
    }
}

// Get license Id by from the database
isolated function getLicenseIdbyDB(string libName, string libVersion) returns int[] {
    int[] licenseID = [];
    int licenseId;
    boolean exist;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_LICENSE WHERE LIB_ID IN (SELECT LIB_ID FROM LM_LIBRARY WHERE LIB_NAME=${libName} AND LIB_VERSION=${libVersion})`;
        
    stream<Library_License, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<Library_License> {
            foreach Library_License row in queryResponse {
                licenseId = row.LIC_ID;
                exist = false;
                foreach int id in licenseID {
                    if id == licenseId {
                        exist = true;
                    }
                }
                if !exist {
                    licenseID.push(licenseId);
                }
            }       
    }

    return licenseID;
}

// Get license Id that matches with the url
isolated function getLicenseIdbyUrl(string url) returns int {
    int licenseID = 0;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE WHERE LIC_URL LIKE "%${url}%"`; 
    stream<License, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<License> {
            foreach License row in queryResponse {
                licenseID = row.LIC_ID;
            }
    } 

    return licenseID;
}

// check if there are libraries without licenses or blocked licenses
isolated function checkLicense(json DataJson) returns json|error {
    int[] blockedLicenseIds = getBlockedLicenses();
    string productName = (check DataJson.packName).toString();
    string productVersion = (check DataJson.packVersion).toString();
    json|error libraries = DataJson.library;
    json[] blockedLicense = [];
    json[] withoutLicense = [];
    if libraries is json[] {
        foreach  json libraryData in libraries {
            
            json|error lib_license = libraryData.libLicenseID;
            if lib_license is json[] {
                if lib_license.length() === 0 {
                    withoutLicense.push(libraryData);
                } else {
                    int count = 0;
                    foreach var id in lib_license {
                        foreach int blockedId in blockedLicenseIds {
                            if <int>id == blockedId {
                                count = count + 1;
                            }
                        }
                    }
                    if count == lib_license.length() {
                        blockedLicense.push(libraryData);
                    }
                }
            } else {
                log:printError("Error: Library licenses are not in json array format ");
            }
        }
    } else {
        log:printError("Error : Libraries are not in json array format ");
    }
    if (blockedLicense.length() == 0 && withoutLicense.length() == 0) {
        log:printInfo(productName + "-" + productVersion + " has been successfully traversed");
        return DataJson;
    } else {
        
        log:printInfo(productName + "-" + productVersion + " has been identified with libraries without license");
        json errorData = {
            status: 400,
            packName: productName,
            packVersion: productVersion,
            blocked: blockedLicense,
            empty: withoutLicense
        };
        _ = check insertTemporaryData(errorData);

        sendEmail(errorData);
        return errorData;
    }
}

// Get all the blocked license Ids
isolated function getBlockedLicenses() returns int[] {
    int[] licenseID = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE WHERE LIC_CATEGORY = "X"`;
        
    stream<License, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<License> {
            foreach License row in queryResponse {
                licenseID.push(row.LIC_ID);
            }       
    }

    return licenseID;
}