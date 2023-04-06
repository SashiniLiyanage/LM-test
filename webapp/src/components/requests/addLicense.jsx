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
import React from 'react';
import PropTypes from 'prop-types';
import { withStyles, Button, Grid, TextField, MenuItem, Typography, Divider } from '@material-ui/core';
import { emphasize } from '@material-ui/core/styles/colorManipulator';
import { ValidatorForm, TextValidator } from 'react-material-ui-form-validator';
import axios from 'axios';

const styles = theme => ({
  root: {
    flexGrow: 1,
    minHeight: 250,
  },
  input: {
    display: 'flex',
    padding: 0
  },
  valueContainer: {
    display: 'flex',
    flexWrap: 'wrap',
    flex: 1,
    alignItems: 'center',
    overflow: 'hidden',
  },
  chip: {
    margin: `${theme.spacing(0.5)}px ${theme.spacing(0.25)}px`,
  },
  chipFocused: {
    backgroundColor: emphasize(
      theme.palette.type === 'light' ? theme.palette.grey[300] : theme.palette.grey[700],
      0.08,
    ),
  },
  noOptionsMessage: {
    padding: `${theme.spacing(2)}px`,
  },
  singleValue: {
    fontSize: 16,
  },
  placeholder: {
    position: 'absolute',
    left: 2,
    fontSize: 16,
  },
  paper: {
    position: 'absolute',
    zIndex: 1,
    left: 0,
    right: 0,
  },
});



class AddLicense extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
        licName : this.props.data.LIC_NAME,
        licKey : this.props.data.LIC_KEY,
        licUrl : this.props.data.LIC_URL,
        licCategory : this.props.data.LIC_CATEGORY,
        licReason : this.props.data.LIC_REASON,
        licRequester : this.props.data.LIC_REQUESTER,
        licId : this.props.data.LIC_ID
    };
  }

  approve = () => {
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
  addNewLicense = () => {
    axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/approveLicense', this.state,{
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
      // window.location.reload(true);
      alert("Failed!!!");
        console.log(error)
      })
  }
  reject = () => {
     axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/rejectLicense', this.state,{
      headers:{
        "API-Key": process.env.REACT_APP_API_KEY
      }
     })
       .then(response => {
         alert("Request is Rejected!!");
         window.location.reload();
         console.log(response)
       })
       .catch(error => {
        // window.location.reload(true);
        alert("Failed!!!");
         console.log(error)
       })
  }
  handleNameChange = (event) => {
    const licName = event.target.value;
    this.setState({ licName });
  }
  handleKeyChange = (event) => {
      const licKey = event.target.value;
      this.setState({ licKey });
  }
  handleUrlChange = (event) => {
      const licUrl = event.target.value;
      this.setState({ licUrl });
  }
  handleCategoryChange = (event) => {
      const licCategory = event.target.value;
      this.setState({ licCategory });
  }
  render() {
    const { classes } = this.props;

    return (
      <div className={classes.root}>
        <React.Fragment>
            <Grid container spacing={3} justify='flex-start' >
              
              <Grid item xs={12} sm={6}>
                <Typography align='left' variant="body2" color="textSecondary">License Name</Typography>
                <Typography align='left'>{this.state.licName}</Typography>
                <Divider/>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography align='left' variant="body2" color="textSecondary" >License Key</Typography>
                <Typography align='left'>{this.state.licKey}</Typography>
                <Divider/>
              </Grid>
              <Grid item xs={12} sm={6}>
                <Typography align='left' variant="body2" color="textSecondary">License Url</Typography>
                <Typography align='left'>{this.state.licUrl}</Typography>
                <Divider/>
              </Grid>

              <Grid item xs={12} sm={6}>
                <Typography align='left' variant="body2" color="textSecondary">License Category</Typography>
                <Typography align='left'>{this.state.licCategory}</Typography> 
                <Divider/>
              </Grid>
              <Grid item xs={12} sm={12}>
                <Typography align='left' variant="body2" color="textSecondary">Reason</Typography>
                <Typography align='left'>{this.state.licReason}</Typography>
                <Divider/>
              </Grid>
              <Grid item xs={12} sm={12}>
                <Typography align='left' variant="body2" color="textSecondary">Requester</Typography>
                <Typography align='left'>{this.state.licRequester}</Typography>
                <Divider/>
              </Grid>
              <Grid item xs={12}>
                <Button style={{margin:'5px'}} color="primary" variant="contained" onClick={this.approve.bind(this)}>Approve License</Button>
                <Button style={{margin:'5px'}} color="secondary" variant="contained" onClick={this.reject.bind(this)}>Reject License</Button>
              </Grid>
            </Grid>
        </React.Fragment>
      </div>
    );
  }
}
AddLicense.propTypes = {
  classes: PropTypes.object.isRequired,
  theme: PropTypes.object.isRequired,
};

export default withStyles(styles, { withTheme: true })(AddLicense);
