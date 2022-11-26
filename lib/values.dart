class Values {
  static String userEmail = "";
  static String userName = "";
  static String userPassword = "";
  static String dstUserEmail = "";
  static String dstUserName = "";
  static String baseUri = "http://39.101.65.141:8080";
  static String fileUri = "http://39.101.65.141:8000";
  static String brokerIp = "39.101.65.141";
  static List<Map<String, String>> contactItems = [];
  static List<Map<String, String>> messageItems = [];
  static Set<String> received = {};
  static bool isChatMqttStarted = false;
  static bool isContactMqttStarted = false;
  static bool isBinded = false;
  static bool autoScroll = true;
  static bool isAsk = false;
  static bool isConfirm = false;
  static Map<String, String> whoAsk = {};
  static bool isMessageArived = false;
  
  // [
  //   {"time": "", "srcUserEmail": "test@test", "dstUserEmail": "mdd", "type":"audio","content": "hi, I'm test"},
  //   {"time": "", srcUserEmail": "mdd", "dstUserEmail": "test@test", "type": "text", "content": "hello, 我是mdd asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"},
  // ];
}
