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
import React, { useContext } from 'react';
import { makeStyles } from '@material-ui/core/styles';
import Paper from '@material-ui/core/Paper';
import Link from '@material-ui/core/Link';
import Typography from '@material-ui/core/Typography';
import {Accordion,AccordionItem,AccordionItemHeading,AccordionItemPanel,AccordionItemButton} from 'react-accessible-accordion';
import 'react-accessible-accordion/dist/fancy-example.css';
import AddLibrary from './addLibrary';
import LibraryTable from './libraryTable';
import UserContext from '../../UserContext';

function Copyright() {
  return (
    <Typography variant="body2" color="textSecondary" align="center">
      {'Copyright © '}
      <Link color="textSecondary" href="#">
        License Manager Application
      </Link>{' '}
      {new Date().getFullYear()}
      {'.'}
    </Typography>
  );
}
const useStyles = makeStyles(theme => ({
  layout: {
    width: 'auto',
    marginLeft: theme.spacing(2),
    marginRight: theme.spacing(2),
    [theme.breakpoints.up(600 + theme.spacing(2) * 2)]: {
      width: 1000,
      marginLeft: 'auto',
      marginRight: 'auto',
    },
  },
  paper: {
    marginTop: theme.spacing(3),
    marginBottom: theme.spacing(3),
    padding: theme.spacing(2),
    [theme.breakpoints.up(600 + theme.spacing(3) * 2)]: {
      marginTop: theme.spacing(6),
      marginBottom: theme.spacing(6),
      padding: theme.spacing(3),
    },
  },
}));
export default function LicenseManager() {
  const classes = useStyles();
  const value = useContext(UserContext);
  return (
    <React.Fragment>
     
      <main className={classes.layout}>
        <Paper className={classes.paper}>
          <React.Fragment>
              <LibraryTable/>
            </React.Fragment>   
          </Paper>
        </main>      
        { 
        value.admin &&
        <main className={classes.layout}>
        <Paper className={classes.paper}>
          <React.Fragment>
            <Accordion>
              
              <AccordionItem>
                <AccordionItemHeading>
                  <AccordionItemButton>
                    Add New Library
                  </AccordionItemButton>
                </AccordionItemHeading>
                <AccordionItemPanel>
                  <AddLibrary/>
                </AccordionItemPanel>
              </AccordionItem>
            </Accordion>
          </React.Fragment>         
        </Paper>
      </main>
      }
      <Copyright />
    </React.Fragment>
  );
}