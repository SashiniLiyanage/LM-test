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
import Button from '@material-ui/core/Button';
import Close from '@material-ui/icons/Close';
import { Divider, Header,Icon} from 'semantic-ui-react'
import UserContext from '../../UserContext';
import AddLicense from './addLicense';

export default class RequestTable extends Component {
  static contextType = UserContext
  constructor() {
    super();
    this.state = {
      licenses: [],
      preview : false,
      loading: false,
      data:{}
    };
  }
  componentDidMount() {
    this.setState({ loading: true })
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getLicenseRequests', {
      headers:{
        "API-Key": process.env.REACT_APP_API_KEY
      }
    }).then(res => {
      this.setState({ licenses: res.data, loading: false})
    }).catch(err => {
      console.log(err)
      alert(err)
      this.setState({ licenses: [], loading: false})
    })
  }
  update(data){
    this.setState({preview:true})
    this.setState({data : data})
  }
  close(){
    this.setState({preview:false})
  }
  render() {
    return (
      <div>
         <Divider horizontal>
                    <Header as='h4'>
                        <Icon name='drivers license' />
                        Requested License Details
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
        title="Requested Licenses"
        columns={[
          { title: 'Name', field: 'LIC_NAME' },
          { title: 'Key', field: 'LIC_KEY' },
          { title: 'Url', field: 'LIC_URL' },
          { title: 'Category', field: 'LIC_CATEGORY' },
        ]}
        data={this.state.licenses}
        options={{
          search: true,
          exportButton: true,
        }}
        actions={
          this.context.admin?
          [{
            key: 3,
            icon: 'preview',
            tooltip: 'Preview License',
            align : 'center',
            onClick: (event, rowData) => this.update(rowData)
          }]
          :
          []
        }
      />
    }

      {this.state.preview &&  
        <div>
          <Divider horizontal>
            <Header as='h4'>
              <Icon name='file' />
              Approve License
            </Header>
          </Divider>
          <div align="right">
            <Button color="default" variant="contained" startIcon={<Close />} onClick={this.close.bind(this)}>Close</Button>
          </div>
          <AddLicense data={this.state.data} />
        </div>}          
      </div>
    );
  }
}
