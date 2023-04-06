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
import axios from 'axios';
import Grid from '@material-ui/core/Grid';
import Typography from '@material-ui/core/Typography';
import Button from '@material-ui/core/Button';
import CloudUploadIcon from '@material-ui/icons/CloudUpload';
import { BallBeat } from 'react-pure-loaders';
import { Divider, Header, Icon } from 'semantic-ui-react'
import {BlobServiceClient} from '@azure/storage-blob';

export default class PackUpload extends Component {
    constructor(props) {
        super(props);
        this.state = {
            selectedFile: null,
            loading : false,
            process : false,
            upload : false,
            progress: 0
        };
    }
    toggleLoading=()=>{
      this.setState({loading: !this.state.loading})
    }
    
    onChangeHandler=event=>{
      if(event.target.files.length === 0) return;
      this.setState({
        selectedFile: event.target.files[0],
        loaded: 0,
        loading:false,
        upload:true
      })
    }

    processPack = () => {
      if (!this.state.process){
        this.setState({process : true})
        axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/processAllPacks',{
          headers:{
            "API-Key": process.env.REACT_APP_API_KEY
          }
        }).then(res=>{
          console.log("Done process")
          this.setState({process:false})
          window.location.reload();
        })
        .catch(error =>{
          this.setState({process:false})
          console.log("error process")
        })
      }
      window.location.reload();
    }
    uploadPack = async (sasToken, accountName, fileName, randomName, containerName) => {
    this.toggleLoading();

      try{
        const blobServiceClient = new BlobServiceClient(`https://${accountName}.blob.core.windows.net/?${sasToken}`);
        const containerClient = blobServiceClient.getContainerClient(containerName);
        const blobClient = containerClient.getBlockBlobClient(randomName + ".zip");
        const options = { blobHTTPHeaders: { blobContentType: this.state.selectedFile.type }, 
          onProgress: (ev) => this.setState({progress : (ev.loadedBytes/this.state.selectedFile.size)}) 
        }
        // upload file
        await blobClient.uploadData(this.state.selectedFile, options);

        axios.post(process.env.REACT_APP_BE_URL + '/LicenseManager/receiver/',{
          randomName: randomName,
          name: fileName
        },{
          headers:{
            "API-Key": process.env.REACT_APP_API_KEY
          }
        })
        .then(res=>{
          this.toggleLoading()
          alert("Successfully uploaded!!! Processing will start in a minute...")
          this.setState({process:false})
          this.processPack()
        })
        .catch(error=>{
          this.toggleLoading()
          console.log(error);
          alert("Error in uploading! Try again...")
        })

      } catch (error) {
        console.error(error);
        alert("Error in uploading! Try again...");
      }
    }
    
    onClickHandler = () => {
      this.setState({upload : false})
      axios.get(process.env.REACT_APP_BE_URL + '/LicenseManager/checkPack/' + this.state.selectedFile.name,{
        headers:{
          "API-Key": process.env.REACT_APP_API_KEY
        }
      })
      .then(res=>{
        if (!res.data.exists){
          this.uploadPack(res.data.sasToken, res.data.accountName, res.data.fileName, res.data.randomName,  res.data.containerName);
        } else {
          alert("Pack is already under process!!!")
        }
      })
      .catch(error=>{
        alert("Error in connecting to the server!!! Try again...")
      })
    }   
    render() {      
      return (
        <React.Fragment>
          <Typography component="h1" variant="h4" align="center" style={{ backgroundColor: '#ddd', padding: '10px' }}>
            License Generation
          </Typography>
          <Divider horizontal>
          <Header as='h4'>
            <Icon name='upload' />
            Uploading Pack                    
          </Header>
          </Divider>
          <Grid container spacing={3}>
            <Grid item xs={12}>
              Click here to upload the pack (.zip)
            </Grid>
            <Grid item xs={12}>
             
              <div>
               <input type="file" 
               style={{display:'none'}}
               name="file" 
               onChange={this.onChangeHandler} 
               ref={fileInput => this.fileInput = fileInput}
               accept=".zip" />
               </div>
               <Button variant="contained" color="primary" startIcon={<CloudUploadIcon />} onClick={() => this.fileInput.click()}> Upload & Generate
              </Button>
              {this.state.upload && this.onClickHandler() }
              </Grid>
              <br></br>
              <Grid item xs={12}>
                {this.state.loading && <div>Uploading pack... {Math.round(this.state.progress * 100)}% <BallBeat color={'#123abc'}loading={this.state.loading}/></div>}
              </Grid>
            </Grid>
          </React.Fragment>
        );
    }
}
