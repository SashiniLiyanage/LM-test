import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import { AuthProvider } from "@asgardeo/auth-react";

const config = {
  signInRedirectURL: `https://${window.location.host}/dashboard`,
  signOutRedirectURL: `https://${window.location.host}`,
  clientID: process.env.REACT_APP_ASGARDEO_CLIENT_ID,
  baseUrl: process.env.REACT_APP_ASGARDEO_BASE_URL,
  scope: ["openid", "groups", "profile", "email",
    "urn:wso2digitaloperationsuser:licensemanager:generate-license-file", 
    "urn:wso2digitaloperationsuser:licensemanager:add-update-jar-details"
  ],
  resourceServerURLs: [process.env.REACT_APP_BE_URL],
};

ReactDOM.render(
  <AuthProvider config={ config }>
      <App />
  </AuthProvider>
  ,document.getElementById('root')
);
