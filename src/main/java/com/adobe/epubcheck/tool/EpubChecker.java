/*
 * Copyright (c) 2007 Adobe Systems Incorporated
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy of
 *  this software and associated documentation files (the "Software"), to deal in
 *  the Software without restriction, including without limitation the rights to
 *  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 *  the Software, and to permit persons to whom the Software is furnished to do so,
 *  subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 *    <AdobeIP#0000474>
 */

package com.adobe.epubcheck.tool;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.w3c.epubcheck.core.Checker;
import org.w3c.epubcheck.util.url.URLUtils;

import com.adobe.epubcheck.api.EPUBProfile;
import com.adobe.epubcheck.api.EpubCheck;
import com.adobe.epubcheck.api.EpubCheckFactory;
import com.adobe.epubcheck.api.LocalizableReport;
import com.adobe.epubcheck.api.Report;
import com.adobe.epubcheck.messages.MessageDictionaryDumper;
import com.adobe.epubcheck.nav.NavChecker;
import com.adobe.epubcheck.opf.OPFChecker;
import com.adobe.epubcheck.opf.OPFChecker30;
import com.adobe.epubcheck.opf.ValidationContext;
import com.adobe.epubcheck.opf.ValidationContext.ValidationContextBuilder;
import com.adobe.epubcheck.ops.OPSChecker;
import com.adobe.epubcheck.overlay.OverlayChecker;
import com.adobe.epubcheck.reporting.CheckingReport;
import com.adobe.epubcheck.util.Archive;
import com.adobe.epubcheck.util.DefaultReportImpl;
import com.adobe.epubcheck.util.EPUBVersion;
import com.adobe.epubcheck.util.FeatureEnum;
import com.adobe.epubcheck.util.FileResourceProvider;
import com.adobe.epubcheck.util.GenericResourceProvider;
import com.adobe.epubcheck.util.InvalidVersionException;
import com.adobe.epubcheck.util.Messages;
import com.adobe.epubcheck.util.OPSType;
import com.adobe.epubcheck.util.ReportingLevel;
import com.adobe.epubcheck.util.URLResourceProvider;
import com.adobe.epubcheck.util.XmlReportImpl;
import com.adobe.epubcheck.util.XmpReportImpl;
import com.adobe.epubcheck.util.outWriter;

import io.mola.galimatias.GalimatiasParseException;
import io.mola.galimatias.URL;

public class EpubChecker
{

  static {
    /* fix #665 (window-less "Checker" gui app on Mac)
     * set -Djava.awt.headless=true programmatically as early as possible
     */
    System.setProperty("java.awt.headless", "true");
  }

  String path = null;
  String mode = null;
  EPUBProfile profile = null;
  EPUBVersion version = EPUBVersion.VERSION_3;
  boolean expanded = false;
  boolean keep = false;
  boolean jsonOutput = false;
  boolean xmlOutput = false;
  boolean xmpOutput = false;
  File fileOut;
  File listChecksOut;
  File customMessageFile;
  boolean listChecks = false;
  boolean displayHelp = false;
  boolean displayVersion = false;
  boolean useCustomMessageFile = false;
  boolean failOnWarnings = false;
  private Messages messages = Messages.getInstance();
  private Locale locale = Locale.getDefault();
  
  int reportingLevel = ReportingLevel.Info;

  private static final HashMap<OPSType, String> modeMimeTypeMap;
  private static final String EPUBCHECK_CUSTOM_MESSAGE_FILE = "ePubCheckCustomMessageFile";

  static
  {
    HashMap<OPSType, String> map = new HashMap<OPSType, String>();

    map.put(new OPSType("xhtml", EPUBVersion.VERSION_2), "application/xhtml+xml");
    map.put(new OPSType("xhtml", EPUBVersion.VERSION_3), "application/xhtml+xml");

    map.put(new OPSType("svg", EPUBVersion.VERSION_2), "image/svg+xml");
    map.put(new OPSType("svg", EPUBVersion.VERSION_3), "image/svg+xml");

    map.put(new OPSType("mo", EPUBVersion.VERSION_3), "application/smil+xml");
    map.put(new OPSType("nav", EPUBVersion.VERSION_3), "application/xhtml+xml");
    modeMimeTypeMap = map;
  }

  public Locale getLocale() {
    return locale;
  }
  


  public int run(String[] args)
  {
    Report report = null;
    int returnValue = 1;
    try
    {
      if (processArguments(args))
      {
        if (displayHelp || (displayVersion && path == null))
        {
          return 0;
        }
        report = createReport();
        report.initialize();
        if (listChecks)
        {
          dumpMessageDictionary(report);
          return 0;
        }
        if (useCustomMessageFile)
        {
          report.setCustomMessageFile(customMessageFile.getAbsolutePath());
        }
        returnValue = processFile(report);
        int returnValue2 = report.generate();
        if (returnValue == 0)
        {
          returnValue = returnValue2;
        }
      }
    } catch (Exception ignored)
    {
      returnValue = 1;
    } finally
    {
      if (report != null) {
        printEpubCheckCompleted(report);
      }
    }
    return returnValue;  
  }
  @Deprecated
  public int processEpubFile(String[] args)
  {
    return run(args);
  }

  int validateFile(String path, EPUBVersion version, Report report, EPUBProfile profile)
  {
    GenericResourceProvider resourceProvider;
    URL url;
    if (path.startsWith("http://") || path.startsWith("https://"))
    {
      try
      {
        url = URL.parse(path);
        resourceProvider = new URLResourceProvider();
      } catch (GalimatiasParseException e)
      {
        //FIXME 2022 add dedicate message
        System.err.println(String.format(messages.get("file_not_found"), path));
        return 1;
      }
    }
    else
    {
      File f = new File(path);
      if (f.exists())
      {
        url = URLUtils.toURL(f);
        resourceProvider = new FileResourceProvider(f);
      }
      else
      {
        System.err.println(String.format(messages.get("file_not_found"), path));
        return 1;
      }
    }

    OPSType opsType = new OPSType(mode, version);

    ValidationContext context = new ValidationContextBuilder().url(url)
        .report(report).resourceProvider(resourceProvider).mimetype(modeMimeTypeMap.get(opsType))
        .version(version).profile(profile).build();
    
    Checker checker = null;
    if (mode == null) {
      checker = EpubCheckFactory.getInstance().newInstance(context);
    } else {
      switch (mode)
      {
      case "opf":
        if (version == EPUBVersion.VERSION_2) {
          checker = new OPFChecker(context);
        } else {
          checker = new OPFChecker30(context);
        }
        break;
      case "xhtml":
      case "svg":
        checker = new OPSChecker(context);
        break;
      case "mo":
        if (version == EPUBVersion.VERSION_3) checker = new OverlayChecker(context);
        break;
      case "nav":
        if (version == EPUBVersion.VERSION_3) checker = new NavChecker(context);
        break;
      default:
        break;
      }
    }
    
    if (checker == null)
    {
      outWriter.println(messages.get("display_help"));
      System.err.println(String.format(messages.get("mode_version_not_supported"), mode, version));

      throw new RuntimeException(String.format(messages.get("mode_version_not_supported"), mode,
          version));
    }


    if (checker.getClass() == EpubCheck.class)
    {
      int validationResult = ((EpubCheck) checker).doValidate();
      if (validationResult == 0)
      {
        outWriter.println(messages.get("no_errors__or_warnings"));
        return 0;
      }
      else if (validationResult == 1)
      {
        System.err.println(messages.get("there_were_warnings"));
        return failOnWarnings ? 1 : 0;
      }
      System.err.println(messages.get("there_were_errors"));
      return 1;
    }
    else
    {
      checker.check();
      if (report.getWarningCount() == 0 && report.getFatalErrorCount() == 0 && report.getErrorCount() == 0)
      {
        outWriter.println(messages.get("no_errors__or_warnings"));
        return 0;
      }
      else if (report.getWarningCount() > 0 && report.getFatalErrorCount() == 0 && report.getErrorCount() == 0)
      {
        System.err.println(messages.get("there_were_warnings"));
        return failOnWarnings ? 1 : 0;
      }
      else
      {
        System.err.println(messages.get("there_were_errors"));
        return 1;
      }
    }
  }
  
  
  private int processFile(Report report)
  {
    report.info(null, FeatureEnum.TOOL_NAME, "epubcheck");
    report.info(null, FeatureEnum.TOOL_VERSION, EpubCheck.version());
    report.info(null, FeatureEnum.TOOL_DATE, EpubCheck.buildDate());
    int result = 0;
    Archive epub = null;

    try
    {
      if (expanded)
      {
        // check existance of path (fix #525)
        File f = new File(path);
        if (!f.exists())
        {
          System.err.println(String.format(messages.get("directory_not_found"), path));
          return 1;
        }

        try
        {
          epub = new Archive(path, true);
          epub.createArchive();
          report.setEpubFileName(epub.getEpubFile().getAbsolutePath());
          path = epub.getEpubFile().getAbsolutePath();
          mode = null;
        } catch (RuntimeException ex)
        {
          System.err.println(messages.get("there_were_errors"));
          return 1;
        }

      }
    if (mode != null)
    {
      report.info(null, FeatureEnum.EXEC_MODE,
          String.format(messages.get("single_file"), mode, version.toString(), profile));
    }
    result = validateFile(path, version, report, profile);
      if (expanded && epub!=null)
      {
        if (!keep || (report.getErrorCount() > 0) || (report.getFatalErrorCount() > 0))
        {
          if (keep && ((report.getErrorCount() > 0) || (report.getFatalErrorCount() > 0)))
          {
            // Notify if we are deleting for failures
            System.err.println(messages.get("deleting_archive"));
          }
          epub.deleteEpubFile();
        }
      }


      return result;
    } catch (Throwable e)
    {
      e.printStackTrace();
      return 1;
    } finally
    {
      report.close();
    }
  }


  private void printEpubCheckCompleted(Report report)
  {
    if(report != null) {
      StringBuilder messageCount = new StringBuilder();
      int count;
      String variant;
      if(reportingLevel <= ReportingLevel.Fatal) {
        messageCount.append(messages.get("messages") + ": ");
        count = report.getFatalErrorCount();
        variant = (count == 0) ? "zero" : (count == 1) ? "one" : "many";
        messageCount.append(String.format(messages.get("counter_fatal_"+variant), count));
      }
      if(reportingLevel <= ReportingLevel.Error) {
        count = report.getErrorCount();
        variant = (count == 0) ? "zero" : (count == 1) ? "one" : "many";
        messageCount.append(" / " + String.format(messages.get("counter_error_"+variant), count));
      }
      if(reportingLevel <= ReportingLevel.Warning) {
        count = report.getWarningCount();
        variant = (count == 0) ? "zero" : (count == 1) ? "one" : "many";
        messageCount.append(" / " + String.format(messages.get("counter_warn_"+variant), count));
      }
      if(reportingLevel <= ReportingLevel.Info) {
        count = report.getInfoCount();
        variant = (count == 0) ? "zero" : (count == 1) ? "one" : "many";
        messageCount.append(" / " + String.format(messages.get("counter_info_"+variant), count));
      }
      if(reportingLevel <= ReportingLevel.Usage) {
        count = report.getUsageCount();
        variant = (count == 0) ? "zero" : (count == 1) ? "one" : "many";
        messageCount.append(" / " + String.format(messages.get("counter_usage_"+variant), count));
      }
      if(messageCount.length() > 0) {
        messageCount.append("\n");
        outWriter.println(messageCount);
      }
    }
    outWriter.println(messages.get("epubcheck_completed"));
    outWriter.setQuiet(false);
  }

  private void dumpMessageDictionary(Report report)
    throws IOException
  {
    OutputStreamWriter fw = null;
    try
    {
      if (listChecksOut != null)
      {
        fw = new FileWriter(listChecksOut);
      }
      else
      {
        fw = new OutputStreamWriter(System.out);
      }
      new MessageDictionaryDumper(report.getDictionary()).dump(fw);
    } catch (Exception e)
    {
      if (listChecksOut != null)
      {
        System.err.println(String.format(messages.get("error_creating_config_file"),
            listChecksOut.getAbsoluteFile()));
      }
      System.err.println(e.getMessage());
    } finally
    {
      if (fw != null)
      {
        try
        {
          fw.close();
        } catch (IOException ignored)
        {
        }
      }
    }
  }

  private Report createReport()
    throws IOException
  {
    LocalizableReport report;
    if (listChecks)
    {
      report = new DefaultReportImpl("none");
    }
    else if (jsonOutput | xmpOutput | xmlOutput)
    {
      PrintWriter pw = null;
      if (fileOut == null)
      {
        pw = new PrintWriter(System.out, true);
      }
      else
      {
        pw = new PrintWriter(fileOut, "UTF-8");
      }
      if (xmlOutput) {
        report = new XmlReportImpl(pw, path, EpubCheck.version());
      } else if (xmpOutput) {
        report = new XmpReportImpl(pw, path, EpubCheck.version());
      } else {
        report = new CheckingReport(pw, path);
      }
    }
    else
    {
      report = new DefaultReportImpl(path);
    }
    report.setReportingLevel(this.reportingLevel);
    report.setLocale(locale);
    if (useCustomMessageFile)
    {
      report.setOverrideFile(customMessageFile);
    }

    return report;
  }
  /**
   * This method iterates through all of the arguments passed to main to find
   * accepted flags and the name of the file to check. This method returns the
   * last argument that ends with ".epub" (which is assumed to be the file to
   * check) Here are the currently accepted flags: <br>
   * <br>
   * -? or -help = display usage instructions <br>
   * -v or -version = display tool version number
   *
   * @param args
   *          String[] containing arguments passed to main
   * @return the name of the file to check
   */
  private boolean processArguments(String[] args)
  {
    // Exit if there are no arguments passed to main
    if (args.length < 1)
    {
      System.err.println(messages.get("argument_needed"));
      return false;
    }

    setCustomMessageFileFromEnvironment();

    Pattern argPattern = Pattern.compile("--?(.*)");
    
    for (int i = 0; i < args.length; i++)
    {
      Matcher argMatch = argPattern.matcher(args[i]);
      if (argMatch.matches()){
        switch (argMatch.group(1)) {
          case "v": 
              if (i + 1 < args.length)
              {
                ++i;
                if (args[i].equals("2.0") || args[i].equals("2"))
                {
                  version = EPUBVersion.VERSION_2;
                }
                else if (args[i].equals("3.0") || args[i].equals("3"))
                {
                  version = EPUBVersion.VERSION_3;
                }
                else
                {
                  outWriter.println(messages.get("display_help"));
                  throw new RuntimeException(new InvalidVersionException(
                      InvalidVersionException.UNSUPPORTED_VERSION));
                }
              }
              else
              {
                outWriter.println(messages.get("display_help"));
                throw new RuntimeException(messages.get("version_argument_expected"));
              }
            break;
          case "m":
          case "mode":
              if (i + 1 < args.length)
              {
                mode = args[++i];
                expanded = mode.equals("exp");
              }
              else
              {
                outWriter.println(messages.get("display_help"));
                throw new RuntimeException(messages.get("mode_argument_expected"));
              }
            break;
          case "p":
          case "profile":
              if (i + 1 < args.length)
              {
                String profileStr = args[++i];
                try
                {
                  profile = EPUBProfile.valueOf(profileStr.toUpperCase(Locale.ROOT));
                } catch (IllegalArgumentException e)
                {
                  System.err.println(messages.get("mode_version_ignored", profileStr));
                  profile = EPUBProfile.DEFAULT;
                }
              }
              else
              {
                outWriter.println(messages.get("display_help"));
                throw new RuntimeException(messages.get("profile_argument_expected"));
              } 
            break;
          case "s":
          case "save":
              keep = true;
            break;
          case "o":
          case "out":
              if ((args.length > (i + 1)) && !(args[i + 1].startsWith("-")))
              {
                fileOut = new File(args[++i]);
              }
              else if ((args.length > (i + 1)) && (args[i + 1].equalsIgnoreCase("-")))
              {
                fileOut = null;
                i++;
              }
              else
              {
                File pathFile = new File(path);
                if (pathFile.isDirectory())
                {
                  fileOut = new File(pathFile.getAbsoluteFile().getParentFile(), pathFile.getName()
                      + "check.xml");
                }
                else
                {
                  fileOut = new File(path + "check.xml");
                }
              }
              xmlOutput = true;
            break;
          case "j":
          case "json":
              if ((args.length > (i + 1)) && !(args[i + 1].startsWith("-")))
              {
                fileOut = new File(args[++i]);
              }
              else if ((args.length > (i + 1)) && (args[i + 1].equalsIgnoreCase("-")))
              {
                fileOut = null;
                i++;
              }
              else
              {
                File pathFile = new File(path);
                if (pathFile.isDirectory())
                {
                  fileOut = new File(pathFile.getAbsoluteFile().getParentFile(), pathFile.getName()
                      + "check.json");
                }
                else
                {
                  fileOut = new File(path + "check.json");
                }
              }
              jsonOutput = true;
            break;
          case "x":
          case "xmp":
              if ((args.length > (i + 1)) && !(args[i + 1].startsWith("-")))
              {
                fileOut = new File(args[++i]);
              }
              else if ((args.length > (i + 1)) && (args[i + 1].equalsIgnoreCase("-")))
              {
                fileOut = null;
                i++;
              }
              else
              {
                File pathFile = new File(path);
                if (pathFile.isDirectory())
                {
                  fileOut = new File(pathFile.getAbsoluteFile().getParentFile(), pathFile.getName()
                      + "check.xmp");
                }
                else
                {
                  fileOut = new File(path + "check.xmp");
                }
              }
              xmpOutput = true;
            break;
          case "i":
          case "info":
              reportingLevel = ReportingLevel.Info;
            break;
          case "f":
          case "fatal":
              reportingLevel = ReportingLevel.Fatal;
            break;
          case "e":
          case "error":
              reportingLevel = ReportingLevel.Error;
            break;
          case "w":
          case "warn":
              reportingLevel = ReportingLevel.Warning;
            break;
          case "u":
          case "usage":
              reportingLevel = ReportingLevel.Usage;
            break;
          case "q":
          case "quiet":
              outWriter.setQuiet(true);
            break;
          case "failonwarnings":
              failOnWarnings = true;
            break;
          case "r":
          case "redir":
              if (i + 1 < args.length)
              {
                fileOut = new File(args[++i]);
              }
            break;
          case "c":
          case "customMessages":
              if (i + 1 < args.length)
              {
                String fileName = args[i + 1];
                if ("none".compareTo(fileName.toLowerCase(Locale.ROOT)) == 0)
                {
                  customMessageFile = null;
                  useCustomMessageFile = false;
                  ++i;
                }
                else if (!fileName.startsWith("-"))
                {
                  customMessageFile = new File(fileName);
                  useCustomMessageFile = true;
                  ++i;
                }
                else
                {
                  System.err.println(String.format(messages.get("expected_message_filename"), fileName));
                  displayHelp();
                  return false;
                }
              }
              break;
          case "l":
          case "listChecks":
              if (i + 1 < args.length)
              {
                if (!args[i + 1].startsWith("-"))
                {
                  listChecksOut = new File(args[++i]);
                }
                else
                {
                  listChecksOut = null;
                }
              }
              listChecks = true;
            break;
          case "locale":
              if(i + 1 < args.length) 
              {
                  if(args[i + 1].startsWith("-"))
                  {
                      System.err.println(String.format(messages.get("incorrect_locale"), args[i + 1]));
                      displayHelp();
                      return false;
                  }
                  else
                  {
                      String langTag = args[++i];
                      // Rather than attempting to validate the locale, we will just
                      // allow it to fallback to the default in the case of invalid
                      // language tags.
                      this.locale = Locale.forLanguageTag(langTag);
                      this.messages = Messages.getInstance(this.locale);
                  }
              }
              else
              {
                  System.err.println(String.format(messages.get("missing_locale")));
                  displayHelp();
                  return false;
              }
              break;
          case "h":
          case "?":
          case "help":
              displayHelp(); // display help message
              displayHelp = true;
              break;
          case "version":
            displayVersion();
            displayVersion = true;
            break;
          default:
              System.err.println(String.format(messages.get("unrecognized_argument"), args[i]));
              displayHelp();
              return false;
        }
        
        
      }else{
        //System.out.println("No match: " + args[i]);
        if (path == null)
        {
          path = args[i];
        }
        else
        {
          System.err.println(String.format(messages.get("unrecognized_argument"), args[i]));
          displayHelp();
          return false;
        }
      }

    }

    if ((xmlOutput && xmpOutput) || (xmlOutput && jsonOutput) || (xmpOutput && jsonOutput))
    {
      System.err.println(messages.get("output_type_conflict"));
      return false;
    }
    if (path != null)
    {
      StringBuilder sb = new StringBuilder();
      for (int i = 0; i < path.length(); i++)
      {
        if (path.charAt(i) == '\\')
        {
          sb.append('/');
        }
        else
        {
          sb.append(path.charAt(i));
        }
      }
      path = sb.toString();
    }

    if (path == null)
    {
      if (listChecks || displayHelp || displayVersion)
      {
        return true;
      }
      else
      {
        System.err.println(messages.get("no_file_specified"));
        return false;
      }
    }
    else if (path.matches(".+\\.[Ee][Pp][Uu][Bb]"))
    {
      if (mode != null || version != EPUBVersion.VERSION_3)
      {
        System.err.println(messages.get("mode_version_ignored"));
        mode = null;
      }
    }
    else if (mode == null && profile == null)
    {
      outWriter.println(messages.get("mode_required"));
      return false;
    }

    return true;
  }

  private void setCustomMessageFileFromEnvironment()
  {
    Map<String, String> env = System.getenv();
    String customMessageFileName = env.get(EPUBCHECK_CUSTOM_MESSAGE_FILE);
    if (customMessageFileName != null && customMessageFileName.length() > 0)
    {
      File f = new File(customMessageFileName);
      if (f.exists())
      {
        customMessageFile = f;
        useCustomMessageFile = true;
      }
    }
  }

  /**
   * This method displays a short help message that describes the command-line
   * usage of this tool
   */
  private void displayHelp()
  {
      outWriter.println(String.format(messages.get("help_text"), EpubCheck.version()));
  }
  
  /**
   * This method displays the EpubCheck version.
   */
  private void displayVersion()
  {
    outWriter.println(String.format(messages.get("epubcheck_version_text"), EpubCheck.version()));
  }
}
