library APIConstants;

const String SUCCESS_MESSAGE = " You will be contacted by us very soon.";

var baseUrl = "http://182.18.157.215/SmartGeoTrack/API/"; // Test
//var baseUrl ="http://182.18.157.215/CISSGT_UAT/API/";//CISSGT_UAT

//var baseUrl ="http://137.59.201.212/SGT/API/";//CISSGT_live

var ValidateUser = "User/ValidateUser";
var GetUserOTP = "Login/GetUserOTP";
var ValidOTP = "Login/ValidOTP";
var ResetPassWord = "User/ResetPassWord";
var SyncTransactions = "Sync/SyncTransactions";
var userChangePassword ='User/ChangePassword';
var Getcount = "Sync/GetCount";
var SyncHoliday = "Sync/SyncHoliday";
var SyncShift  = "Sync/SyncShift";
var SyncUserWeekOffXref  = "Sync/SyncUserWeekOffXref";
var GetMasterData = "SyncMasters/GetMasterData";


 