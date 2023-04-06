/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import React, { useEffect, useState} from 'react';
import { CssBaseline } from '@material-ui/core';
import AppBar from '@material-ui/core/AppBar';
import {Route,NavLink,HashRouter} from "react-router-dom";
import Manager from './components/generator/manager';
import AppHeader from './components/AppHeader';
import LicenseManager from './components/licenses/licenseManager';
import RequestManager from './components/requests/requestManager';
import LibraryManager from './components/library/libraryManager';
import LibraryLicenseManager from './components/libraryLicense/libraryLicenseManager';
import './styles/App.css';
import './styles/index.css';
import UserContext from './UserContext';
import { useAuthContext } from "@asgardeo/auth-react";
import BlobManager from './components/blobs/blobManager';

const Dashboard =()=>{

    const value = { admin: true };
    const [info, setInfo] = useState({});
    const {state, signOut, getBasicUserInfo, getDecodedIDToken} = useAuthContext();

    useEffect(() => {
        if(!state.isAuthenticated) return;

        (async () => {
            const basicUserInfo = await getBasicUserInfo();
            setInfo(basicUserInfo)  
            console.log(basicUserInfo)    
        })().catch((e)=>{
            console.log(e)
        })

        getDecodedIDToken().then((decodedIDToken) => {
            console.log(decodedIDToken);
        }).catch((error) => {
            // Handle the error
        })
  
    }, [state]);

    return(
        <UserContext.Provider value={value}>
        <React.Fragment>
            <CssBaseline/>
            <AppBar position="relative" color="default">
                <AppHeader/>
            </AppBar>
           
            <HashRouter>
                <div className="header black">
                    <ul>
                        <li><NavLink exact to="/">License Generation</NavLink></li>
                        <li><NavLink to="/licensemanager">Licenses</NavLink></li>
                        <li><NavLink to="/librarymanager">Libraries</NavLink></li>
                        <li><NavLink to="/requestmanager">Requests</NavLink></li>
                        { value.admin &&
                            <li><NavLink to="/librarylicensemanager">Library Without Licenses</NavLink></li>
                        }
                        <li><NavLink to="/blobmanager">Blobs</NavLink></li>
                    </ul>
                </div>
                <div className="content">
                    <Route exact path="/" component={Manager}/>
                    <Route path="/licensemanager" component={LicenseManager}/>
                    <Route path="/librarymanager" component={LibraryManager}/>
                    <Route path="/requestmanager" component={RequestManager}/>
                    { value.admin &&
                        <Route path="/librarylicensemanager" component={LibraryLicenseManager}/>
                    }
                    <Route path="/blobmanager" component={BlobManager}/>
                </div>
            </HashRouter>
        </React.Fragment>
        </UserContext.Provider>
    );
}
export default Dashboard;