<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.joda.time.LocalDateTime,org.joda.time.DateTime,
org.joda.time.format.DateTimeFormatter,
org.joda.time.format.ISODateTimeFormat,java.net.*,
org.ecocean.grid.*,
java.io.*,java.util.*, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*,org.ecocean.servlet.*,org.ecocean.media.*,javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Iterator, java.lang.NumberFormatException, org.json.JSONObject"%>

<%!
<<<<<<< HEAD
  public int getBestIndex(Long millis, Map<Integer, Long> timeRankMap, long tolerance) {
=======


  public String getIndivNameFromDirName(String fishDirName) {
    if (fishDirName==null) return null;
    return fishDirName.split("_")[0].trim();
  }

  public int getBestIndex(Long millis, Map<Integer, Long> timeRankMap, long tolerance) {

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
    long bestDistance = Long.MAX_VALUE;
    int bestIndex = -1;
    if (millis == null) return bestIndex;
    try {
<<<<<<< HEAD
      for (Integer index : timeRankMap.keySet()) {
        long diff = Math.abs(millis.longValue() - timeRankMap.get(index).longValue());
        if ( diff <= tolerance && diff < bestDistance) {
          bestDistance = diff;
          bestIndex = index.intValue();
        }
      }
    } catch (Exception e) {
      System.out.println("ERROR: getBestIndex on input ("+millis+", "+timeRankMap+", "+tolerance+")");
      e.printStackTrace();
    }
    return bestIndex;
  }

=======
    for (Integer index : timeRankMap.keySet()) {

      long diff = Math.abs(millis.longValue() - timeRankMap.get(index).longValue());

      if ( diff <= tolerance && diff < bestDistance) {
        bestDistance = diff;
        bestIndex = index.intValue();
      }
    }
    }
    catch (Exception e) {
      System.out.println("ERROR: getBestIndex on input ("+millis+", "+timeRankMap+", "+tolerance+")");
      e.printStackTrace();
    }

    return bestIndex;

  }

  public void parseFishFolder(File fishDir, String indID, Shepherd myShepherd, boolean committing, AssetStore as, JspWriter out, HttpServletRequest request) throws IOException {

    if (!fishDir.isDirectory()) return;

    String dirName = fishDir.getName();

    boolean isTopLevel = dirName.toLowerCase().contains("fish");

    if (isTopLevel && indID==null) indID = getIndivNameFromDirName(dirName);

    boolean isLeft = dirName.toLowerCase().contains("left");
    boolean isRight = dirName.toLowerCase().contains("right");
    boolean isSided = (isLeft || isRight);

    out.println("<p>Parsing indiv. "+indID+" in Folder: "+dirName+"</p>");
    out.println("<p>isTopLevel="+isTopLevel+" isLeft="+isLeft+" isRight="+isRight+" isSided="+isSided+"</p><ul>");

    String indivName = fishDir.getName().split("_")[0].trim();
    String[] dirContents = fishDir.list();

    for (String fname : dirContents) {

      File subFile = new File(fishDir, fname);
      out.println("<li>"+fname+" isPic = "+isPic(subFile)+"</li>");

      if (isPic(subFile)) try { parseFishPic(subFile, indID, isSided, isLeft, myShepherd, committing, as, out, request);
      } catch (Exception e) {
        out.println("<li>ERROR on parseFishPic("+fname+")</li></ul>");
        e.printStackTrace();
      }
      else parseFishFolder(subFile, indID, myShepherd, committing, as, out, request);

    }
    out.println("</ul> <p>Done setting up fish folder "+dirName+"</p>");
  }

  public boolean isPic(File maybePic) throws IOException {
    String fname = maybePic.getName();
    int lastDot = fname.lastIndexOf(".");
    if (lastDot < 0 || lastDot == (fname.length()-1)) return false;
    String ext = maybePic.getName().substring(lastDot).toLowerCase();
    return (ext.equals(".png") || ext.equals(".jpg") || ext.equals(".jpeg"));

  }

  public void parseFishPic(File fishPic, String indID, boolean isSided, boolean isLeft, Shepherd myShepherd, boolean committing, AssetStore as, JspWriter out, HttpServletRequest request) throws IOException, org.datanucleus.api.rest.orgjson.JSONException {

    String sideString = isSided ? (isLeft ? "left" : "right") : "none";

    out.println("<ul>");

    out.println("<li>Parsing fish "+indID+" side = "+sideString+" in pic "+fishPic.getName()+"</li>");


    JSONObject params = as.createParameters(fishPic);
    MediaAsset ma = new MediaAsset(as, params);
    ma.addLabel("_original");
    if (committing) {
      ma.copyIn(fishPic);
      myShepherd.getPM().makePersistent(ma);
      ma.updateStandardChildren(myShepherd);
      ma.updateMinimalMetadata();
    }

    addMaToInd(ma, indID, myShepherd, committing, out, request);

    org.datanucleus.api.rest.orgjson.JSONObject maJson = new org.datanucleus.api.rest.orgjson.JSONObject();
    maJson = ma.sanitizeJson(request, maJson);
    out.println("<li>Media Asset = "+maJson+"</li>");



    out.println("</ul>");


  }

  public void addMaToInd(MediaAsset ma, String indID, Shepherd myShepherd, boolean committing, JspWriter out, HttpServletRequest request) throws IOException, org.datanucleus.api.rest.orgjson.JSONException {

    String species = "Stereolepis gigas";
    Annotation ann = new Annotation(species, ma);
    if (committing) myShepherd.getPM().makePersistent(ann);
    Encounter enc = new Encounter(ann);
    enc.setIndividualID(indID);
    if (committing) myShepherd.storeNewEncounter(enc, Util.generateUUID());

    out.println("<li>Encounter = "+enc.sanitizeJson(request, new org.datanucleus.api.rest.orgjson.JSONObject())+"</li>");

    if (myShepherd.isMarkedIndividual(indID)) {
      MarkedIndividual ind = myShepherd.getMarkedIndividual(indID);
      ind.addEncounter(enc, "context0");
      if (committing) {
        myShepherd.commitDBTransaction();
        myShepherd.beginDBTransaction();
      }
    } else {

      MarkedIndividual ind = new MarkedIndividual(indID, enc);
      if (committing) myShepherd.storeNewMarkedIndividual(ind);

    }
  }


>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
  public int getBestIndex(Long millis, Map<Integer, Long> timeRankMap) {
    long oneWeekInMilliseconds = 604800000;
    return getBestIndex(millis, timeRankMap, oneWeekInMilliseconds * 10);
  }
<<<<<<< HEAD
  
=======

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
  public boolean isDirectoryWithFiles(File dir) {
    try {
      return (dir.isDirectory() && dir.list().length > 0);
    } catch (Exception e) {}
    return false;
  }
<<<<<<< HEAD
=======

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
%>


<%
<<<<<<< HEAD
String context="context0";
context=ServletUtilities.getContext(request);
Shepherd myShepherd=new Shepherd(context);
=======

String context="context0";
context=ServletUtilities.getContext(request);

Shepherd myShepherd=new Shepherd(context);



>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
%>

<html>
<head>
<title>Import Local Media</title>

</head>


<body>
<h1>Importing Local Media</h1>

<ul>
<%
<<<<<<< HEAD
myShepherd.beginDBTransaction();
int numFixes=0;
List<String> nonIndividualDirectories = new ArrayList<String>();
int numPhotosMatched = 0;
int numPhotosNotMatched = 0;
boolean committing=true;
Map<String,String> dirToIndivName = new HashMap<String,String>();
dirToIndivName.put("testing!!!!!!!!!","testIndy");
dirToIndivName.put("CHISPAS", "Chispa");
dirToIndivName.put("DALILA", "Dalila?");
dirToIndivName.put("ELECTRA", "Electro");
dirToIndivName.put("Era", "Eral");
dirToIndivName.put("GALA", "Galo");
dirToIndivName.put("Germanal", "German");
dirToIndivName.put("HEROE", "Felina");
dirToIndivName.put("Hada", "Charqueña");
dirToIndivName.put("JALEA", "Jaleo");
dirToIndivName.put("JUNCOSA", "Junco");
dirToIndivName.put("Jacana","Jacara");
dirToIndivName.put("Jason","Jasione");
dirToIndivName.put("Listo","Litos");
//dirToIndivName.put("","");
%><p>Directory name to Individual name map: <%=dirToIndivName %> <%
try {
	String rootDir = getServletContext().getRealPath("/");
	String baseDir = ServletUtilities.dataDir(context, rootDir).replaceAll("dev_data_dir", "wildbook_data_dir");
  //String pathToUpdateFile="C:\\splash\\CRC SPLASHID additional sightings.mdb";
  //String rootDir="C:/apache-tomcat-8.0.24/webapps";
  String lynxPhotoPath="/data/lynx_photos/individuals";
  //String rootURL="http://localhost:8080";
  String rootURL="http://lynx.wildbook.org";
=======

myShepherd.beginDBTransaction();

int numFixes=0;
List<String> nonIndividualDirectories = new ArrayList<String>();

int numPhotosMatched    = 0;
int numPhotosNotMatched = 0;
boolean committing = true;




try {

	String rootDir = getServletContext().getRealPath("/");
	String baseDir = ServletUtilities.dataDir(context, rootDir).replaceAll("dev_data_dir", "wildbook_data_dir");

  //String pathToUpdateFile="C:\\splash\\CRC SPLASHID additional sightings.mdb";
  //String rootDir="C:/apache-tomcat-8.0.24/webapps";

  String bassPhotoPath="/data/spottedbass";
  //String rootURL="http://localhost:8080";
  String rootURL="http://35.164.110.53:8080/wildbook";
>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
  //String splashImagesDirPath="C:/Users/jholmber/Dropbox/RingedSeal/DISCOVERY_DATA";
  //String splashImagesDirPath="/data/RingedSeal/DISCOVERY_DATA";
  String urlToThumbnailJSPPage=rootURL+"wildbook/resetThumbnail.jsp";
  String assetStorePath="/data/wildbook_data_dir";
<<<<<<< HEAD
  String assetStoreURL="http://lynx.wildbook.org/wildbook_data_dir";
=======
  String assetStoreURL="http://35.164.110.53:8080/wildbook_data_dir";

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
  //AssetSyore work
  ////////////////begin local //////////////
  if (committing) myShepherd.beginDBTransaction();
  LocalAssetStore as = new LocalAssetStore("WWF-Lynx-Asset-Store", new File(assetStorePath).toPath(), assetStoreURL, true);
  if (committing) myShepherd.getPM().makePersistent(as);
  if (committing) myShepherd.commitDBTransaction();
////////////////end local //////////////
<<<<<<< HEAD
String encountersDirPath=assetStorePath+"/encounters";
=======


String encountersDirPath=assetStorePath+"/encounters";


>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
  %>
  <p>Root Dir = <%=rootDir%></p>
  <p>Base Dir = <%=baseDir%></p>
  <p>Asset Store Path = <%=assetStorePath%></p>
<<<<<<< HEAD
  <p>Lynx Photo Path = <%=lynxPhotoPath%></p>
  <p>Asset Store URL = <%=assetStoreURL%></p>
  <p>Encounters Dir = <%=encountersDirPath%></p>
  <%
	Iterator allEncs=myShepherd.getAllEncounters();
  File lynxDir = new File(lynxPhotoPath);
  %><p>Lynx Dir is directory: <%=lynxDir.isDirectory()%></p> <%
  if (lynxDir.isDirectory()) {
    String[] subDirs = lynxDir.list();
    %><p>num subdirs: <%=subDirs.length%></p><%
    %><p>lynx directory contents:<ul><%
    if (committing) myShepherd.beginDBTransaction();
    for (String subDir : subDirs) {
      String indivName = Util.utf8ize(subDir);
      MarkedIndividual indy = myShepherd.getMarkedIndividualWithNameJostling(indivName, dirToIndivName);
      boolean isIndividual = (indy!=null);
      %><%=subDir%> isIndividual = <%=isIndividual%><%
      File indivDir = new File(lynxDir, subDir);
=======
  <p>Lynx Photo Path = <%=bassPhotoPath%></p>
  <p>Asset Store URL = <%=assetStoreURL%></p>
  <p>Encounters Dir = <%=encountersDirPath%></p>
  <%



	Iterator allEncs=myShepherd.getAllEncounters();


  File bassDir = new File(bassPhotoPath);
  %><p>Lynx Dir is directory: <%=bassDir.isDirectory()%></p> <%
  if (bassDir.isDirectory()) {
    String[] subDirs = bassDir.list();
    %><p>num subdirs: <%=subDirs.length%></p><%
    %><p>bass directory contents:<%

    if (committing) myShepherd.beginDBTransaction();
    for (String subDir : subDirs) {

      String indivName = getIndivNameFromDirName(subDir);

      MarkedIndividual indy = myShepherd.getMarkedIndividualQuiet(indivName);
      boolean isIndividual = (indy!=null);

      %><p><%=indivName%> isIndividual = <%=isIndividual%></p><%


      File indivDir = new File(bassDir, subDir);
>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
      if (!indivDir.isDirectory()) {
        %><p>NON-DIRECTORY: <%=subDir%></p><%
        continue;
      }
//      if (!isIndividual) continue;
<<<<<<< HEAD
      if (!isIndividual) {
        if (isDirectoryWithFiles(indivDir)) nonIndividualDirectories.add(subDir);
        // make an annotation for each photo
        // make an encounter for each annotation
        // make an individual from the encounters
        continue;
      }
      Encounter[] sortedEncs = indy.getDateSortedEncounters();
      Map<Integer, Long> encTimeMap = new HashMap<Integer, Long>();
      %><%=subDir%> encounter time map: <ul><%
      for (int i = 0; i < sortedEncs.length; i++) {
        Long thisMillis = sortedEncs[i].getDateInMilliseconds();
        if (thisMillis == null) continue;
        encTimeMap.put(new Integer(i), thisMillis);
        DateTime thisDT = new DateTime(thisMillis);
        %><li><%=i%>: <%=thisMillis%> (<%=thisDT%>)</li><%
      }
      %></ul><%
      int numEncs = 0;
      if (sortedEncs!=null) numEncs = sortedEncs.length;
      %><li><%=subDir%> is a directory, isIndividual=<%=isIndividual%> with <%=numEncs%> encounters and contents<ul><%
      String[] indivPhotos = indivDir.list();
      for (String photoName : indivPhotos) {
        File photo = new File(indivDir, photoName);
        %><li><%=photoName%> is file: <%= !photo.isDirectory()%><ul><%
        if (photo.isDirectory()) continue;
  // unindenting for legibility: here is central code block where we
  // will transform photo into a MediaAsset, then find the corresponding Encounter and attach to it.
  JSONObject params = as.createParameters(photo);
  MediaAsset ma = null;
  Long millisModified = null;
  DateTime modified = null;
  //params.put("path", photo.getAbsolutePath());
  %><li>params = <%=params.toString()%></li><%
  try {
    ma = new MediaAsset(as, params);
    %><li>Created a MediaAsset with parameters <%=ma.getParameters().toString()%></li><%
  } catch (Exception e) {
    %><li>Was NOT able to create a MediaAsset!</li><%
  }
  try {
    millisModified = photo.lastModified();
    modified = new DateTime(millisModified);
    %><li>parsed DateTime = <%=modified%></li><%
  } catch (Exception e) {
    %><li>Was NOT able to parse DateTime!</li><%
  }
  if (millisModified == null || ma == null) continue;
  ma.addLabel("_original");
  if (committing) {
    ma.copyIn(photo);
    myShepherd.getPM().makePersistent(ma);
    ma.updateStandardChildren(myShepherd);
    ma.updateMinimalMetadata();
  }
  Annotation ann = new Annotation("Lynx pardinus", ma);
  if (committing) {
    myShepherd.storeNewAnnotation(ann);
  }
  if (ma.getDateTime()==null) ma.setUserDateTime(modified);
  Long dateMillis = null;
  if (ma.getDateTime()!=null) dateMillis = ma.getDateTime().getMillis();
  %><li>and DateTime <%=ma.getDateTime()%> (in millis: <%=dateMillis%>)</li><%
  int bestIndex = getBestIndex(dateMillis, encTimeMap);
  Long bestEncMillis = null;
  DateTime bestEncDateTime = null;
  if (bestIndex>=0) bestEncMillis = encTimeMap.get(new Integer(bestIndex));
  if (bestEncMillis!=null) {
    bestEncDateTime = new DateTime(bestEncMillis);
    numPhotosMatched++;
    // attach media asset to encounter
    Encounter matchedEnc = sortedEncs[bestIndex];
    %><li>Adding to encounter number <%=matchedEnc.getCatalogNumber()%></li><%
    if (committing) matchedEnc.addAnnotation(ann);
  } else {
    numPhotosNotMatched++;
    Encounter newEnc = new Encounter(ann);
    newEnc.setIndividualID(indy.getIndividualID());
    if (committing) myShepherd.storeNewEncounter(newEnc, Util.generateUUID());
    if (committing) indy.addEncounter(newEnc, context);
  }
  %><li>Encounter time map index match:<%=bestIndex%>; bestEncMillis = <%=bestEncMillis%>; bestEncDateTime = <%=bestEncDateTime%></li><%
  %></ul></li><%
      }
      %></ul></li><%
=======

      parseFishFolder(indivDir, null, myShepherd, committing, as, out, request);


      if (!isIndividual) {
        if (isDirectoryWithFiles(indivDir)) nonIndividualDirectories.add(subDir);
      }


>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
      if (committing) {
        numFixes++;
        myShepherd.commitDBTransaction();
        myShepherd.beginDBTransaction();
      }
<<<<<<< HEAD
    } // end for subDir in lynxDir.subDirs
    %></ul></p><%
  } else {
  }
	while(allEncs.hasNext()){
=======

    } // end for subDir in bassDir.subDirs
    %></ul></p><%
  } else {

  }

	while(allEncs.hasNext()){

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
		Encounter enc=(Encounter)allEncs.next();
    if (committing) {
      myShepherd.commitDBTransaction();
      myShepherd.beginDBTransaction();
    }
<<<<<<< HEAD
=======

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
	}
}
catch(Exception e){
	myShepherd.rollbackDBTransaction();
}
finally{
	myShepherd.closeDBTransaction();
<<<<<<< HEAD
}
java.util.Collections.sort(nonIndividualDirectories);
=======

}


java.util.Collections.sort(nonIndividualDirectories);

>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1
%>

</ul>
<div style="font-family:monospace">
<p>Done successfully: <%=numFixes %></p>
<p>Non Individual Directories: <ul><%
for (String dirName : nonIndividualDirectories) {
  %><li><%=dirName%></li><%
}
%></ul></p>
<p>Num Photos Matched: <%=numPhotosMatched %></p>
<p>Num Photos Not Matched: <%=numPhotosNotMatched %></p>
</div>

</body>
<<<<<<< HEAD
</html>
=======
</html>
>>>>>>> 1ac944a1145885e5c0dc516cec8b595ab1509dd1