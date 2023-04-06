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

import React, {useState} from 'react';
import logo from '../assets/images/logo-inverse.svg';
import { Avatar, MenuItem, Divider, Menu} from '@material-ui/core';
import { useAuthContext } from "@asgardeo/auth-react";
import { withStyles } from '@material-ui/core/styles';

const StyledMenu = withStyles({
    paper: {
      border: '1px solid #d3d4d5',
    },
  })((props) => (
    <Menu
      elevation={0}
      getContentAnchorEl={null}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
      {...props}
    />
  ));

const AppHeader = ()=> { 

        const [anchorEl, setAnchorEl] = React.useState(null);
        const {state, signOut} = useAuthContext();

        const handleClick = (event) => {
            setAnchorEl(event.currentTarget);
        };     

        
        const handleClose = () => {
            setAnchorEl(null);
        };
    
        const GoToProfile = ()=>{
            window.open(`https://myaccount.asgardeo.io/t/${process.env.REACT_APP_ASGARDEO_ORGANIZATION}`, '_blank', 'noreferrer')
        }

        return (
            <nav className="navbar navbar-inverse container-fluid" style={{backgroundColor: "#000000", height: '100%'}}>
                <div className="navbar-header">
                    <a href='/'><br></br><img id="logo" style={{height: '50px'}} src={logo} alt="wso2"/></a>
                    <font className="navbar-brand" 
                        style={{color: "#FBFCFC", fontSize: '40px', paddingLeft: '20px'}}>License Manager Application</font>          
                </div>
                {
                    state.isAuthenticated &&
                    <div style={{marginRight: '20px'}}> 
                        <Avatar aria-controls="customized-menu" aria-haspopup="true" src={"info.picture"} onClick={handleClick}>{state.email? state.email[0].toUpperCase(): ""}</Avatar>        
                        <StyledMenu anchorEl={anchorEl} keepMounted open={Boolean(anchorEl)} onClose={handleClose}>
                            <MenuItem disabled>{state.email}</MenuItem>
                            <Divider></Divider>
                            <MenuItem onClick={GoToProfile}>Profile</MenuItem>
                            <MenuItem onClick={()=>{signOut()}}>Logout</MenuItem>
                        </StyledMenu>
                    </div> 
                }
            </nav>
        );
}

export default AppHeader;
