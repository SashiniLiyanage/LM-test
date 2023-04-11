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
import { withStyles, Button, Grid, TextField, MenuItem } from '@material-ui/core';
import { emphasize } from '@material-ui/core/styles/colorManipulator';
import { ValidatorForm, TextValidator } from 'react-material-ui-form-validator';
import axios from 'axios';
import UserContext from '../../UserContext';

const styles = theme => ({
  root: {
    flexGrow: 1,
    height: 250,
  },
  input: {
    display: 'flex',
    padding: 0,
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



class UpdateLicense extends React.Component {
  static contextType = UserContext
  constructor(props) {
    super(props);
    this.state = {
        licName : this.props.data.LIC_NAME,
        licKey : this.props.data.LIC_KEY,
        licUrl : this.props.data.LIC_URL,
        licCategory : this.props.data.LIC_CATEGORY,
        licId : this.props.data.LIC_ID
    };
  }

  submitHandler = () => {
     axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/updateLicense', this.state,{
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
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
                  value={this.state.licName}
                  onChange={this.handleNameChange}
                  fullWidth
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextValidator
                  required
                  label="License Key"
                  value={this.state.licKey}
                  onChange={this.handleKeyChange}
                  fullWidth
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextValidator
                  required
                  label="License Url"
                  value={this.state.licUrl}
                  onChange={this.handleUrlChange}
                  fullWidth
                />
              </Grid>

              <Grid item xs={12} sm={6}>
              <TextField
                            required
                            label="License Category"
                            onChange={this.handleCategoryChange}
                            name="licCategory"
                            value={this.state.licCategory}
                            fullWidth   
                            select
                        >
                            <MenuItem key="A" value="A">A</MenuItem>
                            <MenuItem key="B" value="B">B</MenuItem>
                            <MenuItem key="X" value="X">X</MenuItem>
                        </TextField>  
                
              </Grid>
              <Grid item xs={12}>
                <Button type="submit" color="primary" variant="contained">Update License</Button>
              </Grid>
            </Grid>
          </ValidatorForm>
        </React.Fragment>
      </div>
    );
  }
}
UpdateLicense.propTypes = {
  classes: PropTypes.object.isRequired,
  theme: PropTypes.object.isRequired,
};

export default withStyles(styles, { withTheme: true })(UpdateLicense);
