import ballerina/log;
import ballerina/sql;

// insert list of licenses for a library
isolated function insertLibraryJson(json libraryData) returns int {
	json|error  _name = libraryData.libName;
    json|error _version = libraryData.libVersion;
    json|error _filename = libraryData.libFilename;
    json|error _type = libraryData.libType;
    json|error _licenseID = libraryData.libLicenseID;

    int libraryID = 0;

    if (_licenseID is int[] && _name is string && _version is string && _filename is string && _type is string ) {
        
        libraryID = insertLibraryData(_name, _version, _filename, _type);

        if libraryID != 0 {
            foreach int id in _licenseID {
                boolean success = insertLibraryLicenseData(libraryID, id);

                if !success {
                    return 0;
                }
            }
        } else {
            log:printError("Error: Library does not exists: ");
        }
    } 

    return libraryID;
}

// insert list of licenses for a requested library
isolated function insertLibraryRequestJson(json libraryData) returns int {
	json|error libName = libraryData.libName;
    json|error libType = libraryData.libType;
    json|error licenseID = libraryData.libLicenseID;
    json|error packName = libraryData.packName;
    json|error url = libraryData.url;
    json|error comment = libraryData.comment;

    int libraryID = 0;

    if (licenseID is int[] && libName is string && libType is string && comment is string &&
        packName is string && url is string ) {
        
        libraryID = insertLibraryRequestData(packName, libName, libType, url, comment);

        if libraryID != 0 {
            foreach int id in licenseID {
                boolean success = insertLibraryLicenseRequestData(libraryID, id);
                if !success {
                    return 0;
                }
            }
        } else {
            log:printError("Error: Library does not exists: ");
        }
    } 

    return libraryID;
}

// insert library details
isolated function insertLibraryRequestData(string packName, string lib_name, string lib_type, string url,
    string comment) returns int {

    int id = checkLibraryRequest(lib_name, lib_type);

    if id != 0 {
        return id;
    } else {
        sql:ParameterizedQuery query = `INSERT INTO LM_LIBRARY_REQUEST (PACK_NAME, LIB_FILENAME, LIB_TYPE, LIC_URL, COMMENT)
            VALUES (${packName},${lib_name},${lib_type}, ${url}, ${comment})`;
        sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

        return handleUpdate(executionResult, "Error in updating library table: ");
           
    }
}

// check if requested library exists and get its' id
isolated function checkLibraryRequest(string libFilename, string libType) returns int {
    int libraryID = 0;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_REQUEST WHERE LIB_FILENAME=${libFilename}
        AND LIB_TYPE=${libType}`;
    stream<LibraryRequest, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<LibraryRequest> {

        LibraryRequest[] lib_id_list = from LibraryRequest item in queryResponse select item;
        if lib_id_list.length() > 0 {
            libraryID = lib_id_list[0].LIB_ID;
        }
        
    } else {
        log:printError("Error in fetching from database: ");
    }
    return libraryID;
}

// insert library details
isolated function insertLibraryData(string lib_name, string lib_version, string lib_filename, string lib_type)
    returns int {

    int id = checkLibrary(lib_filename, lib_type);

    if id != 0 {
        return id;
    } else {
        sql:ParameterizedQuery query = `INSERT INTO LM_LIBRARY (LIB_NAME,LIB_VERSION, LIB_FILENAME, LIB_TYPE)
            VALUES (${lib_name},${lib_version},${lib_filename},${lib_type})`;
        sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

        return handleUpdate(executionResult, "Error in updating library table: ");  
    }
}

// insert license under library
isolated function insertLibraryLicenseData(int libId, int licId) returns boolean {

    boolean checklibrarylicense = checkLibraryLicense(libId, licId);

    if !checklibrarylicense {
        sql:ParameterizedQuery query = `INSERT INTO LM_LIBRARY_LICENSE (LIB_ID,LIC_ID) VALUES (${libId},${licId})`;
        sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);

        if executionResult is sql:Error {
            log:printError("Error in inserting library license", executionResult);
            return false;
        }
    }

    return true;
}

// insert license under requested library
isolated function insertLibraryLicenseRequestData(int libId, int licId) returns boolean {

    boolean checklibrarylicense = checkLibraryLicenseRequest(libId,licId);

    if !checklibrarylicense {

        sql:ParameterizedQuery query = `INSERT INTO LM_LIBRARY_LICENSE_REQUEST (LIB_ID,LIC_ID) VALUES (${libId},${licId})`;
        sql:ExecutionResult|sql:Error executionResult = mysqlEp->execute(sqlQuery = query);

        if executionResult is sql:Error {
            log:printError("Error in inserting library license", executionResult);
            return false;
        }
    }

    return true;
}

// check if license exists under requested library
isolated function checkLibraryLicenseRequest(int libId, int licId) returns boolean {
    
    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_LICENSE_REQUEST WHERE LIB_ID=${libId} AND LIC_ID=${licId}`;
    stream<Library_License, sql:Error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<Library_License> {

        Library_License[] library_license_list = from Library_License item in queryResponse select item;
        return library_license_list.length() > 0;

    } else {
        log:printError("Error in selecting library licenses");
    }

    return false;

}

// check if license exists under library
isolated function checkLibraryLicense(int libId, int licId) returns boolean {
    
    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY_LICENSE WHERE LIB_ID=${libId} AND LIC_ID=${licId}`;
    stream<Library_License, sql:Error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<Library_License> {

        Library_License[] library_license_list = from Library_License item in queryResponse select item;
        return library_license_list.length() > 0;

    } else {
        log:printError("Error in selecting library licenses");
    }

    return false;

}

// check if library exists and get id
isolated function checkLibrary(string libFilename, string libType) returns int {
    int libraryID = 0;

    sql:ParameterizedQuery query = `SELECT * FROM LM_LIBRARY WHERE LIB_FILENAME=${libFilename} AND LIB_TYPE=${libType}`;
    stream<Library, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<Library> {

        Library[] lib_id_list = from Library item in queryResponse select item;
        if lib_id_list.length() > 0 {
            libraryID = lib_id_list[0].LIB_ID;
        }
        
    } else {
        log:printError("Error in fetching from database: ");
    }
    return libraryID;
}

// get updated entries' database id
isolated function handleUpdate(sql:ExecutionResult|error updateResult, string message) returns int {
    
    if updateResult is sql:ExecutionResult {

        anydata|error generatedKey = updateResult.lastInsertId;
        if generatedKey is int {
            return generatedKey;
        }

    } else {
        log:printError(message, updateResult);
    }
    return 0;
}

// update database with product details
isolated function updateDatabase(json dataSet) returns json|error {
    json|error libraries = dataSet.library;
    string productName = (check dataSet.packName).toString();
    string productVersion = (check dataSet.packVersion).toString();
    int productId = insertProductData(productName, productVersion);
    int libraryID = 0;

    if productId != 0 {
        if libraries is json[] {
            foreach json libraryData in libraries {
                libraryID = insertLibraryJson(libraryData);
                if libraryID != 0 {
                    insertProductLibraryData(productId, libraryID);
                } else {
                    log:printError("Error: Error in inserting library ");
                }
            }
            return {status: 200};
        } else {
            log:printError("Error : Libraries is not a json array ");
            return {status: 400};
        }
    } else {
        log:printError("Error: Error in retrieving productID ");
        return {status: 400};
    }
}

// get product id
isolated function insertProductData(string prodName, string prodVersion) returns int {

    int productId = verifyProduct(prodName, prodVersion);

    if productId != 0 {
        return productId;
    }
    sql:ParameterizedQuery query = `INSERT INTO LM_PRODUCT (PROD_NAME, PROD_VERSION) VALUES (${prodName},${prodVersion})`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    return handleUpdate(executionResult, "Error in updating product table :");
}

// get product id if exists
isolated function verifyProduct(string prodName, string prodVersion) returns int {
    int productId = 0;

    sql:ParameterizedQuery query = `SELECT * FROM LM_PRODUCT WHERE PROD_NAME=${prodName} AND PROD_VERSION=${prodVersion}`;
    stream<Product, error?> queryResponse = mysqlEp->query(query);

    if queryResponse is stream<Product> {
        foreach var row in queryResponse {
            productId = row.PROD_ID;
        }
    }

    if productId != 0 {
        deleteProductLibrary(productId);
        return productId;
    }
    return productId;
}

// delete libraries under a product 
isolated function deleteProductLibrary(int productId) {

    sql:ParameterizedQuery query = `DELETE FROM LM_PRODUCT_LIBRARY WHERE PROD_ID=${productId}`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is error {
        log:printError("Error in deleting product library", executionResult);
    }
   
}

// insert libraries under a product
isolated function insertProductLibraryData(int productID, int libraryID) {

    sql:ParameterizedQuery query = `INSERT INTO LM_PRODUCT_LIBRARY (PROD_ID,LIB_ID) VALUES (${productID},${libraryID})`;
    sql:ExecutionResult|error executionResult = mysqlEp->execute(sqlQuery = query);

    if executionResult is error {
        log:printError("Error in inserting product library", executionResult);
    }
}