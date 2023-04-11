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
import MaterialTable from 'material-table';
import { BallBeat } from 'react-pure-loaders';
import axios from 'axios';
import { Divider, Header,Icon} from 'semantic-ui-react'
import UserContext from '../../UserContext';
import fileDownload from 'js-file-download';

export default class BlobTable extends Component {
  static contextType = UserContext
  constructor() {
    super();
    this.state = {
      licenseFile: [],
      loading: false,
      data:{}
    };
  }
  componentDidMount() {
    this.setState({ loading: true })
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getBlobData', {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
      }
    }).then(res => {
      this.setState({ licenseFile: res.data, loading: false})
    }).catch(err => {
      console.log(err)
      alert(err)
      this.setState({ licenseFile: [], loading: false})
    })
  }
  download(data){
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getBlobFile/' + data.BLOB_NAME, {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
      },
      responseType: "blob"
    })
      .then(res => {
        fileDownload(res.data, data.FILENAME);
      })
      .catch(error => {
        console.log(error)
        alert("Failed!!!")
      })
  }
  close(){
    this.setState({update:false})
  }
  render() {
    return (
      <div>
         <Divider horizontal>
                    <Header as='h4'>
                        <Icon name='drivers license' />
                        License File Details
                    </Header>
                </Divider>
      {
      this.state.loading?
      <div>
        Loading...
        <BallBeat color={'#123abc'} loading={this.state.loading} />
      </div>
      :

      <MaterialTable
        title="Generated License Files"
        columns={[
          { title: 'File Name', field: 'FILENAME' },
          { title: 'Date', field: 'BLOB_TIMESTAMP' }
        ]}
        data={this.state.licenseFile}
        options={{
          search: true,
          exportButton: true,
        }}
        actions={
          [{
            key: 3,
            icon: 'download',
            tooltip: 'Download License',
            align : 'center',
            onClick: (event, rowData) => this.download(rowData)
          }]
        }
      />
    }       
      </div>
    );
  }
}
