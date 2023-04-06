import ballerina/email;
import ballerina/log;


// get template for email
isolated function getTemplate(json dataSet) returns string {
    string|error tabel = generateTable(dataSet);
    if(tabel is string){
        string mail_template = html_header + template_header + tabel + template_footer + html_footer;
        return mail_template;
    }else{
        return "error while generating the tabel";
    }
    
}

// generate table for libraries without license
isolated function generateTableContent(json[] data, string heading) returns string|error {
    string tableData = "";
    if (data.length() !== 0) {
        tableData = tableData + string `<div id = "title"><b>` + heading +
        "</b></div><table id=\"openprs\"><tr><th style=\"width:300px\">" +
        "Library Name</th><th style=\"width:300px\">Library Version</th></tr>";
        foreach json library in data {
            tableData = tableData +
            "<tr><td>" + (check library.libName).toString() + "</td>" +
            "<td>" + (check library.libVersion).toString() + "</td></tr>";
        }
        tableData = tableData + "</table>";
    }
    return tableData;
}

// generate table template
isolated function generateTable(json data) returns string|error {
    json | error blocked = data.blocked;
    json | error empty = data.empty;
    string heading;
    string productName = (check data.packName).toString();
    string productVersion = (check data.packVersion).toString();
    string summaryTable = string `<div id = "subhead"> Product Name : ` + productName + "&& Product Version : " + productVersion + "</div>";
    
    if empty is json[] {
        heading = "Libraries without licenses";
        string| error tableContent = generateTableContent(empty, heading);
        if(tableContent is string){
            summaryTable = summaryTable + tableContent;
        }else{
            log:printError("Error in generating table content");
        }
    }

    if blocked is json[] {
        heading = "There are libraries with X category licenses. These libraries have to be removed before generating license file";
        string| error tableContent = generateTableContent(blocked, heading);
        if(tableContent is string){
            summaryTable = summaryTable + tableContent;
        }else{
            log:printError("Error in generating table content");
        }
        
    }
    return summaryTable;
}

// function to send email
isolated function sendEmail(json dataSet){
    do {
	    email:SmtpClient smtpClient = check new ("smtp.gmail.com", GMAIL_SENDER , GMAIL_PASSWORD);
        
        email:Message email = {
            to: [GMAIL_RECIPIENT],
            subject: "License Manager Application",
            body: getTemplate(dataSet),
            'from: GMAIL_SENDER,
            contentType: "text/html"
        };

        check smtpClient->sendMessage(email);
    } on fail var e {
    	log:printError("Error while sending the email: ", e);
    }

}
