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
import { CssBaseline, Paper } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
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
import { BallBeat } from 'react-pure-loaders';

const useStyles = makeStyles(theme => ({
    layout: {
      width: 'auto',
      marginLeft: theme.spacing(2),
      marginRight: theme.spacing(2),
      [theme.breakpoints.up(600 + theme.spacing(2) * 2)]: {
        width: 950,
        marginLeft: 'auto',
        marginRight: 'auto',
      },
    },
    paper: {
      marginTop: theme.spacing(3),
      marginBottom: theme.spacing(3),
      padding: theme.spacing(2),
      [theme.breakpoints.up(600 + theme.spacing(3) * 2)]: {
        marginTop: theme.spacing(6),
        marginBottom: theme.spacing(6),
        padding: theme.spacing(3),
      },
    },
}));

const Dashboard =()=>{

    const [value, setValue] = useState({});
    const [loading, setLoading] = useState(true);
    const {state, getIDToken} = useAuthContext();
    const classes = useStyles();

    useEffect(() => {
        if(!state.isAuthenticated) return;

        (async () => {
            setLoading(true);
            const idToken =  await getIDToken();
            setValue({ admin: true, idToken: idToken})

        })().catch((e)=>{
          console.log(e)
        }).finally(()=>{
            setLoading(false);
        })   
  
    }, [state]);

    return(
        <UserContext.Provider value={value}>
        <React.Fragment>
            <CssBaseline/>
            <AppBar position="relative" color="default">
                <AppHeader/>
            </AppBar>
           
            {loading? 
            <main className={classes.layout}>
            <Paper className={classes.paper}>
            <div>
                Loading...
                <BallBeat color={'#123abc'} loading={loading} />
            </div>     
            </Paper>
            </main>
            
            :
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
            }
        </React.Fragment>
        </UserContext.Provider>
    );
}
export default Dashboard;