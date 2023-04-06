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
import { Button, CssBaseline } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { Header} from 'semantic-ui-react';
import Paper from '@material-ui/core/Paper';
import Typography from '@material-ui/core/Typography';
import './styles/App.css';
import './styles/index.css';
import { useHistory } from 'react-router-dom';

const useStyles = makeStyles(theme => ({
    layout: {
      width: 'auto',
      marginLeft: theme.spacing(2),
      marginRight: theme.spacing(2),
      [theme.breakpoints.up(600 + theme.spacing(2) * 2)]: {
        width: 850,
        marginLeft: 'auto',
        marginRight: 'auto',
      },
    },
    paper: {
      marginTop: theme.spacing(3),
      marginBottom: theme.spacing(3),
      maxHeight: '100%',
      height: '100%',
      padding: theme.spacing(2),
      [theme.breakpoints.up(600 + theme.spacing(3) * 2)]: {
        marginTop: theme.spacing(6),
        marginBottom: theme.spacing(6),
        padding: theme.spacing(3),
      }
    }
  }));

export default function NotFoundPage(){
    const classes = useStyles();
    const history = useHistory();
  
    return(
        <React.Fragment>
            <CssBaseline/>
                <div className="content">
                <main className={classes.layout}>
                    <Paper className={classes.paper}>
                        <Typography component="h1" variant="h4" align="center" style={{ backgroundColor: '#ddd', padding: '10px' }}>
                            Page Not Found
                        </Typography>

                        <Header as='h4'></Header>
                        <Button variant="contained" color='primary' onClick={() => history.goBack()}>Go Back</Button>
                    </Paper>
                </main>
                </div>
        </React.Fragment>
    );
}