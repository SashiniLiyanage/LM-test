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
import React, { Component } from 'react';
import Grid from '@material-ui/core/Grid';
import {Typography, Link} from '@material-ui/core';
import Button from '@material-ui/core/Button';
import { ValidatorForm, TextValidator} from 'react-material-ui-form-validator';
import MenuItem from '@material-ui/core/MenuItem';
import TextField from '@material-ui/core/TextField';
import axios from 'axios';
import Popup from "reactjs-popup";

export default class AddLicense extends Component {
    constructor(props) {
        super(props);
        this.state = {
            licName: "",
            licKey: "",
            licUrl: "",
            licCategory:"",
        };
    }
    handleLicenseNameChange = (event) => {
        const licName = event.target.value;
        this.setState({ licName });
    }
    handleLicenseKeyChange = (event) => {
        const licKey = event.target.value;
        this.setState({ licKey });
    }
    handleLicenseUrlChange = (event) => {
        const licUrl = event.target.value;
        this.setState({ licUrl });
    }
    handleLicenseCategoryChange = (event) => {
        const licCategory = event.target.value;
        this.setState({ licCategory });
    }
    addNewLicense = () => {
        if (this.state.licCategory === ""){
            alert("Please select the category")
        }else {
            axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/addLicense',this.state, {
                headers:{
                    "API-Key": process.env.REACT_APP_API_KEY
                }
            })
            .then(response => {
                alert("Successfully added!!");
                window.location.reload();
                console.log(response)
            })
            .catch(error => {
                alert("Failed!!!");
                console.log(error)
            })
        }    
        
    }
    submitHandler = (e) => {
        e.preventDefault()
        console.log(this.state)
        if (this.state.licCategory === ""){
            alert("Please select the category")
        }else {
            axios.get(process.env.REACT_APP_BE_URL + `/LicenseManager/checkLicense/${this.state.licName}/${this.state.licKey}`, {
                headers:{
                    "API-Key": process.env.REACT_APP_API_KEY
                }
            })
            .then(response => {
                if(response.data.exists){
                    alert("License Already exists");
                }else{
                    this.addNewLicense();
                }
            })
            .catch(error => {
                alert("Failed!!!");
                console.log(error)
            })
        }    
        
    }
    render() {
        const { licName, licKey, licUrl, licCategory } = this.state;
        return (
            <React.Fragment>
                <Typography variant="h6" gutterBottom>
                    Add New License
                </Typography>
                <ValidatorForm
                    ref="form"
                    onSubmit={this.submitHandler}
                    onError={errors => console.log(errors)}
                >
                <Grid container spacing={3}>
                    <Grid item xs={12} sm={6}>
                        <TextValidator
                            required
                            label="License Name"
                            onChange={this.handleLicenseNameChange}
                            name="licName"
                            value={licName}
                            fullWidth
                            validators={['required']}
                            errorMessages={['this field is required']}
                        />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                        <TextValidator
                            required
                            label="License Key"
                            onChange={this.handleLicenseKeyChange}
                            name="licKey"
                            value={licKey}
                            fullWidth
                            validators={['required']}
                            errorMessages={['this field is required']}
                        />
                    </Grid>
                    <Grid item xs={12} sm={6}>
                        <TextValidator
                            required
                            label="License URL"
                            onChange={this.handleLicenseUrlChange}
                            name="licUrl"
                            value={licUrl}
                            fullWidth
                            validators={['required']}
                            errorMessages={['this field is required']}
                        />
                    </Grid>
                    <Grid item xs={12} sm={5}>
                        <TextField
                            required
                            label="License Category"
                            onChange={this.handleLicenseCategoryChange}
                            name="licCategory"
                            value={licCategory}
                            fullWidth   
                            select
                        >
                            <MenuItem key="A" value="A">A</MenuItem>
                            <MenuItem key="B" value="B">B</MenuItem>
                            <MenuItem key="X" value="X">X</MenuItem>
                        </TextField>   
                    </Grid>
                    <Grid item={12} sm={1}>
                            <br></br>                 
                            <Popup trigger={<Link>Help?</Link>} position="right center">
                               <div> You can check the category of the license by viewing the following link:
                                    <Link href="https://www.apache.org/legal/resolved.html#highlevel" target="_blank">Check Category</Link>
                                </div>
                            </Popup>  
                    </Grid>
                    <Grid item xs={12}>
                        <Button type="submit" color="primary" variant="contained">Add License</Button>
                    </Grid>
                </Grid>
                </ValidatorForm>
            </React.Fragment>
        );
    }
}