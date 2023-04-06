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
import { Divider,Header,Icon, Pagination } from 'semantic-ui-react'
import UpdateLibrary from './updateLibrary';
import UserContext from '../../UserContext';
import SearchBar from './librarySearchBar';

export default class LibraryTable extends Component {
  static contextType = UserContext
  constructor() {
    super();
    this.state = {
      libraries: [],
      update : false,
      loading: false,
      data:{},
      nextPageToFetch: 0,
      currPage: 0,
      renderPageSize: 20,
      keyword: ''
    };
  }

  handleFetch() {
    this.setState({ loading: true });
		axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/getLibraries?page=' + this.state.nextPageToFetch + '&query=' + this.state.keyword, {
      headers:{
        "API-Key": process.env.REACT_APP_API_KEY
      }
    }).then(res => {
      let temp = []
      temp = this.state.libraries
      temp.push(...res.data)
      this.setState({ libraries: [...temp], loading: false })
		})
		.catch(error => {
      console.error('Error', error)
      this.setState({ libraries: [], loading: false })
    });
	};

  handleSearch(val) {
    this.setState({ keyword:val, libraries:[], nextPageToFetch:0, currPage:0 },() => {
      console.log("Value in parent: " + this.state.keyword)
      this.handleFetch()
    })
    
  }

  componentDidMount() {
    this.handleFetch()
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
            <Icon name='file' />
            Library Details
          </Header>
        </Divider>

        <SearchBar handler = {this.handleSearch.bind(this)}/>
        
        {
          this.state.loading?
          <div>
            Loading...
            <BallBeat color={'#123abc'} loading={this.state.loading} />
          </div>
          :
          <MaterialTable
                  title="Available Libraries"
                  columns={[
                    { title: 'FileName', field: 'LIB_FILENAME'},
                    { title: 'Type', field: 'LIB_TYPE' },
                    { title: 'License', field: 'LIC_KEY' }
                  ]}
                  data={this.state.libraries}
                  options={{
                    initialPage: this.state.currPage,
                    search: false,
                    exportButton: true,
                    pageSize: this.state.renderPageSize,
                    pageSizeOptions: [this.state.renderPageSize]
                  }}
                  actions={
                    this.context.admin?
                    [{
                      key: 3,
                      icon: 'edit',
                      tooltip: 'Edit Library',
                      align : 'center',
                      onClick: (event, rowData) => this.update(rowData)
                    }]
                    :
                    []
                  }
                  onChangePage={(e) => {
                    if ((this.state.libraries.length % this.state.renderPageSize == 0) 
                      && (e == this.state.libraries.length/this.state.renderPageSize -1)) {
                      this.setState({nextPageToFetch: this.state.nextPageToFetch + 1, currPage: e}, () => {
                        this.handleFetch()
                      })
                    }
                  }}
          />
        }
      
      {this.state.update &&  
        <div>
          <Divider horizontal>
            <Header as='h4'>
              <Icon name='file' />
              Update Library
            </Header>
          </Divider>
          <div align="right">
            <Button color="secondary" variant="contained" startIcon={<Close />} onClick={this.close.bind(this)}>Close</Button>
          </div>
          <UpdateLibrary data={this.state.data} />
        </div>}          
      </div>
    );
  }
}