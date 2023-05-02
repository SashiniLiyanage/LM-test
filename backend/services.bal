import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/http;
import ballerinax/azure_storage_service.blobs as azure_blobs;
import ballerina/jballerina.java;
import ballerina/io;

// database configurations
configurable string DBhost = ?;
configurable string DBuser = ?;
configurable string DBpassword = ?;
configurable string DBname = ?;
configurable int DBport = ?;

// file path configurations
configurable string PROCESSING_PATH = ?;
configurable string FILE_PATH = ?;
configurable string LICENSE_PATH = ?;
configurable string LICENSEHEADER_PATH = ?;

// email sender configurations
configurable string GMAIL_RECIPIENT = ?;
configurable string GMAIL_SENDER = ?;
configurable string GMAIL_PASSWORD = ?;

// azure storage configurations
configurable string ACCESS_KEY_OR_SAS = ?;
configurable string ACCOUNT_NAME = ?;

const int LIBRARIES_PAGE_SIZE = 100;

type Success record {|
    *http:Ok;
    json body;
|};

type InternalServerError record {|
    *http:InternalServerError;
    json body;
|};

type BadRequest record {|
    *http:BadRequest;
    json body;
|};

// database connection configuration
final mysql:Client mysqlEp= check new (
    DBhost, 
    DBuser, 
    DBpassword, 
    DBname, 
    DBport
);

// storage connection configuration 
final azure_blobs:ConnectionConfig blobServiceConfig = {
    accessKeyOrSAS: ACCESS_KEY_OR_SAS,
    accountName: ACCOUNT_NAME,
    authorizationMethod: "accessKey"
};

final azure_blobs:BlobClient blobClient = check new (
    blobServiceConfig
);

final azure_blobs:ManagementClient managementClient = check new (
    blobServiceConfig
);


service / on new http:Listener(9096) {

    resource function get getLicense() returns Success|InternalServerError {

        json|error returnedResponse = getAllLicense();
        
        if returnedResponse is json {
            Success res = {body: returnedResponse};
            return res;
        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }
    
    }

    resource function post updateLicense(@http:Payload json payload) returns Success|BadRequest|InternalServerError {

        json|error licName = payload.licName;
        json|error licUrl = payload.licUrl;
        json|error licId = payload.licId;
        json|error licKey = payload.licKey;
        json|error licCategory = payload.licCategory;
        
        if (licName is string && licUrl is string && licKey is string && licCategory is string && licId is int) {

            boolean success = updateLicense(licName, licKey, licUrl, licCategory, licId);

            if success {
                Success res = {body: "success"};
                return res;
            }

            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;

        } else {
            BadRequest res = {body: "Incorrect payload format"};
            return res;
        }
    
    }

    resource function post addLicense(@http:Payload json payload) 
        returns Success|BadRequest|InternalServerError {

        json|error licName = payload.licName;
        json|error licUrl = payload.licUrl;
        json|error licKey = payload.licKey;
        json|error licCategory = payload.licCategory;
        
        if (licName is string && licUrl is string && licKey is string && licCategory is string) {

            boolean success = addNewLicense(licName, licKey, licUrl, licCategory);

            if success {
                Success res = {body: "Success"};
                return res;
            }

            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;

        } else {
            BadRequest res = {body: "Incorrect payload format"};
            return res;   
        }    
    }

    resource function get checkLicense/[string licName]/[string licKey]() 
        returns Success|BadRequest|InternalServerError|error {

        boolean? exists = checkLicenseExists(licName, licKey);

        if (exists is boolean) {            
            Success res = {body: {exists: exists}};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }

    }

    resource function post requestLicense(@http:Payload json payload) returns Success|BadRequest|InternalServerError {

        json|error licName = payload.licName;
        json|error licUrl = payload.licUrl;
        json|error licKey = payload.licKey;
        json|error licCategory = payload.licCategory;
        json|error licReason = payload.licReason;
        
        if (licName is string && licUrl is string && licKey is string && licCategory is string 
            && licReason is string) {

            boolean success = addNewLicenseRequest(licName, licKey, licUrl, licCategory, licReason);

            if success {
                Success res = {body: "Success"};
                return res;
            }

            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;

        } else {
            BadRequest res = {body: "Incorrect payload format"};
            return res;   
        }    
    }

    resource function post approveLicense(@http:Payload json payload) returns Success|BadRequest|InternalServerError {

            json|error licId = payload.licId;
            
            if (licId is int) {

                boolean success = approveLicenseRequest(licId);

                if success {
                    Success res = {body: "Success"};
                    return res;
                }

                InternalServerError res = {body: "Error: An internal error occurred"};
                return res;

            } else {
                BadRequest res = {body: "Incorrect payload format"};
                return res;   
            }    
    }

    resource function post rejectLicense(@http:Payload json payload) returns Success|BadRequest|InternalServerError {

            json|error licId = payload.licId;
            
            if (licId is int) {

                boolean success = deleteLicenseRequest(licId);

                if success {
                    Success res = {body: "Success"};
                    return res;
                }

                InternalServerError res = {body: "Error: An internal error occurred"};
                return res;

            } else {
                BadRequest res = {body: "Incorrect payload format"};
                return res;   
            }    
    }

    resource function get getLicenseRequests() returns Success|InternalServerError {

        json|error returnedResponse = getAllLicenseRequests();
        
        if returnedResponse is json {
            Success res = {body: returnedResponse};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }
    
    }

    resource function get getLibrary() returns Success|InternalServerError {

        json| error? returnedResponse = getAllLibraries();
        
        if returnedResponse is json{
            Success res = {body: returnedResponse};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }
    }

    // searches libraries by a keyword and returns requested page, the page size is fixed
    resource function get getLibraries(int page,string query) returns Success|InternalServerError {

        json| error? returnedResponse = getLibraries(page, LIBRARIES_PAGE_SIZE, query);
        
        if returnedResponse is json{
            Success res = {body: returnedResponse};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }
    }

    resource function post updateLibrary(@http:Payload json payload) returns Success|InternalServerError|BadRequest|error {

            json|error licenses = payload.ids;
            json|error libId = payload.libId;
            
            if (libId is int && licenses is json[]) {
                boolean success = updateLibrary(licenses,libId);

                if success {
                    Success res = {body: "Success"};
                    return res; 
                }

                InternalServerError res = {body: "Error: An internal error occurred"};
                return res;

            } else {
                BadRequest res = {body: "Incorrect payload format"};
                return res;   
            }

       
    }


    resource function post addLibrary(@http:Payload json payload) returns Success|BadRequest|InternalServerError|error {

            json|error libName = payload.libFilename;
            json|error libType = payload.libType;
            json|error licenses = payload.libLicenseID;
            
            if (libName is string && libType is string && licenses is json[]) {

                boolean success = addNewLibrary(libName, libType, licenses);

                if success {
                    Success res = {body: "Success"};
                    return res;
                }

                InternalServerError res = {body: "Error: An internal error occurred"};
                return res;

            } else {
                BadRequest res = {body: "Incorrect payload format"};
                return res;   
            }    
    
    }

    resource function get getPackstatus() returns Success|BadRequest|InternalServerError {

        _ = updateInterruptedPackStatus();
        
        json|error? returnedResponse = getPackstatus();

        if returnedResponse is json {
            Success res = {body: returnedResponse};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }

    }

    resource function get getBlobData() returns Success|BadRequest|InternalServerError {

        json|error? returnedResponse = getBlobData();

        if returnedResponse is json {
            Success res = {body: returnedResponse};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }

    }

    resource function post deletePack/[string packName]() returns Success|BadRequest|InternalServerError|error {

        boolean success = deletePack(packName);

        if success {
            Success res = {body: "successfully deleted"};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }
    }

    resource function get getDownloadingText/[ string packName]() returns BadRequest|http:Response {

        string licenseFileName = getLicenseFileName(packName);
        azure_blobs:BlobResult| error result = blobClient->getBlob("container-2", licenseFileName);

        if result is error {
            BadRequest response = {body: "file does not exist!"};
            return response;
        }

        _ = deletePack(packName);

        http:Response response = new;
        response.statusCode = 200;
        response.setBinaryPayload(result.blobContent);

        return response;

    }

     resource function get getBlobFile/[ string fileName]() returns BadRequest|http:Response {

        azure_blobs:BlobResult| error result = blobClient->getBlob("container-2", fileName);

        if result is error {
            BadRequest response = {body: "file does not exist!"};
            return response;
        }
       
        http:Response response = new;
        response.statusCode = 200;
        response.setBinaryPayload(result.blobContent);

        return response;
        
    }

    resource function get gettempdata/[ string packName]() returns Success {
         
        json returnedResponse = getTemporaryData(packName);
        
        Success res = {body: returnedResponse};
        return res;
        
    }

    resource function get getallLibraryRequests() returns Success {
         
        json returnedResponse = getallLibraryRequests();
        
        Success res = {body: returnedResponse};
        return res;
        
    }

    resource function post addLibraryRequest/[string packName](@http:Payload json payload)
        returns Success|InternalServerError|BadRequest{
        
        json| error libFilename = payload.libFilename;
        json| error libLicenseID = payload.libLicenseID;
        json| error libType = payload.libType;
        json| error libLicenseURL = payload.libLicenseURL;
        json| error comment = payload.comment;

        if (libFilename is string && libType is string && libLicenseID is json[] && comment is string 
            && libLicenseURL is string) {

            boolean success = addNewLibraryRequest(packName, libFilename, libType, libLicenseID, libLicenseURL, comment);

            if success {
                Success res = {body: ()};
                return res;

            } else {
                InternalServerError res = {body: "Error: An internal error occurred"};
                return res;
            }

        } else {
            BadRequest res = {body: "Payload is not in correct format"};
            return res;
        }
    }

    resource function post addLibraryLicense/[string packName](@http:Payload json payload)
        returns Success|InternalServerError{
        
        boolean success = addLibraryLicense(payload, packName);
        
        if success {
            Success res = {body: ()};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }
    }

    resource function get checkPack/[string packName]() returns Success|BadRequest|InternalServerError|error {

        string _name = java:toString(getName(java:fromString( packName))) ?: "";
        string _version = java:toString(getVersion(java:fromString( packName))) ?: "";
        
        string FileName = _name + "-" + _version + ".zip";
        boolean? exists = checkPack(FileName);

        if exists is boolean {
            Success res = {body:{exists: exists}};
            return res;

        } else {
            InternalServerError res = {body: "Error: An internal error occurred"};
            return res;
        }

    }

    resource function post receiver/[string packName](http:Request request, http:Caller caller) returns error? {

        string _name = java:toString(getName(java:fromString( packName))) ?: "";
        string _version = java:toString(getVersion(java:fromString( packName))) ?: "";
        
        string fileName = _name + "-" + _version + ".zip";
        string randomName = getRandompackName();

        stream<byte[], io:Error?>|error streamer = request.getByteStream();

        if (streamer is stream<byte[], error?>) {

            string filePath = FILE_PATH + "/" + randomName + ".zip";
            error? saveTempFile = io:fileWriteBlocksFromStream( filePath, streamer);
            
            if (saveTempFile is error) {
                return saveTempFile;
            }

            http:Response response = new;
            response.statusCode = 200;
            response.setPayload("Pack processing will start in a minute");
            check caller->respond(response);

            _ = addPackStatus(fileName , randomName);
            _ = processPack(fileName , randomName);
            
        }else{
            return streamer;
        }
            
    }
    
}