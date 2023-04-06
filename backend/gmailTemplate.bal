final string html_header = string `
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>License Generation</title>
      <style>
        #headings {
        font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
        width: 100%;
        background-color: #044767;
        color: #fff;
        padding: 10px;
        text-align: center;
        font-weight: 600px;
        font-size: 20px;
        margin-bottom: 10px;
        margin-top: 30px;
      }
        #subhead {
        font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
        font-weight: 400px;
        font-size: 18px;
        color: #777777;
        padding: 20px;
        text-align: left;
        margin: 10px;
      }
        #title {
        font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
        font-weight: 350px;
        font-size: 16px;
        color: #777777;
        padding: 20px;
        text-align: center;
        margin: 10px;
      }
      #openprs {
        font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
        border-collapse: collapse;
        width: 100%;
        margin: 20px;
      }

      #openprs td, #openprs th {
        border: 1px solid #ddd;
        padding: 8px;
      }

      #openprs tr{
        background-color: #dedede;
      }

      #openprs tr:nth-child(even){background-color: #efefef;}

      #openprs tr:hover {background-color: #ddd;}

      #openprs th {
        padding-top: 12px;
        padding-bottom: 12px;
        text-align: left;
        background-color: #cecece;
        color: #044767;
      }
    </style>
  </head>
  <body>
 `;

final string template_header = string `
   <div id = "headings">
       License Generation Issues
   </div>
`;

final string template_footer = string `
    <div align = center>
        <img src="https://upload.wikimedia.org/wikipedia/en/5/56/WSO2_Software_Logo.png" width="90" height="37" style="display: block; border: 0px">
        <p align="center" >
            Copyright (c) 2019 | WSO2 Inc.<br/>All Right Reserved.
        </p>
    </div>
`;


final string html_footer = string `
    </body>
    </html> `;
