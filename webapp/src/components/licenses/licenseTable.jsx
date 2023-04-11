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
import UpdateLicense from './updateLicense';
import UserContext from '../../UserContext';

export default class LicenseTable extends Component {
  static contextType = UserContext
  constructor() {
    super();
    this.state = {
      licenses: [],
      update : false,
      loading: false,
      data:{}
    };
  }
  componentDidMount() {
    this.setState({ loading: true })
    axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getLicense', {
      headers:{
        "Authorization": `Bearer ${this.context.idToken}`
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
    this.setState({update:true})
    this.setState({data : data})
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
                        License Details
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
        title="Available Licenses"
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
            icon: 'edit',
            tooltip: 'Edit License',
            align : 'center',
            onClick: (event, rowData) => this.update(rowData)
          }]
          :
          []
        }
      />
    }

      {this.state.update &&  
        <div>
          <Divider horizontal>
            <Header as='h4'>
              <Icon name='file' />
              Update License
            </Header>
          </Divider>
          <div align="right">
            <Button color="secondary" variant="contained" startIcon={<Close />} onClick={this.close.bind(this)}>Close</Button>
          </div>
          <UpdateLicense data={this.state.data} />
        </div>}          
      </div>
    );
  }
}
