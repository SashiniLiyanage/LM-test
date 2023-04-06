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
import IconButton from "@material-ui/core/IconButton";
import SearchIcon from '@material-ui/icons/Search';
import InputBase from "@material-ui/core/InputBase";
import '../../styles/SearchBar.css';


export default class SearchBar extends Component {
    constructor() {
        super();
        this.state = {
          text: ''
        };
    }

    render() {
        return  <div className='searchBar'>
                    <form className='searchForm'>
                        <InputBase
                            className='textBox'
                            onInput={(e) => {
                                this.setState({text: e.target.value})
                            }}
                            placeholder="Search library..."
                        />
                        <IconButton type="submit" aria-label="search" onClick={() => {
                            this.props.handler(this.state.text)
                        }}>
                            <SearchIcon/>
                        </IconButton>
                    </form>
                </div>;
    }
}