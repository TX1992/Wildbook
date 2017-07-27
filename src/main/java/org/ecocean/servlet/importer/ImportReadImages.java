package org.ecocean.servlet.importer;

import org.json.JSONObject;

import java.io.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

import org.ecocean.*;
import org.ecocean.servlet.*;
import org.joda.time.DateTime;
import org.ecocean.media.*;
import org.apache.commons.io.FilenameUtils;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.xssf.usermodel.XSSFCell;
//import org.apache.poi.hssf.usermodel.*;
//import org.apache.poi.poifs.filesystem.NPOIFSFileSystem;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ImportReadImages extends HttpServlet {
  /**
   * 
   */
  private HashMap<String,HashMap<String,String>> data = new HashMap<String,HashMap<String,String>>();
  private HashMap<String,MediaAsset> filenames = new HashMap<String,MediaAsset>();
  private static final long serialVersionUID = 1L;
  private static PrintWriter out;
  private static String context; 
  private int failedAssets = 0;
  private int assetsCreated = 0;
  
  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }

  public void doGet(HttpServletRequest request,  HttpServletResponse response) throws ServletException,  IOException {
    doPost(request,  response);
  }
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException,  IOException { 
    out = response.getWriter();
    context = ServletUtilities.getContext(request);
    out.println("Preparing to import image files.");
    Shepherd myShepherd = new Shepherd(context);
    myShepherd.setAction("ImportReadImages.class");
    myShepherd.beginDBTransaction();
    if (!CommonConfiguration.isWildbookInitialized(myShepherd)) {
      out.println("WARNING: Wildbook not initialized. Starting Wildbook");    
      StartupWildbook.initializeWildbook(request, myShepherd);
    }
    myShepherd.commitDBTransaction();
    
    String imageDir = "/opt/dukeImport/DUML Files to Jason-Dream Database/REVISED DATA for JASON-USE THESE!/NEW-species photo-id catalog files/";
    File rootFile = new File(imageDir);
    out.println(rootFile.getAbsolutePath());
    if (rootFile.exists()) {
      out.println("Directory Exists Hooray!");
    } else {
      out.println("The Specified Directory Doesn't Exist.");
    }
    //Grabs images and created media assets.
    // Also runs throught all excel files and stores data for each image in an array
    //with the image name as the key.
    getExcelFiles(rootFile, myShepherd); 
    
    getImageFiles(rootFile, myShepherd); 
    
    associateAssetsAndData(myShepherd);
    
    out.println("Created "+assetsCreated+" new MediaAssets.");
    out.println(failedAssets+" assets failed to be created.");
    
    myShepherd.closeDBTransaction();
  }
  
  public void getImageFiles(File path, Shepherd myShepherd) {
    try {
      if (path.isDirectory()) {
        String[] subDirs = path.list();
        System.out.println("There are "+subDirs.length+" files in the folder"+path.getAbsolutePath());
        for (int i=0;subDirs!=null&&i<subDirs.length;i++ ) {
          getImageFiles(new File(path, subDirs[i]), myShepherd);
        }
      }
      if (path.isFile()&&!path.getName().endsWith("xlsx")) {
        out.println("Found file: "+path.getName());
        boolean success = processImage(path, myShepherd);
        // boolean success = true;
        if (success) {
          assetsCreated++;
        } else {
          failedAssets++;
        }
      } 
      if (path.isDirectory()) {
        out.println("Found Directory: "+path.getAbsolutePath());
      }
    } catch (Exception e) {
      e.printStackTrace();
      out.println("Failed to traverse Image and excel files at path "+path.getAbsolutePath()); 
    }
  }
  
  public void getExcelFiles(File path, Shepherd myShepherd) {
    try {
      if (path.isDirectory()) {
        String[] subDirs = path.list();
        System.out.println("There are "+subDirs.length+" files in the folder"+path.getAbsolutePath());
        for (int i=0;subDirs!=null&&i<subDirs.length;i++ ) {
          getExcelFiles(new File(path, subDirs[i]), myShepherd);
        }
      } 
      if (path.isFile()&&path.getName().endsWith("xlsx")) {
        collectExcelData(path, myShepherd);
      }
      if (path.isDirectory()) {
        out.println("Found Directory: "+path.getAbsolutePath());
      }
    } catch (Exception e) {
      e.printStackTrace();
      out.println("Failed to traverse Image and excel files at path "+path.getAbsolutePath()); 
    }
  }
  
  public boolean processImage(File image, Shepherd myShepherd) {
    AssetStore assetStore = AssetStore.getDefault(myShepherd);
    JSONObject params = new JSONObject();
    MediaAsset ma = null;
    File photo = null;
    //out.println("Image Path? : /"+FilenameUtils.getPath(image.getAbsolutePath()));
    //out.println("Image Name? : "+image.getName());
    try {
      photo = new File("/"+FilenameUtils.getPath(image.getAbsolutePath()),image.getName());
      params = assetStore.createParameters(photo);
      
      ma = new MediaAsset(assetStore, params);
      ma.addDerivationMethod("Bass Importer", System.currentTimeMillis());
      ma.addLabel("_original");
      ma.copyIn(photo);
    } catch (Exception e) {
      e.printStackTrace();
      out.println("!!!! Error Trying to Create Media Asset!!!!");
      return false;
    }
    if (ma!=null) {
      try {
        myShepherd.beginDBTransaction();
        myShepherd.getPM().makePersistent(ma);
        myShepherd.commitDBTransaction();
        
        filenames.put(photo.getName(), ma);
        
        ma.updateMetadata();
        ma.updateStandardChildren(myShepherd);
      } catch (Exception e) {
        myShepherd.rollbackDBTransaction();
        e.printStackTrace();
        out.println("!!!! Could not Persist Media Asset !!!!");
        return false;
      }
    }      
    out.println("Created a new MediaAsset. Filename : "+assetStore.getFilename(ma));
    return true;
  }
  
  public void collectExcelData(File file, Shepherd myShepherd) throws IOException { 
    out.println("\nHey! It's an excel file! Nom Nom."+file.getName());
    // We are going to make a huge Map of all the metadata we need from Excel, and store 
    // it to process later after all images are in. The key will be the image filename.

    HashMap<String,HashMap<String,String>> data = new HashMap<String,HashMap<String,String>>();
    FileInputStream fs = new FileInputStream(file);
    XSSFWorkbook wb = new XSSFWorkbook(fs);
    wb.setMissingCellPolicy(XSSFRow.CREATE_NULL_AS_BLANK);
    XSSFRow row = null;
    DataFormatter formatter = new DataFormatter(); 

    //Hardcoded to the first sheet...
    XSSFSheet sheet = wb.getSheetAt(0);
    int rows = sheet.getPhysicalNumberOfRows();;
    int cols = 0;

    HashMap<String,String> rowData = null;

    // Triple for loops? Has the world gone mad?
    for (int i=1;i<rows;i++) {
      out.println("Current Row : "+i);
      sheet = wb.getSheetAt(0);
      rows = sheet.getPhysicalNumberOfRows();
      //out.println("Rows in this Excel file : "+rows);
      cols = sheet.getRow(0).getLastCellNum();
      //out.println("Columns in sheet 0: "+cols);
      row = sheet.getRow(i);
      rowData = new HashMap<String,String>(19);
      for (int j=0;j<cols-1;j++) {
        XSSFCell cell = row.getCell(j);
        //out.println("RAW CELL : "+cell.toString());
        String cellKey = formatter.formatCellValue(cell.getSheet().getRow(0).getCell(j));
        String cellValue = formatter.formatCellValue(cell);
        out.println("Current Column : "+j);
        out.println("Cell Value : "+cellValue);
        if (cellValue!=null&&!cellValue.equals(cellKey)) {
          rowData.put(cellKey, cellValue);
          out.println("Adding Key : "+cellKey+" Value : "+cellValue);
        } else {
          rowData.put(cellKey, "");
          out.println("Adding Key : "+cellKey+" Value : "+cellValue);
        }
      }
      sheet = wb.getSheetAt(1);
      rows = sheet.getPhysicalNumberOfRows();
      //out.println("Rows in this Excel file : "+rows);
      cols = sheet.getRow(0).getLastCellNum();
      //out.println("Columns in sheet 1: "+cols);
      row = sheet.getRow(i);
      //out.println("Current Row : "+i);
      for (int k=0;k<cols-1;k++) {
        XSSFCell cell = row.getCell(k);
        String cellKey = formatter.formatCellValue(cell.getSheet().getRow(0).getCell(k));
        String cellValue = formatter.formatCellValue(cell);
        out.println("Current Column : "+k);
        out.println("Cell Value : "+cellValue);
        if (cellValue!=null&&!cellValue.equals(cellKey)) {
          rowData.put(cellKey, cellValue);
          out.println("Adding Key : "+cellKey+" Value : "+cellValue);
        } else {
          rowData.put(cellKey, "");
          out.println("Adding Key : "+cellKey+" Value : "+cellValue);
        }
      }
      out.println(rowData.toString()+"\n\n");
      data.put(rowData.get("image_file"), rowData);
    }
    wb.close();
    out.println(data.toString());
  }
  
  private void associateAssetsAndData(Shepherd myShepherd) {
    
    for (String key : filenames.keySet()) {
      HashMap <String,String> excelData = data.get(key);
      MediaAsset ma = filenames.get(key);
      
      String indyID = excelData.get("id_code");
      String date = excelData.get("date");
      
      out.println("Date : "+date+" IndyID : "+indyID);
      
      processDate(date);
    }
    
    
    
  }
  
  private String processDate(String date) {
    out.println("\nDATE :"+date+"\n");
    date = date.substring(0,5) +"/"+ date.substring(5,7) +"/"+ date.substring(7,10);
    out.println("\n NEW DATE :"+date+"\n");
    return date;
  }

}














