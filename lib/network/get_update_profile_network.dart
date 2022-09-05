import 'package:basalon/services/api_provider/api_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../blocs/application_bloc.dart';
import '../modal/get_user_data.dart';

class UpdateAndGetUserProfile {
  GetUserData? getUserData;

  Future getProfileData(userID, {context}) async {
    late final application =
        Provider.of<ApplicationBloc>(context, listen: false);

    try {
      print("userID");
      print(userID);
      // 'https://basalon.co.il/wp-json/wp/v2/get_user_profile',
      final response = await ApiProvider.post(
          url: 'get_user_profile', body: {'user_id': '$userID'});
      print("debug2");
print(response['body']);
print("chetan debug");
      final result = GetUserData.fromJson(response['body']);
      print('----------------get_user_profileget_user_profile');
      print(response['status']);
      print(result.data?.authorImage);
      application.getUserDataProfileProvider = result;
      getUserData = result;
    } catch (e) {
      print("debug3");
      // print('nhi ayi profile');
      print('${e}-------');
    }
    return getUserData;
  }

  Future getUpdateUserData(userId, firstname, lastname, userEmail, userPhone,
      desc, imgPath, filename, BuildContext context, bool removeDp) async {
    try {
      final response =
          await ApiProvider.post(url: 'update_user_profile', body: {
        'user_id': userId,
        'first_name': firstname,
        'last_name': lastname,
        'user_email': userEmail,
        'user_phone': userPhone,
        'description': desc,
        'author_img': imgPath != null
            ? await MultipartFile.fromFile(imgPath, filename: filename)
            : null,
        if (removeDp && imgPath == null) 'remove_dp': removeDp
      });
      EasyLoading.dismiss();
      if (response['status'] == 401) {
        print('no data found');
        // errorAlertMessage('No Data Found', 'Error!');
      } else {
        errorAlertMessage('User Data Updated!', 'Success!', context);
        getProfileData(userId);
      }
    } catch (e) {
      print('pawan bhai ki jai');
      // print('nhi hui update !!');
      print(e);
    }
  }

  Future updateBankDetails(
      userID, owner, number, name, branch, BuildContext context) async {
    try {
      final response =
          await ApiProvider.post(url: 'update_user_payout_method', body: {
        "user_id": "$userID",
        "user_bank_owner": "${owner}",
        "user_bank_number": "$number",
        "user_bank_name": "$name",
        "user_bank_branch": "$branch",
      });

      print(response);
      EasyLoading.dismiss();

      errorAlertMessage('User Data Updated!', 'Success!', context);
    } catch (e) {
      print('nhi hua update pay');
      print(e);
    }
  }

  Future updatePassword(
      userID, oldPass, newPass, confirm, BuildContext context) async {
    try {
      final response =
          await ApiProvider.post(url: 'user_password_reset', body: {
        "user_id": "$userID",
        "old_password": "$oldPass",
        "new_password": "${(newPass == confirm) ? newPass : null}",
      });
      print(response);
      print('------${response['body']['success']}');
      if (response['body']['success'] == 401) {
        EasyLoading.dismiss();
        errorAlertMessage('User Password Failed!', 'Failed!', context);
      } else {
        EasyLoading.dismiss();
        errorAlertMessage('User Password Updated!', 'Success!', context);
      }
    } catch (e) {
      print('nhi hua update pay');
      print(e);
    }
  }

  void errorAlertMessage(
      String errorMessage, String titleMessage, BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(child: Text(titleMessage)),
        content: Text(
          errorMessage,
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
