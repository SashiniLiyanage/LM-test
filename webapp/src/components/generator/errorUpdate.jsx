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
import { Typography, Button, withStyles } from '@material-ui/core';
import axios from 'axios';
import { emphasize } from '@material-ui/core/styles/colorManipulator';
import { Table, Thead, Tbody, Tr, Th, Td } from 'react-super-responsive-table'
import Close from '@material-ui/icons/Close';
import { Divider,Header} from 'semantic-ui-react'
import 'react-super-responsive-table/dist/SuperResponsiveTableStyle.css';
import UpdateLibrary from './updateLibrary';

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

class ErrorUpdate extends Component {
    constructor(props) {
        super(props);
        this.state = {
            packName: this.props.packName,
            libLicenseID: [],
            licenses: [],
            tempData: [],
            blocked: [],
            newLibrary: {
                libFilename: "",
                libType: "",
                libLicenseID: [],
            },
            open: this.props.open,
            update: false,
            data:{}
        };
    }
    addLicense = (data)=>{
        this.setState({update:true})
        this.setState({data : data})
    }
    close = ()=>{
        this.setState({update:false})
    }
    getTempData = () => {
        axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/gettempdata/' +
        this.state.packName, {
            headers:{
                "API-Key": process.env.REACT_APP_API_KEY
            }
        }).then(res => {
            this.setState({ open: false })
            this.setState({blocked : res.data.blockedLibrary})
            const licenseData = res.data.emptyLibrary.map(library => ({
                libFilename : library.LIB_FILENAME,
                libType : library.LIB_TYPE,
                libLicenseID : []
            }))
            this.setState({tempData : licenseData} )
        }).catch(err => {
            console.log(err)
        })
    }
    componentDidMount = () => {
        axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getLicense', {
        headers:{
            "API-Key": process.env.REACT_APP_API_KEY
        }
        }).then(res => {
            this.setState({ licenses: res.data })
        }).catch(err =>
            console.log(err))
    }
    render() {
        const renderBlockedLibrary = this.state.blocked.map((jar, i) => {
            return (
                <Tr key={i}>
                    <Td>{jar.LIB_FILENAME}</Td>
                    <Td>{jar.LIB_TYPE}</Td>
                </Tr>
            )
        });
        const renderLibrary = this.state.tempData.map((data,i) => {
            return (
                <Tr key={i}>
                    <Td>{data.libFilename}</Td>
                    <Td align="center"><Button variant='contained'  onClick={this.addLicense.bind(this,data)}>Add License</Button></Td>
                </Tr>
            )
        })
        return (
            <React.Fragment>
                {this.state.open && this.getTempData()}

                {this.state.tempData.length ?

                    this.state.update?
                   
                    <div>
                    <Divider horizontal>
                        <Header as='h4'>
                        {/* <Icon name='file' /> */}
                        Update Library License
                        </Header>
                    </Divider>
                    <div align="right">
                        <Button variant="contained" startIcon={<Close />} onClick={this.close.bind(this)}>Close</Button>
                    </div>
                    <UpdateLibrary packName={this.state.packName} data={this.state.data} />
                    </div> 
                   
                    :
                    <div>
                    <Typography variant="h6" gutterBottom>
                        {/* Add License to Library */}
                        Libraries without licenses.
                    </Typography>
                    <Typography gutterBottom>
                        There are some libraries without licenses.  Please add them and wait for approval...
                    </Typography>
                    <br></br>
                    <Table>
                        <Thead>
                            <Tr>
                                <Th>Jar Name</Th>
                                <Th>License</Th>
                            </Tr>
                        </Thead>
                        <Tbody>
                            {renderLibrary}   
                        </Tbody>
                    </Table>
                    </div> 
                : 
                <Typography gutterBottom>
                    There are some libraries without licenses.  Please wait for the approval...
                </Typography>
                }
                <br></br>
                {this.state.blocked.length ?
                    <div>
                        <hr></hr><hr></hr><hr></hr>
                        <Typography variant="h6" gutterBottom>
                            Blocked Licenses
                        </Typography>
                        <Typography gutterBottom style={{ backgroundColor: "pink" }}>
                            There are libraries with X category licenses. These libraries should be removed from the pack (Re-upload the pack after removing these jars)
                        </Typography>
                        <hr></hr>                        
                        <Table>
                            <Thead><Tr><Th>Jar name</Th><Th>Jar Type</Th></Tr></Thead>
                            <Tbody>
                                {renderBlockedLibrary}
                            </Tbody>
                        </Table>
                    </div>
                : null }
            </React.Fragment>
        );
    }

}
export default withStyles(styles, { withTheme: true })(ErrorUpdate);
