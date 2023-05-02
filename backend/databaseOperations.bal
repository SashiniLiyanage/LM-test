import ballerinax/mysql.driver as _;
import ballerina/sql;
import ballerina/jballerina.java;
import ballerina/log;
import ballerina/io;

type License record {|
    int LIC_ID;
    string LIC_KEY;
    string LIC_NAME;
    string LIC_URL;
    string? LIC_CATEGORY;
|};

type LicenseRequest record {|
    int LIC_ID;
    string LIC_KEY;
    string LIC_NAME;
    string LIC_URL;
    string LIC_CATEGORY;
    string? LIC_REASON;
|};

type Updated_License record{|
    int value;
    string label;
|};

type Library record {|
    int LIB_ID;
    string LIB_FILENAME;
    string LIB_TYPE;
    string LIB_NAME?;
    string LIB_VERSION?;
    string LIC_KEY?;
|};

type LibraryRequest record {|
    int LIB_ID;
    string PACK_NAME;
    string LIB_FILENAME;
    string LIB_TYPE;
    string LIC_URL;
    string COMMENT;
|};

type Library_License record {|
    int LIB_ID;
    int LIC_ID;
|};

type ProcessingPack record {|
    string PACK_NAME;
    string PACK_RANDOMNAME;
    string? PACK_STATUS;
    string? PACK_LICENSE;
    string? PACK_TIMESTAMP;
    int PACK_STATUS_CODE;
|};

type TemporaryPack record {|
    string PACK_NAME;
    string LIB_NAME;
    string LIB_VERSION;
    string LIB_FILENAME;
    string LIB_TYPE;
    string LIB_LICENSE;
|};

type Product record {|
    int PROD_ID;
    string PROD_NAME;
    string PROD_VERSION;
|};

type Temporary record {|
    string PACK_NAME;
    string LIB_FILENAME;
    string LIB_TYPE;
    string BLOCKED;
|};

type LicenceBlob record {|
    int BLOB_ID;
    string FILENAME;
    string BLOB_NAME;
    string BLOB_TIMESTAMP;
|};

enum StatusCode {
    FAILED_STATE = "0",
    SUCCESS_STATE = "1",
    PROCESSING_STATE = "2",
    BLOCKED_STATE = "3"
}

// get name of the pack
isolated function getName(handle product) returns handle = @java:Method {
    name: "getName",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

// get version of the pack
isolated function getVersion(handle product) returns handle = @java:Method {
    name: "getVersion",
    'class: "org.wso2.internal.apps.license.manager.TraversePack"
} external;

// get all licenses
isolated function getAllLicense() returns json|error {

    License[] license_list = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_License`;

    stream<License, error?> queryResponse = mysqlEp->query(query);

    check from License item in queryResponse
        do {license_list.push(item);};
    check queryResponse.close();

    return license_list.toJson();

}

// get all requested licenses
isolated function getAllLicenseRequests() returns json|error {

    LicenseRequest[] license_list = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_License_Requests`;

    stream<LicenseRequest, error?> queryResponse = mysqlEp->query(query);

    check from LicenseRequest item in queryResponse
        do {license_list.push(item);};
    check queryResponse.close();

    return license_list.toJson();

}

// approve a license
isolated function approveLicenseRequest(int licId) returns boolean {

    LicenseRequest request;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE_REQUESTS WHERE LIC_ID=${licId}`;
    stream<LicenseRequest, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<LicenseRequest> {
        LicenseRequest[] license_list  = from LicenseRequest item in queryResponse select item;
        request = license_list[0];
    } else {
        log:printError("Error in getting license requests");
        return false;
    }

    boolean success = addNewLicense(request.LIC_NAME, request.LIC_KEY, request.LIC_URL, request.LIC_CATEGORY);

    if success {
        _ = deleteLicenseRequest(licId);
    }

    return success;

}

// delete license request
isolated function deleteLicenseRequest(int licId) returns boolean {

    sql:ParameterizedQuery query = `DELETE FROM LM_LICENSE_REQUESTS WHERE LIC_ID=${licId}`;    
    sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);
    
    if(executionResult is sql:ExecutionResult){
        return true;
    } else {
        log:printError("Error in inserting license", executionResult);
        return false;
    }


}

// insert new license
isolated function addNewLicense(string licName, string licKey, string licUrl,string licCategory) returns boolean {

    sql:ParameterizedQuery query = `INSERT INTO LM_LICENSE (LIC_NAME,LIC_KEY,LIC_URL, LIC_CATEGORY) 
        VALUES (${licName},${licKey},${licUrl},${licCategory})`;
    sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);

    if(executionResult is sql:ExecutionResult){
        return true;
    } else {
        log:printError("Error in inserting license", executionResult);
        return false;
    }

   
}

// check if license exists
isolated function checkLicenseExists(string licName, string licKey) returns boolean? {
    
    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSE WHERE LIC_NAME=${licName} OR LIC_KEY=${licKey}`;
    stream<License, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<License> {
        
        License[] license_list  = from License item in queryResponse select item;
        return license_list.length() > 0 ;

    } else {
        log:printError("Error in getting processing packs");
        return;
    }  
}

// insert new license request
isolated function addNewLicenseRequest(string licName, string licKey, string licUrl, string licCategory,
    string licReason) returns boolean {

    sql:ParameterizedQuery query = `INSERT INTO LM_LICENSE_REQUESTS (LIC_NAME,LIC_KEY,LIC_URL, LIC_CATEGORY, LIC_REASON)
        VALUES (${licName},${licKey},${licUrl},${licCategory},${licReason})`;
    sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);

    if(executionResult is sql:ExecutionResult){
        return true;
    } else {
        log:printError("Error in inserting license request", executionResult);
        return false;
    }
}

// get all libraries
isolated  function getAllLibraries() returns json| error?{

    Library[] all_library_list = [];

    sql:ParameterizedQuery query = `SELECT LIB_ID,LIB_FILENAME,LIB_TYPE,LIC_KEY FROM LM_LIBRARY_LICENSE 
        INNER JOIN LM_LICENSE USING (LIC_ID) INNER JOIN LM_LIBRARY USING (LIB_ID) ORDER BY LIB_ID`;
    stream<Library, error?> queryResponse = mysqlEp->query(query);

    check from Library item in queryResponse
        do {all_library_list.push(item);};
    check queryResponse.close();

    return all_library_list.toJson();
}

// search libraries by a keyword. if keyword is empty, returns all libraries in given page.
isolated  function getLibraries(int pageNum, int pageSize, string searchTerm) returns json| error?{

    Library[] library_list = [];
    string term = "%" + searchTerm + "%";
    sql:ParameterizedQuery query = 
        `
            SELECT LIB_ID,LIB_FILENAME,LIB_TYPE,LIC_KEY 
            FROM LM_LIBRARY_LICENSE 
            INNER JOIN LM_LICENSE USING (LIC_ID) 
            INNER JOIN LM_LIBRARY USING (LIB_ID)
            WHERE LIB_FILENAME LIKE ${term} OR LIB_TYPE LIKE ${term} OR LIC_KEY LIKE ${term}
            ORDER BY LIB_ID 
            LIMIT ${pageSize} OFFSET ${(pageNum) * pageSize}
        `;

    stream<Library, error?> queryResponse = mysqlEp->query(query);

    check from Library item in queryResponse
        do {library_list.push(item);};
    check queryResponse.close();

    return library_list.toJson();
}

// update license
isolated function updateLicense(string licName, string licKey, string licUrl, string licCategory, int licId) returns boolean {
    
    sql:ParameterizedQuery query = `UPDATE LM_LICENSE SET LIC_NAME=${licName}, LIC_KEY=${licKey},
        LIC_URL=${licUrl}, LIC_CATEGORY=${licCategory} WHERE LIC_ID=${licId}`;
    sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);

    if(executionResult is sql:ExecutionResult){
        return true;
    } else {
        log:printError("Error in updating licenses", executionResult);
        return false;
    }
}

// update library
isolated function updateLibrary(json[] licenses, int libId) returns boolean {

    boolean success = deleteLibraryLicense(libId);

    if success {
        foreach json license in licenses {
            json|error licId = license.value;

            if licId is int {
                boolean insert = insertLibraryLicenseData(libId, licId);
                if !insert {
                    return false;
                }
            } else {
                log:printError("License Id is not an integer");
                return false;
            }
        }
        return true;
    }
    
    return false;
}


// add new library
isolated function addNewLibrary(string libName, string libType, json[] licenses) returns boolean {

    string _filename = libName;
    string _type = libType;

    string _name = java:toString(getName(java:fromString(_filename))) ?: "";
    string _version = java:toString(getVersion(java:fromString(_filename))) ?: "";
    
    int[] licenseID = [];
    foreach json license in licenses {
        json|error value = license.value;
        if value is int {
            licenseID.push(value);
        } else {
            log:printError("Error: Invalid licence id");
            return false;
        }
    }

    json data = {libName: _name, libVersion: _version, libFilename: _filename, libType: _type, libLicenseID: licenseID};
    
    int libraryID = insertLibraryJson(data);
    if libraryID != 0 {
        return true;
    }
   
    return false;
}

// delete library-license entry
isolated function deleteLibraryLicense(int libId) returns boolean {

    sql:ParameterizedQuery query = `DELETE FROM LM_LIBRARY_LICENSE WHERE LIB_ID=${libId}`;    
    sql:ExecutionResult|sql:Error result = mysqlEp->execute(sqlQuery = query);

    if result is sql:ExecutionResult {
        return true;
    } else {
        log:printError("Error in deleting library licenses ", result);
        return false ;
    }
    
}

// check if processing pack exists
isolated  function checkPack(string packName) returns boolean? {

    sql:ParameterizedQuery query = `SELECT * FROM LM_PROCESSING_PACK WHERE PACK_NAME=${packName}`;
    stream<ProcessingPack, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<ProcessingPack> {
        
        ProcessingPack[] processing_pack_list  = from ProcessingPack item in queryResponse select item;

        return processing_pack_list.length() > 0 ;

    } else {
        log:printError("Error in getting processing packs");
        return;
    }  
}

// get all pack status
isolated function getPackstatus() returns json| error? {
    
    ProcessingPack[] processing_pack_list = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_PROCESSING_PACK ORDER BY PACK_TIMESTAMP`;
    stream<ProcessingPack, error?> queryResponse = mysqlEp->query(query);

    check from ProcessingPack item in queryResponse
        do {processing_pack_list.push(item);};
    check queryResponse.close();

    return processing_pack_list.toJson();
}

// Update status of the packs that are processing for more than an hour
isolated function updateInterruptedPackStatus() returns boolean {
    string newStatus = "Processing for more than 30 Minutes";
    string newStatusCode = FAILED_STATE;

    sql:ParameterizedQuery query = `UPDATE LM_PROCESSING_PACK SET PACK_STATUS=${newStatus}, PACK_STATUS_CODE=${newStatusCode}, PACK_TIMESTAMP=NOW() 
        WHERE PACK_TIMESTAMP < DATE_SUB(NOW(), INTERVAL 30 MINUTE) AND PACK_STATUS_CODE = 2`;
    sql:ExecutionResult|sql:Error result = mysqlEp->execute(sqlQuery = query);

    if result is sql:ExecutionResult {
        return true;
    }else{
        log:printError("Error in updating packs that are in processing state for more than 30 Minutes ", result);
        return false ;
    }
}

// add pack status
isolated function addPackStatus(string packName, string randomName) returns boolean {

    
    sql:ParameterizedQuery query = `INSERT INTO LM_PROCESSING_PACK (PACK_NAME, PACK_STATUS, PACK_RANDOMNAME,PACK_LICENSE)
        VALUES (${packName},"uploaded",${randomName},NULL)`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if(executionResult is sql:ExecutionResult){
        return true;
    } else {
        log:printError("Error in inserting pack status", executionResult);
        return false;
    }
}

// update status of a pack
isolated function updateStatus(string packName, string status, string statusCode) returns boolean {

    sql:ParameterizedQuery query = `UPDATE LM_PROCESSING_PACK SET PACK_STATUS=${status},PACK_STATUS_CODE=${statusCode}, PACK_TIMESTAMP=NOW()
        WHERE PACK_NAME=${packName}`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is sql:ExecutionResult {
        return true;
    } else {
        log:printError("Error in updating status", executionResult);
    }

    return false;
}

// insert data about library without licenses
isolated function insertTemporaryData(json errorData) returns error? {

    string packName = (check errorData.packName).toString() + "-" + (check errorData.packVersion).toString() + ".zip";
    json|error emptyData = errorData.empty;
    json|error blockedData = errorData.blocked;

    if (emptyData is json[] && blockedData is json[]) {
        _ = check insert(emptyData, packName, 0);
        _= check insert(blockedData, packName, 1);
    } else {
        log:printError("Error in fetching temporary data from the json created after traversing");
    }

}

// insert extracted pack data when libraries without licenses are found
isolated function savePackData(string packName, string packData) returns error? {

    io:StringReader stringReader = new (packData, encoding = "UTF-8");
    json|error Json = stringReader.readJson();

    if Json is json {
        json libraries = check Json.library;

        if libraries is json[] {
            foreach  json libraryData in libraries {
                json|error lib_license = libraryData.libLicense;
                string lib_name = (check libraryData.libName).toString();
                string lib_version = (check libraryData.libVersion).toString();
                string lib_filename = (check libraryData.libFilename).toString();
                string lib_type = (check libraryData.libType).toString();

                if lib_license is json[] {
                    string libLicense = lib_license.toJsonString();
                    _ = check insertTempPackData(packName, lib_name, lib_version, lib_filename, lib_type, libLicense);
                }
            }
        }
    } else {
        log:printError("Error in converting to json", Json);
        return Json;
    }
}

isolated function insertTempPackData(string packName, string libName, string libVersion, string fileName, string libType,
    string libLicense) returns error? {

    sql:ParameterizedQuery query = `INSERT INTO LM_TEMPORARY_PACK_DATA (PACK_NAME, LIB_NAME, LIB_VERSION, LIB_FILENAME,
        LIB_TYPE, LIB_LICENSE) VALUES (${packName},${libName},${libVersion},${fileName},${libType},${libLicense})`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is error {
        log:printError("Error in inserting temp data", executionResult);
        return executionResult;
    }
    return;
}

// insert status of library without licenses
isolated function insert(json[] temData, string packName, int status) returns boolean|error {
    string libFilename;
    string libType;

    foreach json library in temData {
        libFilename = (check library.libFilename).toString();
        libType = (check library.libType).toString();      

        sql:ParameterizedQuery query = `INSERT INTO LM_TEMPORARY_TABLE (PACK_NAME, LIB_FILENAME, LIB_TYPE, BLOCKED)
            VALUES (${packName},${libFilename},${libType},${status})`;
        sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

        if executionResult is error {
            log:printError("Error in inserting temp data", executionResult);
            return false;
        }
    }
    return true;
}

// delete packs status
isolated  function deletePack(string packName) returns boolean {

    sql:ParameterizedQuery query = `DELETE FROM LM_PROCESSING_PACK WHERE PACK_NAME=${packName}`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is sql:ExecutionResult {
        return true;

    } else {
        log:printError("Error in deleting pack name ", executionResult);
        return false;
    }
}

// get license filename of the pack
isolated function getLicenseFileName(string packName) returns string {
    string licenseFileName = "";

    sql:ParameterizedQuery query = `SELECT * FROM LM_PROCESSING_PACK WHERE PACK_NAME=${packName}`;
    stream<ProcessingPack, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<ProcessingPack> {
        foreach ProcessingPack row in queryResponse {
            licenseFileName = row.PACK_LICENSE ?: "";
        }
        return licenseFileName;
    } else {
        log:printError("Error in getting random pack name");
        return licenseFileName;
    }
   
}

// get random name of the pack
isolated function getPackRandomName(string packName) returns string {
    string randomName = "";

    sql:ParameterizedQuery query = `SELECT * FROM LM_PROCESSING_PACK WHERE PACK_NAME=${packName}`;
    stream<ProcessingPack, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<ProcessingPack> {
        foreach ProcessingPack row in queryResponse {
            randomName = row.PACK_RANDOMNAME;
        }
        return randomName;
    } else {
        log:printError("Error in getting random pack name");
        return randomName;
    }
   
}

// get temporary data about blocked and libraries without licenses
isolated function getTemporaryData(string packName) returns json {
    json[] librariesWithoutLicense = getData(packName, 0);
    json[] librariesWithblockedLicense = getData(packName, 1);

    return {emptyLibrary: librariesWithoutLicense, blockedLibrary: librariesWithblockedLicense};
}

// get all requests data about libraries without licenses
isolated function getallLibraryRequests() returns json {

    json[] library_list = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_REQUEST`;
    stream<LibraryRequest, error?> queryResponse = mysqlEp->query(query);
    
    if queryResponse is stream<LibraryRequest> {
        foreach LibraryRequest item in queryResponse {
            int[] licenseID = getLibraryLicenseId(item.LIB_ID);
            json library = {...item, licenseID};
            library_list.push(library);
        }
    } else {
        log:printError("Error in getting temporary data");
    }
 
    return library_list.toJson();
}

// get license IDs under one library
isolated function getLibraryLicenseId(int libId) returns int[]{
    int[] licenseId = [];
    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_LICENSE_REQUEST WHERE LIB_ID=${libId}`;
    stream<Library_License, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<Library_License> {
        foreach Library_License item in queryResponse {
            licenseId.push(item.LIC_ID);
        }
    }
    return licenseId;
}

// get data from LM_TEMPORARY_TABLE
isolated function getData(string packName, int status) returns json[] {

    json[] jsonArray = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_TEMPORARY_TABLE WHERE PACK_NAME=${packName} AND BLOCKED=${status}`;
    stream<Temporary, error?> queryResponse = mysqlEp->query(query);
    
    if queryResponse is stream<Temporary> {
        foreach Temporary item in queryResponse {
            jsonArray.push({LIB_FILENAME: item.LIB_FILENAME, LIB_TYPE: item.LIB_TYPE});
        }
    } else {
        log:printError("Error in getting temporary data");
    }

    return jsonArray;
}

// get data from LM_TEMPORARY_PACK_DATA
isolated function getTemporaryPackData(string packName) returns TemporaryPack[]|error {

    TemporaryPack[] tempPack = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_TEMPORARY_PACK_DATA WHERE PACK_NAME=${packName}`;
    stream<TemporaryPack, error?> queryResponse = mysqlEp->query(query);

    check from TemporaryPack item in queryResponse
        do {tempPack.push(item);};
    check queryResponse.close();

    return tempPack;
}


// insert new library request
isolated function addNewLibraryRequest(string packName, string libName, string libType, json[] licenses,
    string url, string comment) returns boolean {

    int[] licenseID = [];

    foreach json license in licenses {
        json|error value = license.value;
        if value is int {
            licenseID.push(value);
        } else {
            log:printError("Error: Invalid licence id");
            return false;
        }
    }

    json data = {libName, packName, libType, libLicenseID: licenseID, url, comment};
    
    int libraryID = insertLibraryRequestJson(data);

    if libraryID != 0 {
        _ = deleteTemporaryData(packName, libName);
        return true;
    }
   
    return false;
}

// add updated library with licenses
isolated function addLibraryLicense(json library, string packName) returns boolean {

    json|error license;

    license = library.libLicenseID;

    if license is json[] {
        
        json|error libName = library.libFilename;
        json|error libType = library.libType;

        if(libName is string && libType is string && addNewLibrary(libName, libType, license)){
            _ = deleteLibraryRequest(packName, libName);
        }
            
    } else {
        log:printError("error in json format for licenses added to libraries without license");
    }
    
    json jsonObject = getTemporaryData(packName);
    json|error empty = jsonObject.emptyLibrary;
    json|error blocked = jsonObject.blockedLibrary;
    boolean checkRequests = getRequestsData(packName);

    if (empty is json[] && empty.length() == 0 && blocked is json[] && blocked.length() == 0 && !checkRequests) {
        _ = regenerateLicenseFile(packName);
    }
    
    return true;
}

// delete temporary data
isolated function deleteTemporaryData(string packName, string libraryName) returns boolean {
    
    sql:ParameterizedQuery query = `DELETE FROM LM_TEMPORARY_TABLE WHERE PACK_NAME=${packName} AND LIB_FILENAME=${libraryName}`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is sql:ExecutionResult {
        return true;
    } else {
        log:printError("Error in deleting temporary data", executionResult);
        return false;
    }

}

// delete library requests
isolated function deleteLibraryRequest(string packName, string libraryName) returns boolean {
    
    sql:ParameterizedQuery query = `DELETE FROM LM_LIBRARY_REQUEST WHERE PACK_NAME=${packName}
        AND LIB_FILENAME=${libraryName}`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is sql:ExecutionResult {
        return true;
    } else {
        log:printError("Error in deleting temporary data", executionResult);
        return false;
    }

}

// get requested data of a one pack
isolated function getRequestsData(string packName) returns boolean {

    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_REQUEST WHERE PACK_NAME=${packName}`;
    stream<LibraryRequest, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<LibraryRequest> {
        LibraryRequest[] library_list  = from LibraryRequest item in queryResponse select item;
        return library_list.length() > 0 ;
    } else {
        log:printError("Error in selecting library requests");
        return false;
    }
}

// save the license file in a container
isolated function saveBlob(string  licenseFileName, byte[] blobContent) returns string? {

    if(checkContainer("container-2") is error){
        log:printError("container creation failed");
        return;
    }

    string blobName = getRandompackName() + "_" + licenseFileName;
    map<json>|error putBlobResult = blobClient->putBlob("container-2", blobName, "BlockBlob", blobContent);
    
    sql:ParameterizedQuery query = `INSERT INTO LM_LICENSEFILE_BLOB (FILENAME, BLOB_NAME, BLOB_TIMESTAMP)
        VALUES (${licenseFileName},${blobName},NOW())`;
    sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);

    if (executionResult is sql:Error || putBlobResult is error) {
        log:printError("Failed to save blob");
        return;
    } else {
        log:printInfo("Blob is saved");
        return blobName;
    }
}

// get all saved license files
isolated function getBlobData() returns json|error{

    LicenceBlob[] blob_list = [];

    sql:ParameterizedQuery query = `SELECT * FROM LM_LICENSEFILE_BLOB ORDER BY BLOB_ID DESC`;
    stream<LicenceBlob, error?> queryResponse = mysqlEp->query(query);

    check from LicenceBlob item in queryResponse
        do {blob_list.push(item);};
    check queryResponse.close();

    return blob_list.toJson();
}
