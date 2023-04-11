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
import classNames from 'classnames';
import Select from 'react-select';
import { withStyles } from '@material-ui/core/styles';
import Typography from '@material-ui/core/Typography';
import TextField from '@material-ui/core/TextField';
import Paper from '@material-ui/core/Paper';
import Chip from '@material-ui/core/Chip';
import MenuItem from '@material-ui/core/MenuItem';
import CancelIcon from '@material-ui/icons/Cancel';
import Button from '@material-ui/core/Button';
import { emphasize } from '@material-ui/core/styles/colorManipulator';
import Grid from '@material-ui/core/Grid';
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

function NoOptionsMessage(props) {
  return (
    <Typography
      color="textSecondary"
      className={props.selectProps.classes.noOptionsMessage}
      {...props.innerProps}
    >
      {props.children}
    </Typography>
  );
}

function inputComponent({ inputRef, ...props }) {
  return <div ref={inputRef} {...props} />;
}

function Control(props) {
  return (
    <TextField
      fullWidth
      InputProps={{
        inputComponent,
        inputProps: {
          className: props.selectProps.classes.input,
          inputRef: props.innerRef,
          children: props.children,
          ...props.innerProps,
        },
      }}
      {...props.selectProps.textFieldProps}
    />
  );
}

function Option(props) {
  return (
    <MenuItem
      buttonRef={props.innerRef}
      selected={props.isFocused}
      component="div"
      style={{
        fontWeight: props.isSelected ? 500 : 400,
      }}
      {...props.innerProps}
    >
      {props.children}
    </MenuItem>
  );
}

function Placeholder(props) {
  return (
    <Typography
      color="textSecondary"
      className={props.selectProps.classes.placeholder}
      {...props.innerProps}
    >
      {props.children}
    </Typography>
  );
}

function SingleValue(props) {
  return (
    <Typography className={props.selectProps.classes.singleValue} {...props.innerProps}>
      {props.children}
    </Typography>
  );
}

function ValueContainer(props) {
  return <div className={props.selectProps.classes.valueContainer}>{props.children}</div>;
}


function Menu(props) {
  return (
    <Paper square className={props.selectProps.classes.paper} {...props.innerProps}>
      {props.children}
    </Paper>
  );
}
function MultiValue(props) {
  return (
    <Chip
      tabIndex={-1}
      label={props.children}
      className={classNames(props.selectProps.classes.chip, {
        [props.selectProps.classes.chipFocused]: props.isFocused,
      })}
      onDelete={props.removeProps.onClick}
      deleteIcon={<CancelIcon {...props.removeProps} />}
    />
  );
}
const components = {
  Control,
  Menu,
  MultiValue,
  NoOptionsMessage,
  Option,
  Placeholder,
  SingleValue,
  ValueContainer,
};

class UpdateLibrary extends React.Component {
  static contextType = UserContext
  constructor(props) {
    super(props);
    this.state = {
      licenses: [],
      libId: this.props.data.LIB_ID,
      ids: [],
      available: true,
      name : this.props.data.LIB_FILENAME
    };
  }

  handleLicenseChange = () => value => {
    this.setState({ ids: value })
  }
  submitHandler = (e) => {
    e.preventDefault()
    if (this.state.ids.length === 0) {
      alert("Please add the licensese!!")
    } else {
        this.updateLibrary()
    }
  }
  updateLibrary = () => {
    axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/updateLibrary', this.state,
    {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
      }
    }
    )
      .then(response => {
        alert("Successfully added!!");
        this.setState({libId:"",ids:null})
        window.location.reload();
        console.log(response)
      })
      .catch(error => {
        window.location.reload(true);
        alert("Failed!!!");
        console.log(error)
      })
  }
  componentDidMount() {
    fetch(process.env.REACT_APP_BE_URL + '/LicenseManager/getLicense', {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
      }
    })
      .then(res => res.json())
      .then((data) => {
        this.setState({ licenses: data })
      })
      .catch(console.log)
  }
  render() {
    const { classes } = this.props;

    const licenses = this.state.licenses.map(license => ({
      value: license.LIC_ID,
      label: license.LIC_KEY,
    }));

    return (
      <div className={classes.root}>
        <React.Fragment>
          
          <ValidatorForm
            ref="form"
            onSubmit={this.submitHandler}
            onError={errors => console.log(errors)}
          >
            <Grid container spacing={3}>
              
              <Grid item xs={12}>
                <TextValidator
                  required
                  label="Library Name"
                  value={this.state.name}
                  fullWidth
                  readOnly
                />
              </Grid>
              <Grid item xs={12}>

                <Select
                  classes={classes}
                  textFieldProps={{
                    label: 'Licenses',
                    InputLabelProps: {
                      shrink: true,
                    },
                  }}
                  options={licenses}
                  components={components}
                  value={this.state.ids}
                  onChange={this.handleLicenseChange()}
                  placeholder='Select multiple licenses'
                  isMulti
                />
              </Grid>
              <Grid item xs={12}>
                <Button type="submit" color="primary" variant="contained">Update Library</Button>
              </Grid>
            </Grid>
          </ValidatorForm>
        </React.Fragment>
      </div>
    );
  }
}
UpdateLibrary.propTypes = {
  classes: PropTypes.object.isRequired,
  theme: PropTypes.object.isRequired,
};

export default withStyles(styles, { withTheme: true })(UpdateLibrary);
