package com.nosm.elearning.ariadne.constants;

public final class C {
	  private C() {}  // can't construct

	  public static final String br = System.getProperty ( "line.separator" );

	  // misc

	  public static final String GAME_HOST3 = "142.51.75.11";
	  public static final String GAME_HOST = "142.51.75.17";

	  public static final int GAME_GAME_ID3 = 2; // hard-coded until picking Lab from list is supported
	  public static final String GAME_USER = "olremote";
	  public static final String GAME_PASSWORD = "s3cr3t";

	  public static final String GAME_NAME = "YOUR LABYRINTH NAME LOOKUP STRING";

	  public static final String GAME_URL_PATH = "/mnode.asp?id=";
	  public static final String GAME_URL_PATH_SUFFIX = "&mode=remote&remotemode=id";
	  public static final String GAME_URL_NODE_PATH = "";

	  public static final String GAME_URL_PATH3 = "/django/labyrinth/";
	  public static final String GAME_URL_NODE_PATH3 = "node";
	  public static final String GAME_URL_PATH_SUFFIX3 = "/data/classic/?";
	  //http://142.51.75.17/mnode.asp?id=6275&mode=remote&remotemode=id

	  //public static final String GAME_URL_BASE_PATH3 = GAME_URL_PATH3 + GAME_GAME_ID;

	  public static final String GAME_URL_NAME_SUFFIX = "</a>";
	  public static final String GAME_URL_NAME_PREFIX = "'>";//"]]]] - "; //session id gets appended
	  public static final String GAME_URL_NAME_PREFIX3 = "/data/\'>";

	  public static final String GAME_URL_ID_PREFIX = ".asp?id=";
	  public static final String GAME_URL_ID_SUFFIX = "&mode=remote";

	  public static final String GAME_URL_ID_PREFIX3 = "/link/";
	  public static final String GAME_URL_ID_SUFFIX3 = "/data/";

	  public static final String GAME_URL_ROOT3 = "/root";
	  public static final String GAME_URL_ROOT = "/remote.asp";

	  public static final String GAME_URL_LINKER_SUFFIX = "</p>";
	  public static final String GAME_URL_LINKER_PREFIX = "<p>";

	  public static final String GAME_URL_LINK_START = "start";
	  public static final String GAME_URL_LINK_SSID3 =  "sessionid";
	  public static final String GAME_URL_LINK_SSID = "sessID";
	  //GAME_URL_SSID_PREFIX3
	  //public static final String GAME_URL_LINK_PREFIX3 = "/link/"; // trouble
	  public static final String GAME_URL_LINK_PREFIX = "nodeid=";

	  //UI
	  public static final String UI_NAME = "assetNameOUT";
	  public static final String UI_TYPE = "assetType";
	  public static final String UI_VAL = "assetValueIN";
	  public static final String UI_PAIRS = "savedUIPairs";
	  public static final String UI_TARGET = "assetTargetIN";
	  public static final String UI_ID = "assetMapNodeid";


	}
