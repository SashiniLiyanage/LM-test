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
import axios from 'axios';
import Button from '@material-ui/core/Button';
import DeleteIcon from '@material-ui/icons/Delete';
import CloudDownload from '@material-ui/icons/CloudDownload';
import { BallBeat } from 'react-pure-loaders';
import Close from '@material-ui/icons/Close';
import Error from '@material-ui/icons/Error';
import { Divider,Header,Icon } from 'semantic-ui-react';
import './../../styles/paging.css';
import ErrorUpdate from './errorUpdate';
import fileDownload from 'js-file-download';
import UserContext from '../../UserContext';

export default class PackStatus extends React.Component {
  static contextType = UserContext
  constructor() {
    super();
    this.state = {
      packstatus: [],
      name: "",
      open: false
    };
  }

  componentDidMount() {
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getPackstatus', {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
      }
    })
      .then(res => {
        this.setState({ packstatus: res.data })
      })
      .catch(error => {
        console.log(error)
      })
  }
  delete(item) {
    const packstatus = this.state.packstatus.filter(i => i.PACK_NAME !== item.PACK_NAME)
    this.setState({ packstatus })
    axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/deletePack/' + item.PACK_NAME,{},{
    headers:{
      "Authorization": `Bearer ${this.context.idToken}`
    }
    }).then(res => {
      console.log("Successfully deleted " + item.PACK_NAME)
      
    })
      .catch(error => {
        console.log(error)
      })
      this.setClose()
  }
  download(pack) {
    var licenseFile = pack.PACK_NAME.replace('.zip', '.txt')
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getDownloadingText/' + pack.PACK_NAME, {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
      },
      responseType: "blob"
    })
      .then(res => {
        fileDownload(res.data, licenseFile)
        const packstatus = this.state.packstatus.filter(i => i.PACK_NAME !== pack.PACK_NAME)
        this.setState({ packstatus })
      })
      .catch(error => {
        console.log(error)
      })
  }
  regenerate = () => {
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/processAllPacks', 
    {
        headers:{
          "Authorization": `Bearer ${this.context.idToken}`
        }
    }).then(res => {
        console.log("Done process")
    })
        .catch(error => {
            console.log(error)
        })
    window.location.reload()
  }
  checkSuccess(pack) {
    if (pack.PACK_STATUS_CODE === 1) {
      return true;
    } else {
      return false;
    }
  }
  checkProcess(pack) {
    if (pack.PACK_STATUS_CODE === 2) {
      return true;
    } else {
      return false;
    }
  }
  checkViewError(pack) {
    if (pack.PACK_STATUS_CODE === 3) {
      return true;
    } else {
      return false;
    }
  }
  checkError(pack) {
    if (pack.PACK_STATUS_CODE === 4) {
      return true;
    } else {
      return false;
    }
  }
  setOpen(pack) {
    this.setState({ open: true })
    this.setState({ name: pack.PACK_NAME })

  }
  setClose() {
    this.setState({ open: false })
  }
  render() {
    const renderpacks = this.state.packstatus.map((pack, i) => {
      return <tr key={i}>
        <td> 
          <div>
            {this.checkViewError(pack) && <Icon link name='delete' color="red"  size="large" onClick={this.delete.bind(this,pack)}/>}      
            {pack.PACK_NAME}
          </div>
        </td>
        <td width="45%">{pack.PACK_STATUS}</td>
        <td align="center">
          {this.checkSuccess(pack) ?
            <Button variant="contained" color="default" startIcon={<CloudDownload/>} onClick={this.download.bind(this, pack)}>Download License</Button>
            : this.checkProcess(pack) && pack.PACK_STATUS === "uploaded" ? <Button color="primary" variant="contained" onClick={this.regenerate.bind(this)}>Regenerate</Button>
            : this.checkProcess(pack) ? <BallBeat color={'#123abc'} loading={this.checkProcess(pack)} />
              : this.checkViewError(pack) ?
                <Button color="default" variant="contained" startIcon={<Error />} onClick={this.setOpen.bind(this, pack)} width="100%">View Details</Button>
                : this.checkError(pack) ? <Button variant="contained" color="secondary" startIcon={<CloudDownload />} onClick={this.download.bind(this, pack)}>Download Error</Button>
                  : <Button variant="contained" color="secondary" startIcon={<DeleteIcon />} onClick={this.delete.bind(this, pack)}>Delete</Button>}
        </td>
      </tr>;
    });
    return (
      <div>
        <Divider horizontal>
          <Header as='h4'>
            <Icon name='zip' />
            Pack Details
          </Header>
        </Divider>
        <table className="table table-hover table-bordered">
          <thead><tr><th width="25%">Pack Name</th><th>Pack Status</th><th style={{textAlign:"right"}}><Icon link name='refresh' color='grey' onClick={this.componentDidMount.bind(this)}/></th></tr></thead>
          <tbody id="cursorPointer">
            {this.state.packstatus.length ? 
              renderpacks : 
              <tr>
                <td colSpan="3" align="center" style={{ backgroundColor: '#ddd', padding: '10px' }}>Nothing to show</td>
              </tr>}
          </tbody>
        </table>
        {this.state.open && 
          <div> 
            <br></br>
            <Divider horizontal>
              <Header as='h4'>
                <Icon name='tag' />
                Error Details
              </Header>
            </Divider>
            <p align="right">
              <Button color="secondary" variant="contained" startIcon={<Close />} onClick={this.setClose.bind(this)}>Close</Button>
            </p>
            <ErrorUpdate packName={this.state.name} open={this.state.open}/>
          </div>
        }
      </div>
    );
  }
}

