import ballerinax/azure_storage_service.blobs as azure_blobs;
import ballerina/jballerina.java;
import ballerina/io;
import ballerina/log;
import ballerina/sql;
import ballerina/http;
import ballerina/file;

isolated function createRandomUUID() returns handle = @java:Method {
    name: "randomUUID",
    'class: "java.util.UUID"
} external;

isolated  function getJsonString(handle product, handle sourcepath, handle destinationpath, handle fileName) returns handle = @java:Method {
    name: "getJsonString",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

isolated function getSubString(handle word) returns handle = @java:Method {
    name: "getSubString",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

isolated function gnerateDownloadLink(handle accountName, handle accountKey, handle blobName, handle containerName) returns handle = @java:Method {
    name: "gnerateDownloadLink",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

isolated function getRandompackName() returns string {
    string? random = java:toString(createRandomUUID());
    if random is string {
        return random;
    }
    return "000";
}

// process all the uploaded packs
isolated function processAllPack() returns boolean {
    string packName;
    string randomName;
    json|error data;
    boolean proceed = true;

    while (proceed) {
        ProcessingPack[]|error nextPack = getNextPack();

        if nextPack is error {
            log:printError("Error in getting next packs", nextPack);
            break;
        }
        if nextPack.length() == 0 {
            log:printInfo("All the packs are processed");
            break;
        }
            
        foreach ProcessingPack pack in nextPack {

            packName = pack.PACK_NAME;
            randomName = pack.PACK_RANDOMNAME;

            _ = updateStatus(packName, "Extracting the pack", 2);
            log:printInfo("Extracting the pack");

            data = getDataJson(randomName,packName);
            _ = updateStatus(packName, "Pack is extracted", 2);
            log:printInfo("Pack is extracted");

            if(data is error){
                _ = updateStatus(packName, "Failed in Traversing Pack", 0);
                log:printError("Failed in Traversing Pack", data);

            }else if (data.status == 200) {

                _ = updateStatus(packName, "Updating database", 2);
                log:printInfo("Updating database");
                
                json|error updated = updateDatabase(data);
                _ = updateStatus(packName, "Database is updated", 2);
                log:printInfo("Database is updated");

                if (updated is json && updated.status == 200) {

                    _ = updateStatus(packName, "Generating License file", 2);
                    log:printInfo("Generating License file");

                    error? response = generateLicense(data);

                    if (response is error) {
                        _ = updateStatus(packName, "License Generation Failed", 0);
                        log:printError("License Generation Failed", response);
                    } else {
                        _ = updateStatus(packName, "License File Generated", 1);
                        log:printInfo("License File Generated");
                    }

                } else {
                    _ = updateStatus(packName, "Database Updation Failed", 0);
                    log:printInfo("Database Updation Failed");
                }
                
            } else {
                json | error withoutLicense = data.empty;
                json | error blockedLicense = data.blocked;

                if (withoutLicense is json[] && blockedLicense is json[]) {
                    if (withoutLicense.length() > 0 || blockedLicense.length() > 0) {
                        _ = updateStatus(packName, "Libraries without Licenses or with X category licenses", 3);
                        log:printInfo("Libraries without Licenses or with X category licenses");
                    } else {
                        _ = updateStatus(packName, "Failed in Traversing Pack", 0);
                        log:printInfo("Failed in Traversing Pack");
                    }
                } else {
                    _ = updateStatus(packName, "Failed in Traversing Pack", 0);
                    log:printInfo("Failed in Traversing Pack");
                }
            }
        }
    }

    return true;
}

// check if a container exists in azure storage
isolated function checkContainer(string containerName) returns error?{
    boolean exists = false;

    azure_blobs:ListContainerResult result = check blobClient->listContainers();
    azure_blobs:Container[] containers = result.containerList;

    foreach azure_blobs:Container item in containers {
        if(item.Name === containerName){
            exists = true;
        }
    }

    if(!exists){
        _ = check managementClient->createContainer(containerName);
    }

    return;
}

// download pack from azure blob
isolated  function downloadFile(string blobName, string containerName) returns error?{
    string url = java:toString(gnerateDownloadLink(java:fromString(ACCOUNT_NAME),java:fromString(ACCESS_KEY_OR_SAS),java:fromString(blobName),java:fromString("container-1"))) ?: "";

    http:Client httpEP = check new (url);
    http:Response resp = check httpEP->get("");
    stream<byte[], io:Error?> byteStream = check resp.getByteStream();
    _ = check io:fileWriteBlocksFromStream(FILE_PATH + "/" + blobName, byteStream);

}

isolated function getDataJson(string path, string packName) returns json|error {


    log:printInfo("Downloading the file... ");
    error? file = downloadFile(path +".zip", "container-1" );

    if(file is error){
        log:printError("Download failed ", file);
        return file;
    }else{
        log:printInfo("File Downloaded sucessfully");
    }

    json jsonEmpty = {};
    var jsonVar = getJsonString(java:fromString(path),java:fromString(FILE_PATH),java:fromString(PROCESSING_PATH), java:fromString(packName));
    string? jsonString = java:toString(jsonVar);

    if jsonString is string {
        if(jsonString === "Exception"){
            error err = error("Error happended in getJsonString");
            return err;
        }else{
            io:StringReader stringReader = new (jsonString, encoding = "UTF-8");
            json | error Json = stringReader.readJson();
            if Json is json {
                jsonEmpty = check UpdateLicenseID(Json);
            } else {
                log:printError("Error in converting to json", Json);
            }
        }
    } else {
        log:printError("Error: returned jsonString is not in string format", jsonString);
    }

    return checkLicense(jsonEmpty);
}

isolated function UpdateLicenseID(json DataJson) returns json|error {
    string productName = (check DataJson.packName).toString();
    string productVersion = (check DataJson.packVersion).toString();
    json | error libraries = DataJson.library;
    json[] newLibrary = [];
    int index = 0;

    if (libraries is json[]) {
        foreach  json libraryData in libraries {
            json | error lib_license = libraryData.libLicense;
            string lib_name = (check libraryData.libName).toString();
            string lib_version = (check libraryData.libVersion).toString();
            string lib_filename = (check libraryData.libFilename).toString();
            string lib_type = (check libraryData.libType).toString();

            json[] ids = [];
            if (lib_license is json[]) {
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

isolated function getLicenseID(string libName, string libVersion, json[] libUrl) returns json[] {
    json[] licenseID = getLicenseIdbyDB(libName, libVersion);
    int id;
    if (licenseID.length() === 0) {
        foreach json url in libUrl {
            id = getLicenseIdbyUrl(url.toString());
            if (id === 0) {
                string? license = java:toString(getSubString(java:fromString(url.toString())));
                if license is string {
                    id = getLicenseIdbyUrl(license);
                    if (id !== 0) {
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

isolated function getLicenseIdbyDB(string libName, string libVersion) returns int[] {
    int[] licenseID = [];
    int licenseId;
    boolean exist;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_LICENSE WHERE LIB_ID IN (SELECT LIB_ID FROM LM_LIBRARY WHERE LIB_NAME=${libName} AND LIB_VERSION=${libVersion})`;
        
    stream<Library_License, error?> queryResponse = mysqlEp->query(query);

    if (queryResponse is stream<Library_License>) {
            foreach Library_License row in queryResponse {
                licenseId = row.LIC_ID;
                exist = false;
                foreach int id in licenseID {
                    if (id == licenseId) {
                        exist = true;
                    }
                }
                if (!exist) {
                    licenseID.push(licenseId);
                }
            }       
    }

    return licenseID;
}

isolated function getLicenseIdbyUrl(string url) returns int {
    int licenseID = 0;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE WHERE LIC_URL LIKE "%${url}%"`; 
    stream<License, error?> queryResponse = mysqlEp->query(query);

    if (queryResponse is stream<License>) {
            foreach License row in queryResponse {
                licenseID = row.LIC_ID;
            }
    } 

    return licenseID;
}

isolated function checkLicense(json DataJson) returns json|error {
    int[] blockedLicenseIds = getBlockedLicenses();
    string productName = (check DataJson.packName).toString();
    string productVersion = (check DataJson.packVersion).toString();
    json | error libraries = DataJson.library;
    json[] blockedLicense = [];
    json[] withoutLicense = [];
    if (libraries is json[]) {
        foreach  json libraryData in libraries {
            
            json | error lib_license = libraryData.libLicenseID;
            if (lib_license is json[]) {
                if (lib_license.length() === 0) {
                    withoutLicense.push(libraryData);
                } else {
                    int count = 0;
                    foreach var id in lib_license {
                        foreach int blockedId in blockedLicenseIds {
                            if (<int>id == blockedId) {
                                count = count + 1;
                            }
                        }
                    }
                    if (count == lib_license.length()) {
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
        json errorData = {status: 400, packName: productName, packVersion: productVersion, blocked: blockedLicense, empty: withoutLicense};
        _ = check insertTemporaryData(errorData);

        sendEmail(errorData);
        return errorData;
    }
}

isolated function getBlockedLicenses() returns int[] {
    int[] licenseID = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE WHERE LIC_CATEGORY = "X"`;
        
    stream<License, error?> queryResponse = mysqlEp->query(query);

    if (queryResponse is stream<License>) {
            foreach License row in queryResponse {
                licenseID.push(row.LIC_ID);
            }       
    }

    return licenseID;
}

isolated function uploadPack(stream<byte[], io:Error?> streamer, string randomName) returns boolean{
    
    string filePath = FILE_PATH+"/"+randomName+".zip";
    io:Error? saveTempFile = io:fileWriteBlocksFromStream( filePath, streamer);
    
    if(saveTempFile is io:Error){
        log:printError("File saving failed");
        return false;
    }

    if(checkContainer("container-1") is error){
        log:printError("container creation failed");
        return false;
    }

    error? putBlobResult = blobClient->uploadLargeBlob("container-1", randomName+".zip", filePath);

    if(putBlobResult is error){
        log:printError("Failed to save the pack");
        return false;
    }

    error? removeTempFile = file:remove(filePath);
    if(removeTempFile is error){
        log:printError("Error in deleting temp file");
    }

    return true;
}