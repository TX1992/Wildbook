/*
 * The Shepherd Project - A Mark-Recapture Framework
 * Copyright (C) 2011 Jason Holmberg
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package org.ecocean.servlet;


import org.ecocean.CommonConfiguration;
import org.ecocean.Encounter;
import org.ecocean.Shepherd;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import java.util.concurrent.ThreadPoolExecutor;
import org.ecocean.MailThreadExecutorService;
import org.ecocean.NotificationMailer;



public class EncounterSetState extends HttpServlet {

  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }


  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    doPost(request, response);
  }


  private void setDateLastModified(Encounter enc) {
    String strOutputDateTime = ServletUtilities.getDate();
    enc.setDWCDateLastModified(strOutputDateTime);
  }


  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    String context="context0";
    context=ServletUtilities.getContext(request);
    Shepherd myShepherd = new Shepherd(context);
    myShepherd.setAction("EncounterSetState.class");
    //set up for response
    response.setContentType("text/html");
    PrintWriter out = response.getWriter();
    boolean locked = false;
    boolean isOwner = true;

 

    if ((request.getParameter("number") != null)&&(request.getParameter("state") != null)) {
      myShepherd.beginDBTransaction();
      Encounter changeMe = myShepherd.getEncounter(request.getParameter("number"));
      setDateLastModified(changeMe);
      String state = request.getParameter("state");

      String oldScar = "None";


      try {
        if(changeMe.getState()!=null){
          oldScar = changeMe.getState();
        }
        changeMe.setState(state);
        changeMe.addComments("<p><em>" + request.getRemoteUser() + " on " + (new java.util.Date()).toString() + "</em><br>Changed state from " + oldScar + " to " + state + ".</p>");
      } catch (Exception le) {
        locked = true;
        le.printStackTrace();
        myShepherd.rollbackDBTransaction();
      }


      if (!locked) {
        myShepherd.commitDBTransaction();
        //out.println(ServletUtilities.getHeader(request));
        out.println("<strong>Success:</strong> Encounter state has been updated from " + oldScar + " to " + state + ".");
        response.setStatus(HttpServletResponse.SC_OK);
        
        String message = "Encounter " + request.getParameter("number") + " state has been updated from " + oldScar + " to " + state + ".";
        ServletUtilities.informInterestedParties(request, request.getParameter("number"), message,context);
        notifyEmail(request, context, changeMe);  //does beyond enc.interestedResearchers
      } 
      else {
        //out.println(ServletUtilities.getHeader(request));
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        out.println("<strong>Failure:</strong> Encounter state was NOT updated because another user is currently modifying this reconrd. Please try to reset the scarring again in a few seconds.");
        

      }
    } 
    else {
     // out.println(ServletUtilities.getHeader(request));
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      out.println("<strong>Error:</strong> I don't have enough information to complete your request.");
      

    }


    out.close();
    myShepherd.closeDBTransaction();
  }



    private void notifyEmail(HttpServletRequest request, String context, Encounter enc) {
        if ((enc == null) || (request == null) || (context == null)) return;
        String langCode = null;
        ThreadPoolExecutor es = MailThreadExecutorService.getExecutorService();
        Map<String, String> tagMap = NotificationMailer.createBasicTagMap(request, enc);

        String message = "Encounter " + enc.getCatalogNumber() + " state has been marked as '" + enc.getState() + "'.\n";
        tagMap.put(NotificationMailer.STANDARD_CONTENT_TAG, message);

/*
        //notify new submission?  for now: no?
        String mailTo = CommonConfiguration.getNewSubmissionEmail(context);
        NotificationMailer mailer = new NotificationMailer(context, null, enc.getSubmitterEmail(), "encounterDataUpdate", tagMap);
        es.execute(mailer);
*/

        //"others"
        tagMap.put(NotificationMailer.EMAIL_NOTRACK, "number=" + enc.getCatalogNumber());
        String submitter = enc.getSubmitterEmail();
        String informers = enc.getInformOthers();
System.out.println("INFO: EncounterSetState.notifyEmail() -> " + submitter + ", " + informers);
        Set<String> cSubmitters = new HashSet<>();
        if (submitter != null) cSubmitters.addAll(NotificationMailer.splitEmails(submitter));
        if (informers != null) cSubmitters.addAll(NotificationMailer.splitEmails(informers));
        for (String emailTo : cSubmitters) {
            tagMap.put(NotificationMailer.EMAIL_HASH_TAG, Encounter.getHashOfEmailString(emailTo));
            es.execute(new NotificationMailer(context, langCode, emailTo, "encounterDataUpdate", tagMap));
        }
        es.shutdown();
    }
}
  
  
