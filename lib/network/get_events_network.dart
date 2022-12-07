import 'package:basalon/main.dart';
import 'package:basalon/modal/event_category_model.dart';
import 'package:basalon/modal/get_event_detail_data.dart';
import 'package:basalon/modal/home_data.dart';
import 'package:basalon/screens/home_page.dart';
import 'package:basalon/services/api_provider/api_provider.dart';
import 'package:basalon/services/constant.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:geolocator/geolocator.dart';

class FetchEventData {
  FetchEventData({
    this.id,
    this.filterByCategory,
    this.commentContent,
    this.rating,
    this.eventId,
    this.filterByTime,
  });

  final int? id;
  dynamic filterByCategory;
  dynamic filterByTime;

  String? eventId;
  dynamic rating;
  String? commentContent;
  bool isAlertOpened = false;

  var dio = Dio();
  List data = [];

  Welcome? eventData;
  List? cardData;
  FilterCategoryModel? filterCategoryModel;
  dynamic categoryData;
  Position? geoLoc;
  String isNear = '';
  String timeValue = '';
  String loc = '';
  setLocation() async {
    geoLoc = await Geolocator.getCurrentPosition();

    // setState(() {

    // });

    return geoLoc;
  }

  Future getEventData(page, filterByCategory, filterByTime, filterByAnyWhere,
      mapLat, mapLng, keyword, startDate, endDate, BuildContext context) async {
    try {
      configLoading();
      //EasyLoading.show();
      final response = await ApiProvider.post(url: 'get_events', body: {
        "paged": "$page",
        "keyword": keyword != "" || keyword != null ? "$keyword" : "",
        "category": "${filterByCategory ?? ''}",
        "map_lat": (filterByAnyWhere == 'עיר מסויימת' ||
                filterByAnyWhere == 'בכל מקום' ||
                filterByAnyWhere == 'קרוב אליי')
            ? '$mapLat'
            : null,
        "map_lng": (filterByAnyWhere == 'עיר מסויימת' ||
                filterByAnyWhere == 'בכל מקום' ||
                filterByAnyWhere == 'קרוב אליי')
            ? '$mapLng'
            : null,
        "start_date": "$startDate",
        "end_date": "$endDate",
        "time":
            "${filterByTime == 'specific_date' ? "this_week" : filterByTime ?? " "}",
        // "sort": filterByAnyWhere == 'online'
        //     ? 'start-date'
        //     : (filterByAnyWhere == 'בכל מקום' || filterByCategory == 'אירוח קולינרי')
        //       ? 'start-date'
        //         : ((filterByAnyWhere == 'קרוב אליי' ||
        //                     filterByAnyWhere == 'עיר מסויימת') ||
        //                 mapLng != null)
        //             ? 'near'
        //             : '',
        "sort": (filterByAnyWhere == 'עיר מסויימת' ||
                filterByAnyWhere == 'קרוב אליי' ||
                application.filterAnywhereProvider == 'קרוב אליי')
            ? "near"
            : (filterByAnyWhere == 'בכל מקום')
                ? 'start-date'
                : '',
        "event_type": filterByAnyWhere == 'online' ? 'online' : 'classic',
        "el_data_taxonomy_custom[]": "",
        "show_featured": "",
      });
      final result = HomeData.fromJson(response['body']);
     
    //  if(data.isEmpty && page == 1){
    //   data = [];
    //  }

      if (response['status'] == 401) {
        // errorAlertMessage('no event found', '', context);
      } else {
        if (page > 1) {
          data = [...data, ...?result.data];
        } else {
          data = result.data!;
        }
        EasyLoading.dismiss();
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (keyword != null && keyword != '') {
        data = [];
      }
      // data = [];
    }
    return data;
  }

  List greekToEng = [
    {"greekName": "שרון והסביבה", "englishName": "sharon"},
    {"greekName": "מרכז", "englishName": "center"},
    {"greekName": "ירושלים והסביבה", "englishName": "east"},
    {"greekName": "מחוז חיפה והצפון", "englishName": "north"},
    {"greekName": "השפלה והדרום", "englishName": "south"},
    {
      "greekName": "קרוב אליי",
      "englishName": "",
    },
    {"greekName": "בכל הארץ", "englishName": ""}
  ];

  getFilterEnglishName(val) {
    var res =
        greekToEng.firstWhere((element) => element['greekName'] == val.trim());

    return res['englishName'];
  }

  Future getEventData2(
      page,
      isSearch,
      Search,
      List locdata,
      filterByCategory,
      filterByTime,
      filterByAnyWhere,
      mapLat,
      mapLng,
      keyword,
      startDate,
      endDate,
      BuildContext context) async{
    var filteer = [];
    var searchLoc = [];
    if (filterByAnyWhere == 'קרוב אליי') {
      isNear = 'קרוב אליי';
    } else if (filterByAnyWhere == 'בכל הארץ') {
      isNear = 'בכל הארץ';
    }
    if(filterByAnyWhere == 'קרוב אליי'){
      loc = 'קרוב אליי';
    }
    timeValue = filterByTime;
    print("filterbykeyword");
    print(filterByAnyWhere);
    locdata.map((val) => {filteer.add(getFilterEnglishName(val))}).toList();
        print(filteer.last);
    Search.map((val)=>{searchLoc.add(getFilterEnglishName(val))}).toList();
    print("SearchLoc");
    print(searchLoc.join(','));

    var body = {
      "event_state": searchLoc.isNotEmpty ? searchLoc.join(","): filteer.join(","),
      "column": "three-column",
      "event_type": filterByAnyWhere == 'online' ? 'online' : 'classic',
      "el_data_taxonomy_custom[]": "",
      "show_featured": "",
      "keyword": keyword != "" || keyword != null ? "$keyword" : "",
      "cat": "${filterByCategory ?? ''}",
      "map_lat": filterByAnyWhere == 'קרוב אליי' ? mapLat: null,
                  // loc == 'קרוב אליי' ? mapLat : null,
      // filterByAnyWhere == 'עיר מסויימת'
      //     ? mapLat
      //     : filterByAnyWhere == 'בכל מקום'
      //         ? mapLat
      //         : filterByAnyWhere == 'מרכז'
      //             ? mapLat
      //             : filterByAnyWhere == 'קרוב אליי'
      //                 ? mapLat
      //                 : null,
      "map_lng": filterByAnyWhere == 'קרוב אליי' ? mapLng: null,
                //  loc == 'קרוב אליי' ? mapLng : null,
      // filterByAnyWhere == 'עיר מסויימת'
      //     ? mapLng
      //     : filterByAnyWhere == 'בכל מקום'
      //         ? mapLng
      //         : filterByAnyWhere == 'קרוב אליי'
      //             ? mapLng
      //             : null,
      "start_date": "$startDate",
      "end_date": "$endDate",
      "time": "${filterByTime}",
      "sort": ((filterByAnyWhere == 'השפלה והדרום') || (filterByAnyWhere == 'בכל הארץ') 
      ||(filterByAnyWhere == 'מחוז חיפה והצפון') || (filterByAnyWhere == 'ירושלים והסביבה') ||
      (filterByAnyWhere == 'מרכז' || filterByAnyWhere == 'שרון והסביבה')
       ) ? 'start-date' : 'near',
      //  (isNear == 'קרוב אליי' && timeValue == filterByTime)
      //     ? 'near'
      //     : (isNear =='קרוב אליי' && filterByTime == null)
      //         ? 'near'
      //         : (isNear == 'בכל הארץ' && filterByTime == null)
      //         ? 'start-date'
      //         :(isNear == 'בכל הארץ' && filterByTime == timeValue)
      //         ? "": mapLng == null? "": "",

      // (filterByAnyWhere == 'עיר מסויימת' ||
      //         filterByAnyWhere == 'קרוב אליי' ||
      //         application.filterAnywhereProvider == 'קרוב אליי')
      //     ? "near"
      //     : filterByAnyWhere == 'בכל מקום' ?  'start-date':
      //     filterByAnyWhere == 'בכל הארץ' ?  'start-date':
      //      filterByAnyWhere == 'השפלה והדרום' ? 'start-date': '',
      "type": "type5",
      "paged": "$page"
    };
    print("this is body");
    print(body);
    print("printing filter value");
    print(filterByAnyWhere);
    try {
      configLoading();
      final response =
          await ApiProvider.post(url: 'get_event_search', body: body);
      // data = [];
              
      final result = HomeData.fromJson(response['body']);
      if (response['body']['success'] == 401) {
        if (!isAlertOpened){
        isAlertOpened = true;
        page == 1 ? errorAlertMessage('no event found', '', context): "";
        }else {

        }
      } else {
        if (page > 1) {
          data = [...data, ...?result.data];
        } else {
          print("is conyroller hear");
          // data.clear();
          data = result.data!;
          // data = data;
        }
    // EasyLoading.dismiss();
      }
    } catch (e) {
      // EasyLoading.dismiss();
      if (keyword != null && keyword != '') {
        data = [];
      }
      data = [];
    }
    print("this is dara length");
    print(data.length);
    return data;
  }

  Future getEventDetailData() async {
    try {
      final response =
          await ApiProvider.post(url: 'get_event_detail', body: {"id": "$id"});
      final result = Welcome.fromJson(response['body']);
      eventData = result;
    } catch (e) {}
    return eventData;
  }

  Future getEventCategories() async {
    try {
      final response = await ApiProvider.get('get_event_category');
      final result = FilterCategoryModel.fromJson(response['body']);

      filterCategoryModel = result;
    } catch (e) {}
    return filterCategoryModel;
  }

  Future postFeedbackEventDetails(context, userId,
      {content, rating, eventId}) async {
    try {
      await ApiProvider.post(url: 'add_comment', body: {
        'user_id': '$userId',
        'event_id': '$eventId',
        'rating': '$rating',
        'comment_content': '$commentContent',
      });
      errorAlertMessage('Waiting for approval', '', context);
    } catch (e) {}
  }

  Future sendEmailToAuthor(
    context,
    eventId,
    name,
    email,
    phone,
    subject,
    content,
  ) async {
    try {
      await ApiProvider.post(url: 'email_send_to_author', body: {
        'event_id': '$eventId',
        'name_customer': '$name',
        'email_customer': '$email',
        'phone_customer': '$phone',
        'subject_customer': '$subject',
        'content': '$content',
      });
      errorAlertMessage('Mail Sent Successfully!', '', context);
    } catch (e) {}
  }

  void errorAlertMessage(
      String errorMessage, String titleMessage, BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        title: Center(child: Text(titleMessage)),
        content: Text(
          errorMessage,
          textAlign: TextAlign.center,
          style: ktextStyleBoldMedium,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              isAlertOpened = false;
              Navigator.of(context).pop();
            },
            // onPressed: () => Navigator.pushReplacement(
            //     context, MaterialPageRoute(builder: (context) => HomePage())),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
//
// import 'package:basalon/modal/event_category_model.dart';
// import 'package:basalon/modal/get_event_detail_data.dart';
// import 'package:basalon/modal/home_data.dart';
// import 'package:basalon/services/api_provider/api_provider.dart';
// import 'package:dio/dio.dart';
//
// class FetchEventData {
//   FetchEventData({
//     this.id,
//     this.filterByCategory,
//     this.commentContent,
//     this.rating,
//     this.eventId,
//   });
//
//   final int? id;
//   dynamic filterByCategory;
//
//   String? eventId;
//   dynamic rating;
//   String? commentContent;
//
//   var dio = Dio();
//   List data = [];
//
//   Welcome? eventData;
//   List? cardData;
//   FilterCategoryModel? filterCategoryModel;
//
//   Future getEventData(page, filterByCategory, filterByTime, filterByAnyWhere,
//       mapLat, mapLng, keyword, startDate, endDate) async {
//     try {
//       final response = await ApiProvider.post(url: 'get_events', body: {
//         "paged": "$page",
//         "category": "${filterByCategory ?? ""}",
//         "time": "${filterByTime ?? "this_week"}",
//         "event_type": filterByAnyWhere == 'online' ? 'online' : 'classic',
//         "sort": (filterByAnyWhere == 'online' || filterByAnyWhere == 'classic')
//             ? 'start-date'
//             : filterByAnyWhere == 'קרוב אליי'
//             ? 'near'
//             : 'near',
//         "map_lat": "$mapLat",
//         "map_lng": "$mapLng",
//         "keyword": "$keyword",
//         "start_date": "$startDate",
//         "end_date": "$endDate",
//       });
//
//       final result = HomeData.fromJson(response['body']);
//
//       if (page > 1) {
//         data = [...data, ...?result.data];
//       } else {
//         data = result.data!;
//       }
//     } catch (e) {
//       if (keyword != null && keyword != '') {
//         data = [];
//       }
//     }
//     return data;
//   }
//
//   Future getEventDetailData() async {
//     try {
//       final response =
//       await ApiProvider.post(url: 'get_event_detail', body: {"id": "$id"});
//       final result = Welcome.fromJson(response['body']);
//       eventData = result;
//       // cardData = eventData?.data?.relatedEvent;
//     } catch (e) {
//     }
//     return eventData;
//   }
//
//   Future getEventCategories() async {
//     try {
//       final response = await ApiProvider.get('get_event_category');
//       final result = FilterCategoryModel.fromJson(response['body']);
//
//       filterCategoryModel = result;
//     } catch (e) {
//     }
//     return filterCategoryModel;
//   }
//
//   Future postFeedbackEventDetails() async {
//     try {
//       final response = await ApiProvider.post(url: 'add_comment', body: {
//         'event_id': '$eventId',
//         'rating': '$rating',
//         'comment_content': '$commentContent',
//       });
//     } catch (e) {
//     }
//   }
// }
