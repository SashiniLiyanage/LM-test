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
package org.wso2.internal.apps.license.manager;

import org.apache.commons.io.FileUtils;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

/*
 * Contains the functions required for the License Generation process.
 */
public class LicenseManagerUtils {


    /**
     * Static function to unzip a file to a given location.
     * @param infile    the location of the zipped file.
     * @param outFolder location where the file should be unzipped.
     * @throws IOException
     */
    public static void unzip(String infile, String outFolder) throws IOException{

        Enumeration entries;

        try (ZipFile zipFile = new ZipFile(infile)) {
            entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = (ZipEntry) entries.nextElement();
                File f = new File(outFolder + File.separator + entry.getName());

                if (!entry.isDirectory()) {
                    f.getParentFile().mkdirs();
                    copyInputStream(zipFile.getInputStream(entry), new BufferedOutputStream(new FileOutputStream(f
                            .getAbsolutePath())));
                }
                // if (entry.isDirectory()) {
                //     System.out.println("directory: "+entry.getName());
                // }
            }
        } catch (IOException e) {
            System.out.println("Error in unziping: "+infile+" Error:"+e.getMessage());
            throw(e);
        }
    }

    private static void copyInputStream(InputStream in, OutputStream out) throws IOException {

        byte[] buffer = new byte[1024];
        int len;

        while ((len = in.read(buffer)) >= 0) {
            out.write(buffer, 0, len);
        }
        in.close();
        out.close();
    }

    /**
     * Delete folders.
     * @param filePath path to the folder.
     */
    public static void deleteFolder(String filePath) {

            File file = new File(filePath);
            if (file.isDirectory()) {
                try{
                    FileUtils.deleteDirectory(file);
                    System.out.println("Deleted directory: "+filePath);
                }catch(Exception e){
                    System.out.println(e.getMessage());
                }
            } else if (file.isFile()) {
                try{
                    file.delete();
                    System.out.println("Deleted file: "+filePath);
                }catch(Exception e){
                    System.out.println(e.getMessage());
                }
            }
    }

}